--!strict
local Sift = require(script.Parent.Parent.Sift) :: any

local Logger = require(script.Parent.Logger)
local Net = require(script.Parent.Net.Client)
local Types = require(script.Parent.Types)
local Serializer = require(script.Parent.Serializer)

local Dictionary = Sift.Dictionary
local CopyDeep = Dictionary.copyDeep

local Replicas = {}
local Replicators = {}

local function FindReplicaById(Id: string?): Types.ClientReplica?
	return Replicas[Id]
end

local Replica = require(script.Parent.Replica)

local ClientReplica = {}
ClientReplica.__index = ClientReplica
setmetatable(ClientReplica, { __index = Replica })

function ClientReplica:GetChildren()
	if self.__IsParent then
		return Dictionary.filter(Replicas, function(_, _Replica)
			return _Replica.__Parent == self
		end)
	else
		Logger("Warn", "Replica is not a parent.")
		return {}
	end
end

--[=[
	@method OnClientEvent
	@within Replica
	@client
	@param Callback (...any) -> nil
	@return { Disconnect: () -> nil }

	Listens for a client event, and fires the callback with the arguments passed.
]=]
function ClientReplica:OnClientEvent(Callback: (...any) -> nil): { Disconnect: () -> nil }
	return self.__Fired:Connect(Callback)
end

function ClientReplica:Fire(...)
	local Args = { ... }

	Net.fireServerEvent.fire({
		Id = self.Id,
		Args = Args,
	})
end

function ClientReplica:Destroy()
	Replicas[self.Id] = nil
	self.Destroying:Fire()
	task.defer(self.__Cleaner.Destroy, self.__Cleaner)
	table.clear(self)
end

export type ClientReplica = Replica.Replica & typeof(setmetatable({} :: Types.ClientReplica, ClientReplica))

local function NewReplica(Config: Types.ClientConfig): ClientReplica
	if Config.WriteLib and not Config.WriteLib:IsA("ModuleScript") then
		return Logger("Warn", "WriteLib must be a ModuleScript.")
	end

	local Parent

	if Config.Parent then
		repeat
			Parent = FindReplicaById(Config.Parent)
			task.wait()
		until Parent
	end

	local self = setmetatable(Replica.new(Config), ClientReplica) :: ClientReplica

	Replicas[Config.Id] = self

	return self
end

local Replicator = {}
Replicator.__index = Replicator

function Replicator:AddListener(Callback)
	table.insert(self.__Listeners, Callback)

	for _, _Replica in pairs(self.__Replicas) do
		task.spawn(Callback, FindReplicaById(_Replica))
	end

	return function()
		for I = #self.__Listeners, 1, -1 do
			if self.__Listeners[I] == Callback then
				table.remove(self.__Listeners, I)
			end
		end
		table.sort(self.__Listeners)
	end
end

function Replicator:AddReplica(_Replica)
	if table.find(self.__Replicas, _Replica.Id) then
		return
	elseif _Replica.Name ~= self.Name then
		Logger("Warn", "Replica name does not match replicator name.")
		return
	end

	table.insert(self.__Replicas, _Replica.Id)

	for _, Listener in self.__Listeners do
		task.spawn(Listener, _Replica)
	end
end

local function NewReplicator(Name: string, IsParent: boolean?)
	if Replicators[Name] then
		return Replicators[Name]
	end

	local self = setmetatable({
		Name = Name,
		IsParent = IsParent,
		__Replicas = {},
		__Listeners = {},
	}, Replicator)

	Replicators[Name] = self

	return self
end

Net.createReplica.on(function(_Replica)
	local _Replicator = NewReplicator(_Replica.Name, _Replica.IsParent)

	if not Replicas[_Replica.Id] then
		task.spawn(_Replicator.AddReplica, _Replicator, NewReplica(_Replica :: any))
	else
		Logger("Warn", "Replica already exists")
	end
end)

Net.destroyReplica.on(function(Id)
	local _Replica = FindReplicaById(Id)

	if _Replica then
		local Name = _Replica.Name
		local _Replicator = Replicators[Name]

		if _Replicator then
			table.remove(_Replicator.__Replicas, table.find(_Replicator.__Replicas, Id))
		end

		_Replica:Destroy()
	end
end)

Net.fireClientEvent.on(function(Data)
	local _Replica = Replicas[Data.Id]

	if _Replica then
		local Args = Data.Args or {}
		_Replica.__Fired:Fire(table.unpack(Args))
	end
end)

Net.changeParent.on(function(Info)
	local _Replica = Replicas[Info.Id]

	if _Replica then
		local _Parent = FindReplicaById(Info.Parent)
		_Replica.Parent = _Parent
	end
end)

local function BatchUpdateReplica(Id, Changes)
	local _Replica = Replicas[Id]

	if not _Replica then
		return
	end

	local Data = _Replica.Data

	if not Data then
		return
	end

	local OldData = CopyDeep(Data)

	for _, Packet in Changes do
		local _Path = Serializer.ConvertToPath(Packet.Path)

		local _Data = Data

		for I = 1, #_Path - 1 do
			local Key = _Path[I]
			_Data = _Data[Key]
		end

		if Packet.Action == "Set" then
			_Data[_Path[#_Path]] = Packet.Value
		elseif Packet.Action == "Remove" then
			table.remove(_Data, _Path[#_Path])
		elseif Packet.Action == "Insert" then
			table.insert(_Data, Packet.Value)
		end

		_Replica.__Change:Fire(_Path, Data, OldData)
	end
end

Net.updateReplicas.on(function(Data)
	for Id, Change in Data do
		task.spawn(BatchUpdateReplica, Id, Change)
	end
end)

task.defer(function()
	local _Replicas = Net.getInitialReplicas.invoke()

	table.sort(_Replicas, function(A: { [any]: any }, B: { [any]: any })
		return A.IsParent and not B.IsParent
	end)

	for _, _Replica in _Replicas do
		local _Replicator = Replicators[_Replica.Name]

		if not _Replicator then
			_Replicator = NewReplicator(_Replica.Name, _Replica.IsParent)
		end

		if not Replicas[_Replica.Id] then
			task.spawn(_Replicator.AddReplica, _Replicator, NewReplica(_Replica :: any))
		end
	end
end)

--[=[
    @function ListenToNewReplica
    @within Replicator
    @client
    @param Name string
    @param Callback (Replica: Replica) -> nil
    @return () -> nil

    Listens to new replicas being created, and fires the callback with the new replica.
    returns a function that when called, disconnects the listener.
]=]
return table.freeze({
	ListenToNewReplica = function(Name: string, Callback: (...any) -> nil)
		local Listener

		local Disconnector = function()
			if Listener then
				Listener()
			end
		end

		task.spawn(function()
			local _Replicator = Replicators[Name]

			if not _Replicator then
				repeat
					_Replicator = Replicators[Name]
					task.wait()
				until _Replicator
			end

			Listener = (_Replicator :: any):AddListener(Callback)
		end)

		return Disconnector
	end,
})
