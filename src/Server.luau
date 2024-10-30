--!strict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Sift = require(script.Parent.Parent.Sift) :: any
local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

local Types = require(script.Parent.Types)
local Logger = require(script.Parent.Logger)
local Replication = require(script.Parent.Replication)
local SharedFunctions = require(script.Parent.SharedFunctions)

local Array = Sift.Array
local Dictionary = Sift.Dictionary
local CopyDeep = Dictionary.copyDeep

local Replicas = {}

local Replica = {}
Replica.__index = Replica

function Replica:Write(Method: string, ...: any)
    if self.__WriteLib and self.__WriteLib[Method] then
        local Return = { self.__WriteLib[Method](self, ...) }
        
        local Packet = { Name = self.Name, Id = self.Id, Method = Method, Args = { ... } }
        if self.To == "ALL" or not self.To then
            Replication.replicateWrite.sendToAll(Packet)
        elseif typeof(self.To) == "table" then
            Replication.replicateWrite.sendToList(Packet, self.To)
        else
            Replication.replicateWrite.sendTo(Packet, self.To)
        end
        
        return unpack(Return)
    end
end

function Replica:Destroy()
    self.__Write:Destroy()
    self.__Change:Destroy()
    
    self.Destroying:Fire()

    Replicas[self.Id] = nil
    
    Replication.destroyReplica.sendToAll({
        Name = self.Name,
        Id = self.Id
    })
    
    task.delay(0.1, self.Destroying.Destroy, self.Destroying)
end

