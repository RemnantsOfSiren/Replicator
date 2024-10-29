--!strict
local Sift = require(script.Parent.Parent.Sift) :: any
local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

local Types = require(script.Parent.Types)
local Replication = require(script.Parent.Replication)

local SharedFunctions = require(script.Parent.SharedFunctions)

local Dictionary = Sift.Dictionary
local CopyDeep = Dictionary.copyDeep

local Replicators = {}

local function FindReplicaById(Id: string?): Types.ClientReplica?
    if Id then
        for _, _Replicator in pairs(Replicators) do
            for _, _Replica in pairs(_Replicator.__Replicas) do
                if _Replica.Id == Id then
                    return _Replica
                end
            end
        end
    end

    return nil
end

local Replica = {}
Replica.__index = Replica

function Replica:Destroy()
    self.__Write:Destroy()
    self.__Change:Destroy()

    self.Destroying:Fire()
    
    task.delay(0.1, self.Destroying.Destroy, self.Destroying)
    table.clear(self)
end

local function NewReplica(Config: {Name: string, Id: string, Tags: { any }, Data: any, WriteLib: ModuleScript?, Parent: string?}): Types.ClientReplica
    local self = setmetatable({
        Id = Config.Id,
        Name = Config.Name,
        Tags = Config.Tags,
        Data = Config.Data,

        __Cleaner = Trove.new(),
        __Write = Signal.new(),
        __Change = Signal.new(),
        Destroying = Signal.new(),
        
        __Parent = if Config.Parent then FindReplicaById(Config.Parent) else nil,
        WriteLib = Config.WriteLib,
        __WriteLib = Config.WriteLib and require(Config.WriteLib) :: {[any]: any} or nil,
    }, Replica)

    for Key, Function in SharedFunctions do
        self[Key] = Function
    end

    self.__Cleaner:Connect(self.Destroying, function() 
        self.__Cleaner:Destroy()
    end)

    return self
end

local Replicator = {}
Replicator.__index = Replicator

function Replicator:AddListener(Callback)
    table.insert(self.__Listeners, Callback)
    
    for _, _Replica in pairs(self.__Replicas) do
        task.spawn(Callback, _Replica)
    end

    return function()
        table.remove(self.__Listeners, table.find(self.__Listeners, Callback))
    end
end

function Replicator:AddReplica(_Replica)
    self.__Replicas[_Replica.Id] = _Replica
    for _, Listener in self.__Listeners do
        task.spawn(Listener, _Replica)
    end
end

local function NewReplicator(Name: string)
    if Replicators[Name] then
        return Replicators[Name]
    end

    local self = setmetatable({
        Name = Name,
        __Replicas = {},
        __Listeners = {},
    }, Replicator)

    Replicators[Name] = self

    return self
end

local function Listener(Name: string, Callback: (...any) -> nil)
    local _Replicator = Replicators[Name]

    if not _Replicator then
        _Replicator = NewReplicator(Name)
    end

    return _Replicator:AddListener(Callback)
end

Replication.createReplica.listen(function(_Replica)
    local _Replicator = Replicators[_Replica.Name]

    if not _Replicator then
        _Replicator = NewReplicator(_Replica.Name)
    end

    if not _Replicator.__Replicas[_Replica.Id] then
        task.defer(_Replicator.AddReplica, _Replicator, NewReplica(_Replica))
    else
        warn("Replica already exists")
    end
end)

Replication.destroyReplica.listen(function(Data)
    local _Replicator = Replicators[Data.Name]
    if _Replicator then
        local _Replica = _Replicator.__Replicas[Data.Id]

        if _Replica then
            _Replica:Destroy()
            _Replicator.__Replicas[Data.Id] = nil
        end
    end
end)

type Packet = {
    Name: string,
    Id: string,
    Changes: { 
        {Time: number, Path: { string | number }, Value: any}
    }
}

Replication.replicateChanges.listen(function(Data: Packet)
    local _Replicator = Replicators[Data.Name]

    if _Replicator then
        local _Replica = _Replicator.__Replicas[Data.Id]

        if _Replica then
            table.sort(Data.Changes, function(A, B)
                return A.Time < B.Time
            end)

            local AlteredKeys = {}

            for _, Change in Data.Changes do
                task.spawn(function()
                    local Path = Change.Path
                    local _Data = _Replica.Data
 
                    if table.find(AlteredKeys, table.concat(Path, ":")) then
                        print("This was already altered")
                        return
                    end

                    for I = 1, #Path - 1 do
                        local Key = Path[I]
                        _Data = _Data[Key]
                        
                        if not _Data then
                            break
                        end
                    end
                    
                    if _Data then
                        table.insert(AlteredKeys, table.concat(Path, ":"))
                        local LastKey = Path[#Path]
                        local OldData = if typeof(_Data[LastKey]) == "table" then CopyDeep(_Data[LastKey]) else _Data[LastKey]
                        _Data[LastKey] = Change.Value
                        _Replica.__Change:Fire(Path, Change.Value, OldData)
                    end
                end)
            end
        end
    end
end)

Replication.getInitialReplicas.listen(function(_Replicas) 
    for _, _Replica in _Replicas do
        local TempReplica = NewReplica(_Replica)

        local _Replicator = Replicators[TempReplica.Name]
        
        if not _Replicator then
            _Replicator = NewReplicator(TempReplica.Name)
        end

        task.defer(_Replicator.AddReplica, _Replicator, TempReplica)
    end
end)

Replication.getInitialReplicas.send()

return table.freeze({
    ListenToNewReplica = Listener,
})