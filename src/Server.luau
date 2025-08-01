--!strict
local Sift = require(script.Parent.Parent.Sift) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

local Logger = require(script.Parent.Logger)
local Net = require(script.Parent.Net.Server)
local Parser = require(script.Parent.Parser)
local Types = require(script.Parent.Types)

local Dictionary = Sift.Dictionary

local Replicas: { [string]: ServerReplica } = {}

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

local CreateReplicatedTable = require(script.Parent.ReplicatedTable)

export type ServerReplica = Replica.Replica & typeof(setmetatable({} :: Types.ServerReplica, ServerReplica))

local Changes: Types.Packet = {} :: Types.Packet

local function NewReplica(Config: Types.ServerConfig): ServerReplica
	local Parent: Types.ServerReplica? = Config.Parent :: Types.ServerReplica?

	if Parent and Parent.To then
		Config.To = Parent.To
	elseif not Config.To then
		Config.To = "All"
	end

	local self = setmetatable(Replica.new(Config), ServerReplica) :: ServerReplica

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
				CreateReplica(Player, self :: { [string | number]: any })
			end
		end
	end)

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

	if Config.Data then
		self.Data = self:AddCleanupMethod(CreateReplicatedTable(Config.Data), "Destroy")

		self:AddCleanupMethod(
			self.Data.__signal:Connect(function(ReplicatedTable)
				if not Changes[self.Id] then
					Changes[self.Id] = {}
				end

				local OldData = ReplicatedTable.__oldtable
				local Data = ReplicatedTable:Get()

				local _Changes = {}

				-- Check for keys removed
				for Key in OldData do
					if Data[Key] == nil then
						table.insert(_Changes, {
							Key = tostring(Key),
							Value = nil,
							IsNumber = type(Key) == "number",
						})

						local Indicies = table.clone(ReplicatedTable.__indicies or {})
						Indicies[#Indicies + 1] = Key
						self.__Change:Fire(Indicies, Data, OldData)
					end
				end

				for Key, Value in Data do
					local IsEqual

					local _OldData = OldData[Key]

					if typeof(_OldData) == "table" and typeof(Value) == "table" then
						IsEqual = Dictionary.equalsDeep(_OldData, Value)
					else
						IsEqual = _OldData == Value
					end

					if not IsEqual then
						table.insert(_Changes, {
							Key = tostring(Key),
							Value = Value,
							IsNumber = type(Key) == "number",
						})

						local Indicies = table.clone(ReplicatedTable.__indicies or {})
						Indicies[#Indicies + 1] = Key
						self.__Change:Fire(Indicies, Data, OldData)
					end
				end

				local OutterMostUpdated = ReplicatedTable:GetUpdatedAncestor()

				if OutterMostUpdated ~= ReplicatedTable then
					ReplicatedTable = OutterMostUpdated
				end

				local Found = false

				for _, Change in Changes[self.Id] do
					if Change.Path == ReplicatedTable.__indicies then

						Changes[self.Id] = {
							Path = ReplicatedTable.__indicies,
							Changes = Dictionary.merge(Change.Changes or {}, _Changes or {}),
						}

						Found = true
						break
					end
				end

				if not Found then
					Changes[self.Id] = {
						Path = ReplicatedTable.__indicies,
						Changes = _Changes,
					}
				end
			end),
			"Disconnect"
		)
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
		Parent = Config.Parent and Config.Parent.Id,
		WriteLib = self.WriteLib,
	})

	self.__Ready = true
	Replicas[self.Id] = self

	return self
end

Net.getInitialReplicas.on(function(Player: Player)
	return Dictionary.values(Dictionary.map(
		Dictionary.filter(Replicas, function(_Replica)
			return _Replica.To == "All"
				or (typeof(_Replica.To) == "table" and table.find(_Replica.To, Player))
				or (_Replica.To :: Player) == Player
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

task.spawn(function()
	while true do
		if Dictionary.count(Changes) > 0 then
			Net.updateReplicas.fireAll(Changes)
			table.clear(Changes)
		end
		task.wait()
	end
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
