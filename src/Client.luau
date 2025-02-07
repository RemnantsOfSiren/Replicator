--!strict
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
local Replicators = {}

local function FindReplicaById(Id: string?): Types.ClientReplica?
	if Id then
		for _, _Replicator in pairs(Replicators) do
			if not _Replicator.IsParent then
				continue
			end

			local _Replica = _Replicator.__Replicas[Id]

			if _Replica then
				return _Replica
			end
		end
	end

	return nil
end

local Replica = {}
Replica.__index = Replica

function Replica:GetChildren()
	if self.__IsParent then
		return Dictionary.filter(Replicas, function(_, _Replica)
			return _Replica.__Parent == self
		end)
	else
		warn("Replica is not a parent.")
		return {}
	end
end

--[=[
	@method OnClientEvent
	@within Replica
	@client
	@param Callback (Player: Player, ...any) -> nil
	@return { Disconnect: () -> nil }

	Listens for a client event, and fires the callback with the arguments passed.
]=]
function Replica:OnClientEvent(Callback: (Player: Player, ...any) -> nil): { Disconnect: () -> nil }
	return self.__Fired:Connect(Callback)
end

function Replica:Fire(...)
	local Args = { ... }

	Replication.fireEvent.send({
		Name = self.Name,
		Id = self.Id,
		Args = Args,
	})
end

function Replica:Destroy()
	Replicas[self.Id] = nil
	self.Destroying:Fire()
	task.defer(self.__Cleaner.Destroy, self.__Cleaner)
	table.clear(self)
end

local function NewReplica(Config: {
	Name: string,
	Id: string,
	Tags: { any },
	Data: any,
	WriteLib: ModuleScript?,
	Parent: string?,
	IsParent: boolean?,
}): Types.ClientReplica
	local Cleaner = Trove.new()

	local Parent

	if Config.Parent then
		repeat
			Parent = FindReplicaById(Config.Parent)
			task.wait()
		until Parent
	end

	local self = setmetatable({
		Id = Config.Id,
		Name = Config.Name,
		Tags = Config.Tags,
		Data = Config.Data,
		__IsParent = Config.IsParent,

		__Write = Cleaner:Construct(Signal),
		__Fired = Cleaner:Construct(Signal),
		__Change = Cleaner:Construct(Signal),
		Destroying = Cleaner:Construct(Signal),

		__Cleaner = Cleaner,

		__Parent = Parent,
		WriteLib = Config.WriteLib,
		__WriteLib = Config.WriteLib and require(Config.WriteLib) :: { [any]: any } or nil,
	}, Replica)

	for Key, Function in SharedFunctions do
		self[Key] = Function
	end

	self.__Cleaner:Connect(self.Destroying, function()
		self.__Cleaner:Destroy()
	end)

	Replicas[Config.Id] = self

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
		for I = #self.__Listeners, 1, -1 do
			if self.__Listeners[I] == Callback then
				table.remove(self.__Listeners, I)
			end
		end
		table.sort(self.__Listeners)
	end
end

function Replicator:AddReplica(_Replica)
	if self.__Replicas[_Replica.Id] then
		return
	elseif _Replica.Name ~= self.Name then
		Logger("Warn", "Replica name does not match replicator name.")
		return
	end

	self.__Replicas[_Replica.Id] = _Replica
	for _, Listener in self.__Listeners do
		task.spawn(Listener, _Replica)
	end
end

local function NewReplicator(Name: string, IsParent: boolean)
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

Replication.packets.createReplica.listen(function(_Replica)
	local _Replicator = NewReplicator(_Replica.Name, _Replica.IsParent)

	if not Replicas[_Replica.Id] then
		task.spawn(_Replicator.AddReplica, _Replicator, NewReplica(_Replica))
	else
		Logger("Warn", "Replica already exists")
	end
end)

Replication.packets.destroyReplica.listen(function(Id)
	local _Replica = Replicas[Id]

	if _Replica then
		local Name = _Replica.Name
		local _Replicator = Replicators[Name]
		if _Replicator then
			_Replicator.__Replicas[Id] = nil
		end
		_Replica:Destroy()
	end
end)

Replication.packets.replicateChanges.listen(function(Data: Types.Packet)
	local _Replica = Replicas[Data.Id]

	if _Replica then
		if _Replica.__IsParent then
			Logger("Warn", "Parent replicas cannot be altered.")
			return
		end

		table.sort(Data.Changes, function(A, B)
			return A.Time < B.Time
		end)

		for _, Change in Data.Changes do
			local Path = Change.Path
			local _Data = _Replica.Data

			for I = 1, #Path - 1 do
				local Key = Path[I]
				_Data = _Data[Key]

				if type(_Data) ~= "table" then
					Logger("Warn", `Replica ({_Replica.Id}) attempting to index a non table value at key {Key}.`)
				end

				if not _Data then
					return
				end
			end

			if _Data then
				local _OldData = CopyDeep(_Replica.Data)
				local LastKey = Path[#Path]

				if LastKey ~= nil and type(LastKey) == "number" and (Array.is(_Data) or Dictionary.count(_Data) == 0) then
					if Change.Value == nil then
						table.remove(_Data, LastKey :: number)
					elseif _Data[LastKey] then
						_Data[LastKey] = Change.Value
					else
						table.insert(_Data, LastKey :: number, Change.Value)
					end
				else
					pcall(function() 
						_Data[LastKey] = Change.Value
					end)
				end

				_Replica.__Change:Fire(Path, _Data[LastKey], _OldData)
			end
		end
	end
end)

Replication.packets.fireEvent.listen(function(Data)
	local _Replica = Replicas[Data.Id]

	if _Replica then
		_Replica.__Fired:Fire(table.unpack(Data.Args))
	end
end)

Replication.packets.changeParent.listen(function(Info)
	local _Replica = Replicas[Info.Id]

	if _Replica then
		local _Parent = FindReplicaById(Info.Parent)
		_Replica.__Parent = _Parent
	end
end)

task.defer(function()
	local _Replicas = Replication.queries.getInitialReplicas.invoke()
	
	table.sort(_Replicas, function(A, B)
		return A.IsParent and not B.IsParent
	end)

	for _, _Replica in _Replicas do
		local _Replicator = Replicators[_Replica.Name]

		if not _Replicator then
			_Replicator = NewReplicator(_Replica.Name, _Replica.IsParent)
		end

		if not Replicas[_Replica.Id] then
			task.spawn(_Replicator.AddReplica, _Replicator, NewReplica(_Replica))
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

			Listener = _Replicator:AddListener(Callback)
		end)

		return Disconnector
	end,
})
