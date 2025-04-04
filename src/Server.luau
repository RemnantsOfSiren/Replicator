--!strict
local Sift = require(script.Parent.Parent.Sift) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

local Net = require(script.Parent.Net.Server)
local Types = require(script.Parent.Types)
local Logger = require(script.Parent.Logger)
local Parser = require(script.Parent.Parser)

local Array = Sift.Array
local Dictionary = Sift.Dictionary
local CopyDeep = Dictionary.copyDeep

local Replicas = {}

local Replica = require(script.Parent.Replica)

local ServerReplica = {}
ServerReplica.__index = ServerReplica
setmetatable(ServerReplica, { __index = Replica })

local function CreateReplica(player, replica)
	Net.createReplica.fire(player, {
		Id = replica.Id,
		Name = replica.Name,
		Tags = replica.Tags,
		Data = if replica.Data then replica.Data:Get() else nil,
		Parent = if replica.__Parent then replica.__Parent.Id else nil,
		IsParent = replica.__IsParent,
		WriteLib = replica.WriteLib,
	})
end

--[=[
    @method Write
    @within Replica
    @server
    @param Method string
    @param ... any
    @return any

    Uses the WriteLib to write data changes, and then replicates the write call to the client along with any information needed to replicate the call.
]=]
function ServerReplica:Write(Method: string, ...: any)
	if self.__WriteLib and self.__WriteLib[Method] then
		local Return = { self.__WriteLib[Method](self, ...) }
		local Packet = { Method = Method, Args = { ... } }
		self.__Fire(Net.replicaWrite, Packet)
		return unpack(Return)
	end
end