local function ListenToTable(_Replica: Types.ServerReplica, Table, Indicies: {[number]: any}?)
	local Method = setmetatable({}, {
		__index = function(_, Key) 
            return rawget(Table, Key)
        end,
        __tostring = function()
            return "[[Replicated Table]]"
        end,
		__newindex = function(self, Key, Value)
			local IsTable = type(Value) == "table"
			local _Indicies = table.clone(Indicies or {})
            
			_Indicies[#_Indicies + 1] = Key
            _Replica.__Change:Fire(_Indicies, if IsTable then CopyDeep(Value) else Value, if type(Table[Key]) == "table" then CopyDeep(Table[Key]) else Table[Key])

            if Sift.Array.is(Table) and Value == nil then
                warn("Use :Remove() to remove an element from an array.")
            else
                rawset(Table, Key, Value)
            end

            if IsTable then
                rawset(self, Key, ListenToTable(_Replica, Value, _Indicies))
            end
            
            if (Sift.Array.is(Table) or Sift.Dictionary.count(Table) == 0) and not self.Insert then
                rawset(self, "Insert", function(_, ...)
                    local Args = { ... }
                    local InsertIndices = table.clone(_Indicies)
                    if #Args > 1 then
                        InsertIndices[#InsertIndices + 1] = Args[1]
                        _Replica.__Change:Fire(InsertIndices, Args[2], Table[Args[1]])
                        table.insert(Table, Args[1], Args[2])
                    else
                        InsertIndices[#InsertIndices + 1] = #Table + 1
                        _Replica.__Change:Fire(InsertIndices, Args[1], Table[#Table + 1])
                        table.insert(Table, Args[1])
                    end
                end)
                rawset(self, "insert", rawget(self, "Insert"))
                rawset(self, "Remove", function(_, Index: number)
                    local _Indicies = table.clone(Indicies or {})
                    _Indicies[#_Indicies + 1] = Index
                    _Replica.__Change:Fire(_Indicies, nil, Table[Index])
                    table.remove(Table, Index)
                end)
                rawset(self, "remove", rawget(self, "Remove"))
            elseif not Sift.Array.is(Table) and self.Insert then
                rawset(self, "Insert", nil)
                rawset(self, "insert", nil)
                rawset(self, "Remove", nil)
                rawset(self, "remove", nil)
            end
		end,
	})

    rawset(Method, "get", function()
        local AlreadyVisited = {}
        local Cleaner = {}

        return function()
            for Index, Value in pairs(Table) do
                if not table.find(AlreadyVisited, Index) then
                    table.insert(AlreadyVisited, Index)
                    local _Indicies = table.clone(Indicies or {})
                    _Indicies[#_Indicies + 1] = Index
                    local Temp = type(Value) == "table" and ListenToTable(_Replica, Value, _Indicies)
                    if Temp then
                        table.insert(Cleaner, Temp)
                    end
                    return Index, Temp or Value, function(NewValue)
                        if type(NewValue) == "table" then
                            rawset(Method, Index, ListenToTable(_Replica, NewValue, Indicies))
                        else
                            rawset(Table, Index, NewValue)
                        end
                    end
                end
            end

            table.clear(Cleaner)
            table.clear(AlreadyVisited)
            return nil
        end
    end)

    rawset(Method, "Get", rawget(Method, "get"))

	for Index, Value in Table do
		if type(Value) == "table" then
			Method[Index] = Value
		end
	end

    if Sift.Array.is(Table) or Sift.Dictionary.count(Table) == 0 then
        rawset(Method, "Insert", function(_, ...)
            local Args = { ... }
            local _Indicies = table.clone(Indicies or {})
            if #Args > 1 then
                _Indicies[#_Indicies + 1] = Args[1]
                _Replica.__Change:Fire(_Indicies, Args[2], Table[Args[1]])
                table.insert(Table, Args[1], Args[2])
            else
                _Indicies[#_Indicies + 1] = #Table + 1
                _Replica.__Change:Fire(_Indicies, Args[1], Table[#Table + 1])
                table.insert(Table, Args[1])
            end
        end)
        rawset(Method, "insert", rawget(Method, "Insert"))
        rawset(Method, "Remove", function(_, Index: number)
            local _Indicies = table.clone(Indicies or {})
            _Indicies[#_Indicies + 1] = Index
            _Replica.__Change:Fire(_Indicies, nil, Table[Index])
            table.remove(Table, Index)
        end)
        rawset(Method, "remove", rawget(Method, "Remove"))
    end

	return Method
end

local function NewReplica(Config: {Name: string, Tags: { string }, Data: any, WriteLib: ModuleScript?, To: Types.ToOptions?, Parent: Types.ServerReplica?}): Types.ServerReplica
    if Config.Parent and Config.Parent.To then
        Config.To = Config.Parent.To
    elseif not Config.To then
        Config.To = "All"
    end

    local self = setmetatable({
        To = Config.To,
        Id = HttpService:GenerateGUID(false),
        Name = Config.Name,
        Tags = Config.Tags,

        __Cleaner = Trove.new(),
        __Write = Signal.new(),
        __Change = Signal.new(),
        Destroying = Signal.new(),

        __Parent = Config.Parent,
    }, Replica)

    for Key, Function in SharedFunctions do
        self[Key] = Function
    end

    self.__Cleaner:Connect(self.Destroying, function() 
        self.__Cleaner:Destroy()
    end)
    
    if Config.Data then
        self.__Data = Config.Data
        self.Data = ListenToTable(self, self.__Data)
    end
    
    if Config.WriteLib and Config.WriteLib:IsA("ModuleScript") and Config.WriteLib:IsDescendantOf(game.ReplicatedStorage) then
        self.WriteLib = Config.WriteLib
        self.__WriteLib = require(self.WriteLib) :: { [string]: (self: Types.ServerReplica, ...any) -> unknown }
    elseif Config.WriteLib then
        Logger("Error", "WriteLib must be a ModuleScript and a descendant of ReplicatedStorage.")
    end

    local Changes = {}

    self.__Change:Connect(function(Path, Value)
        table.insert(Changes, { Time = os.clock(), Path = Path, Value = Value })
    end)

    self.__Cleaner:Connect(RunService.Heartbeat, function() 
        if #Changes > 0 then
            local Keys = {}
            
            Changes = Array.filter(Array.sort(Changes, function(A, B)
                return A.Time > B.Time
            end), function(Change)  
                local Id = table.concat(Change.Path, ":")
                
                if not Keys[Id] then
                    Keys[Id] = true
                    return true
                end
                
                return false
            end)

            local Packet: Types.Packet = {
                Name = self.Name,
                Id = self.Id,
                Changes = Changes
            }

            if self.To == "All" or not self.To then
                Replication.replicateChanges.sendToAll(Packet)
            elseif typeof(self.To) == "table" then
                Replication.replicateChanges.sendToList(Packet, self.To)
            else
                Replication.replicateChanges.sendTo(Packet, self.To)
            end

            table.clear(Changes)
        end
    end)

    local CreatePacket = {
        Id = self.Id,
        Name = self.Name,
        Tags = self.Tags,
        Data = Config.Data and CopyDeep(Config.Data),
        WriteLib = self.WriteLib,
        Parent = Config.Parent and Config.Parent.Id
    }

    if Config.To == "All" or not Config.To then
        task.spawn(Replication.createReplica.sendToAll, CreatePacket)
    elseif typeof(Config.To) == "table" then
        task.spawn(Replication.createReplica.sendToList, CreatePacket, Config.To)
    else
        task.spawn(Replication.createReplica.sendTo, CreatePacket, Config.To)
    end

    Replicas[self.Id] = self

    return self
end

Replication.getInitialReplicas.listen(function(_, Player)
    local _Replicas = {}

    for _, _Replica in Replicas do        
        table.insert(_Replicas, {
            Name = _Replica.Name,
            Id = _Replica.Id,
            Tags = _Replica.Tags,
            Data = if _Replica.__Data then CopyDeep(_Replica.__Data) else nil,
            WriteLib = _Replica.WriteLib,
            Parent = _Replica.__Parent and _Replica.__Parent.Id
        })
    end

    Replication.getInitialReplicas.sendTo(_Replicas, Player)
end)

return table.freeze({
    NewReplica = NewReplica
})