--[=[
	@method SetValue
	@within Replica
	@server
	@param Path { string | number } | string | number
	@param Value any

	Updates the specified path to the provided value.
	-- This isn't the recommended use of the API, and should only be used in cases of backwards compatibility.
	-- Credit to @Fuse for the backwards compatibility implementation.
]=]
function ServerReplica:SetValue(path: Types.ValidPath, value: any)
	local ParsedPath = Parser(path)
	local Pointer = self.Data

	for Index, Key in ParsedPath do
		if Index == #ParsedPath then
			break
		end

		Pointer = Pointer[Key]
		if not Pointer then
			return
		end
	end

	Pointer[ParsedPath[#ParsedPath]] = value
end

--[=[
	@method GetChildren
	@within Replica
	@return { [string]: Replica }

	Returns all children of the replica, if the replica is not a parent it will return an empty table.
]=]
function ServerReplica:GetChildren()
	if self.__IsParent then
		return Dictionary.filter(Replicas, function(_Replica)
			return _Replica.__Parent == self
		end)
	else
		Logger("Warn", "Replica is not a parent.")
		return {}
	end
end

--[=[
	@method OnServerEvent
	@within Replica
	@server
	@param Callback (Player: Player, ...any) -> nil
	@return { Disconnect: () -> nil }

	Connects a function to the server event, which will be fired when the client sends a request.
]=]
function ServerReplica:OnServerEvent(Callback: (Player: Player, ...any) -> nil): { Disconnect: () -> nil }
	return self.__Fired:Connect(Callback)
end

--[=[
	@method Fire
	@within Replica
	@param ... any
	@return nil

	Sends a request to the client, sending the arguments to the client.
]=]
function ServerReplica:Fire(...)
	local Args = { ... }
	self.__Fire(Net.fireClientEvent, { Args = Args })
end

--[=[
	@method SetParent
	@within Replica
	@server
	@param Parent ServerReplica
	@return nil

	Sets the parent of the replica, and then replicates the change to the client.
]=]
function ServerReplica:SetParent(Parent: Types.ServerReplica)
	if not Parent.__IsParent then
		Logger("Warn", "Attempt to set a parent that is not a parent replica.")
		return
	end

	if not Parent.__Ready then
		repeat
			task.wait()
		until Parent.__Ready
	end

	self.__Parent = Parent
	local Previous: any = self.To
	self.To = Parent.To

	self.__ReplicateToChanged:Fire(Previous, self.To)

	self.__Fire(Net.changeParent, {
		Parent = Parent.Id,
	})
end

--[=[
	@method ReplicateFor
	@within Replica
	@server
	@param Player Player
	@return nil

	Replicates the replica to the specified player.
	This should only ever be intentionally called from the Server.
	-- Credit to @Fuse for implementation of this function.
]=]
function ServerReplica:ReplicateFor(player: Player)
	-- Ensure player can be replicated to
	if self.To == "All" then
		return warn(`Attempt to update replication when To="All".\n{debug.traceback()}`)
	end

	if type(self.To) == "table" and table.find(self.To, player) then
		return
	end

	-- Replicate to player
	local Previous = self.To

	if typeof(self.To) == "Instance" then
		self.To = { self.To }
	end

	table.insert(self.To, player)
	self.__ReplicateToChanged:Fire(Previous, self.To)

	-- Replicate main replica to player
	CreateReplica(player, self)

	if self.__IsParent then
		for _, ChildReplica in self:GetChildren() do
			ChildReplica.__ReplicateToChanged:Fire(Previous, self.To)
		end
	end
end

--[=[
    @method Destroy
    @within Replica
    @server
    @return nil

    Destroys the replica and cleans up any tasks that were added to the cleaner.
    [Destroying] will be fired when the replica is destroyed.
    This should only ever be intentionally called from the Server.
]=]
function ServerReplica:Destroy()
	self.Destroying:Fire()

	Replicas[self.Id] = nil

	Net.destroyReplica.fireAll(self.Id)

	if self.__IsParent then
		for _, ChildReplica in self:GetChildren() do
			ChildReplica.To = self.To
			Net.destroyReplica.fireAll(ChildReplica.Id)
		end
	end
	
	task.defer(self.__Cleaner.Destroy, self.__Cleaner)
	table.clear(self)
end

--[=[
	@method DestroyFor
	@within Replica
	@server
	@return nil

	Destroys the replica for the specified player.
	This should only ever be intentionally called from the Server.
	-- Credit to @Fuse for implementation of this function.
]=]
function ServerReplica:DestroyFor(Player: Player)
	if self.To == "All" then
		return warn(`Attempt to destroy replication for {Player} when To="All".\n{debug.traceback()}`)
	end

	if typeof(self.To) == "Instance" then
		self.To = nil
	elseif typeof(self.To) == "table" then
		local index = table.find(self.To, Player)
		if index then
			table.remove(self.To, index)
		end
	end

	Net.destroyReplica.fire(Player, self.Id)

	if self.__IsParent then
		for _, ChildReplica in self:GetChildren() do
			ChildReplica.To = self.To
			Net.destroyReplica.fire(Player, ChildReplica.Id)
		end
	end
end

--[=[ 
    @class ReplicatedTable
    @server

    Mutating this table will cause the changes to be replicated to the client.
    -- Iterating over the table will return the index, value, and a function to set the value.
    ```lua
    local Replica = Replicator.NewReplica({
        Name = "Replica",
        Tags = { "Test" },
        Data = {
            Array = { 1, 2, 3 },
        }
    })
    
    local Array = Replica.Data.Array
    
    for Index, Value, SetValue in Array do
        print(Index, Value)
        SetValue(10)
    end
    ```
]=]

--[=[
    @method Insert
    @within ReplicatedTable
    @param Index number?
    @param Value any
    @return nil

    - If the table is an array, inserts a value into the array at the specified index or at the end of the array.
    - If the table is a dictionary, this function call will not exist and may throw an error.

    ```lua
    local Replica = Replicator.NewReplica({
        Name = "Replica",
        Tags = { "Test" },
        Data = {
            Array = { 1, 2, 3 },
        }
    })
    
    local Array = Replica.Data.Array
    
    Array:Insert(2, 10)
    Array:Insert(15)

    for Index, Value in Array:Get() do
        print(Value)
    end
    ---> 1, 10, 2, 3, 15
    ```
]=]

--[=[
    @method Remove
    @within ReplicatedTable
    @param Index number
    @return nil

    - If the table is an array, removes the value at the specified index.
    - If the table is a dictionary, this function call will not exist and may throw an error.

    ```lua
    local Replica = Replicator.NewReplica({
        Name = "Replica",
        Tags = { "Test" },
        Data = {
            Array = { 1, 2, 3 },
        }
    })
    
    local Array = Replica.Data.Array
    
    Array:Remove(2)

    for Index, Value in Array:Get() do
        print(Value)
    end
    ---> 1, 3
    ```
]=]

--[=[
    @method Get
    @within ReplicatedTable
    @return any

    Returns a deep copy of the table.
]=]

local ValidKeyTypes = { "string", "number" }

local function ListenToTable(RegisterUpdate: (...any) -> nil, Table, Indicies: { [number]: any }?): Types.ReplicaTable
	local OldData = CopyDeep(Table)

	local Method = setmetatable({
		__type = "Replicated Table",
		__value = {},
	}, {
		__index = function(self, Key)
			return rawget(self.__value, Key) or rawget(Table, Key)
		end,
		__tostring = function()
			return "[[Replicated Table]]"
		end,
		__newindex = function(self, Key, Value)
			local validKey = table.find(ValidKeyTypes, typeof(Key))

			if not validKey then
				warn(`Attempt to assign a value to a key that is not a string or number. {type(Key)} was given.`)
				return
			end

			local IsTable = type(Value) == "table"

			if IsTable and Value.__type == "Replicated Table" then
				Logger("Warn", "Attempt to assign a replicated table to another replicated table.")
				return
			end

			local Updated = false

			if Sift.Array.is(Table) and Value == nil then
				Logger("Warn", "Use :Remove() to remove an element from an array.")
				return
			else
				local TValue = rawget(Table, Key)
				if
					(IsTable and type(TValue) == "table" and not Dictionary.equalsDeep(Value, TValue))
					or TValue ~= Value
				then
					Updated = true
					rawset(Table, Key, Value)
				end
			end

			local _Indicies = table.clone(Indicies or {})
			_Indicies[#_Indicies + 1] = Key

			if Updated then
				RegisterUpdate(_Indicies, if IsTable then CopyDeep(Value) else Value, OldData)
				OldData = CopyDeep(Table)
			end

			if IsTable then
				rawset(self.__value, Key, ListenToTable(RegisterUpdate, Value, _Indicies))
			end

			if (Sift.Array.is(Table) or Sift.Dictionary.count(Table) == 0) and not rawget(self, "Insert") then
				rawset(self, "Insert", function(_, ...)
					local Args = { ... }
					local InsertIndices = table.clone(Indicies or {})
					local Index = if #Args > 1 then Args[1] else #Table + 1
					local _Value = if #Args > 1 then Args[2] else Args[1]
					InsertIndices[#InsertIndices + 1] = Index
					table.insert(Table, Index, _Value)
					if _Value and type(_Value) == "table" then
						rawset(self, Index, ListenToTable(RegisterUpdate, _Value, InsertIndices))
					end
					RegisterUpdate(InsertIndices, _Value, OldData)
					OldData = CopyDeep(Table)
				end)
				rawset(self, "insert", rawget(self, "Insert"))
				rawset(self, "Remove", function(_, Index: number)
					local _Indicies = table.clone(Indicies or {})
					_Indicies[#_Indicies + 1] = Index
					local _Value = table.remove(Table, Index)
					if _Value and type(_Value) == "table" then
						rawset(self, Index, nil)
					end
					RegisterUpdate(_Indicies, nil, OldData)
					OldData = CopyDeep(Table)
				end)
				rawset(self, "remove", rawget(self, "Remove"))
			elseif not Sift.Array.is(Table) and rawget(self, "Insert") then
				rawset(self, "Insert", nil :: any)
				rawset(self, "insert", nil :: any)
				rawset(self, "Remove", nil :: any)
				rawset(self, "remove", nil :: any)
			end
		end,
		__iter = function(self)
			local Cleaner = {}
			local AlreadyVisited = {}

			return function(): (any, any, any)
				for Index, Value in pairs(Table) do
					if not table.find(AlreadyVisited, Index) then
						table.insert(AlreadyVisited, Index)

						local _Indicies = table.clone(Indicies or {})
						_Indicies[#_Indicies + 1] = Index
						Value = if type(Value) == "table"
							then ListenToTable(RegisterUpdate, Value, _Indicies)
							else Value

						return Index,
							Value,
							function(NewValue)
								local IsReplicatedTable = type(NewValue) == "table"
									and NewValue.__type
									and NewValue.__type == "Replicated Table"

								if IsReplicatedTable then
									local T = CopyDeep(NewValue)
									rawset(Table[Index], Index, T)
									return
								else
									self[Index] = NewValue
								end
							end
					end
				end

				table.clear(Cleaner)
				table.clear(AlreadyVisited)
				return nil, nil, nil
			end
		end,
	}) :: any

	rawset(Method, "Get", function()
		return CopyDeep(Table)
	end)
	rawset(Method, "get", rawget(Method, "Get"))

	for Index, Value in Table do
		if type(Value) == "table" then
			if Value.__type and Value.__type == "Replicated Table" then
				rawset(Method, Index, Value)
			else
				Method[Index] = Value
			end
		end
	end

	if Sift.Array.is(Table) or Sift.Dictionary.count(Table) == 0 then
		rawset(Method, "Insert", function(_, ...)
			local Args = { ... }
			local InsertIndices = table.clone(Indicies or {})
			local Index = if #Args > 1 then Args[1] else #Table + 1
			local _Value = if #Args > 1 then Args[2] else Args[1]
			InsertIndices[#InsertIndices + 1] = Index
			table.insert(Table, Index, _Value)
			if _Value and type(_Value) == "table" then
				rawset(Method, Index, ListenToTable(RegisterUpdate, _Value, InsertIndices))
			end
			RegisterUpdate(InsertIndices, _Value, OldData)
			OldData = CopyDeep(Table)
		end)
		rawset(Method, "insert", rawget(Method, "Insert"))
		rawset(Method, "Remove", function(_, Index: number)
			local _Indicies = table.clone(Indicies or {})
			_Indicies[#_Indicies + 1] = Index
			local _Value = table.remove(Table, Index)
			if _Value and type(_Value) == "table" then
				rawset(Method, Index, nil)
			end
			RegisterUpdate(_Indicies, nil, OldData)
			OldData = CopyDeep(Table)
		end)
		rawset(Method, "remove", rawget(Method, "Remove"))
	end

	return Method
end

export type ServerReplica = Replica.Replica & typeof(setmetatable({} :: Types.ServerReplica, ServerReplica))

local function NewReplica(Config: Types.ServerConfig): ServerReplica
	local Parent: Types.ServerReplica? = Config.Parent :: Types.ServerReplica?

	if Parent and Parent.To then
		Config.To = Parent.To
	elseif not Config.To then
		Config.To = "All"
	end

	local self = setmetatable(Replica.new(Config), ServerReplica)

	self.__ReplicateToChanged = Signal.new()
	
	self.__ReplicateToChanged:Connect(function(Previous, New)
		if Previous == "All" then
			Previous = game.Players:GetPlayers()
		elseif typeof(Previous) == "Instance" then
			Previous = { Previous }
		end

		if New == "All" then
			New = game.Players:GetPlayers()
		elseif typeof(New) == "Instance" then
			New = { New }
		end

		for _, Player in Previous do
			if not table.find(New, Player) then
				self:DestroyFor(Player)
			end
		end

		for _, Player in New do
			if not table.find(Previous, Player) then
				CreateReplica(Player, self)
			end
		end
	end)

	local Changes = {}

	self.__Fire = function(Event, Packet)
		Packet.Id = self.Id

		if Config.To == "All" or not Config.To then
			Event.fireAll(Packet)
		elseif typeof(Config.To) == "table" then
			Event.fireList(Config.To, Packet)
		else
			Event.fire(Config.To, Packet)
		end
	end

	local function RegisterUpdate(Path, Value, OldData)
		self.__Change:Fire(Path, Value, self.__OldData)
		self.__OldData = CopyDeep(OldData)

		local Found = Array.findWhere(Changes, function(ChangeInfo)
			return Path == ChangeInfo.Path
		end)

		if Found and os.clock() > Found.Time then
			Found.Value = Value
			Found.Time = os.clock()
			return
		end

		table.insert(Changes, { Time = os.clock(), Path = Path, Value = Value })
	end

	if Config.Data then
		self.__OldData = CopyDeep(Config.Data)
		self.Data = ListenToTable(RegisterUpdate, Config.Data)
	end

	if
		Config.WriteLib
		and Config.WriteLib:IsA("ModuleScript")
		and Config.WriteLib:IsDescendantOf(game.ReplicatedStorage)
	then
		self.WriteLib = Config.WriteLib
		self.__WriteLib = require(self.WriteLib) :: { [string]: (self: ServerReplica, ...any) -> unknown }
	elseif Config.WriteLib then
		Logger("Error", "WriteLib must be a ModuleScript and a descendant of ReplicatedStorage.")
	end

	self.__Fire(Net.createReplica, {
		Name = self.Name,
		Tags = self.Tags,
		Data = self.Data and self.Data:Get(),
		WriteLib = self.WriteLib,
		Parent = Config.Parent and Config.Parent.Id,
	})

	self.__Ready = true
	Replicas[self.Id] = self

	self:AddCleanupMethod(task.spawn(function()
		while true do
			if self.__Ready and #Changes > 0 then
				self.__Fire(Net.updateReplica, {
					Id = self.Id,
					Changes = Changes,
				})
			end

			table.clear(Changes)

			task.wait(.1)
		end
	end), true)

	return self
end

Net.getInitialReplicas.on(function(Player: Player)
	return Dictionary.values(Dictionary.map(
		Dictionary.filter(Replicas, function(_Replica)
			return _Replica.To == "All"
				or (typeof(_Replica.To) == "table" and table.find(_Replica.To, Player))
				or _Replica.To == Player
		end),
		function(_Replica)
			return {
				Id = _Replica.Id,
				Name = _Replica.Name,
				Tags = _Replica.Tags,
				Data = if _Replica.Data then _Replica.Data:Get() else nil,
				Parent = if _Replica.__Parent then _Replica.__Parent.Id else nil,
				IsParent = _Replica.__IsParent,
				WriteLib = _Replica.WriteLib,
			}
		end
	))
end)

Net.fireServerEvent.on(function(Player, Packet)
	local _Replica = Replicas[Packet.Id]

	if _Replica then
		_Replica.__Fired:Fire(Player, unpack(Packet.Args or {}))
	end
end)

game:BindToClose(function()
	for _, _Replica in pairs(Replicas) do
		task.defer(_Replica.Destroy, _Replica)
	end

	table.clear(Replicas)
end)

--[=[
    @function NewReplica
    @within Replicator
    @server
    @param Config {Name: string, Tags: { string }?, Data: {[any]: any}?, WriteLib: ModuleScript?, To: Types.ToOptions?, Parent: Replica]?, IsParent: boolean?}
    @return Replica
]=]
return table.freeze({
	NewReplica = NewReplica,
})
