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

local Replicators = {}

local function FindReplicaById(Id: string?): Types.ClientReplica?
	if Id then
		for _, _Replicator in pairs(Replicators) do
			if not _Replicator.IsParent then
				continue
			end

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

Replication.createReplica.listen(function(_Replica)
	local _Replicator = Replicators[_Replica.Name]

	if not _Replicator then
		_Replicator = NewReplicator(_Replica.Name, _Replica.IsParent)
	end

	if not _Replicator.__Replicas[_Replica.Id] then
		task.spawn(_Replicator.AddReplica, _Replicator, NewReplica(_Replica))
	else
		Logger("Warn", "Replica already exists")
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
	Changes: { { Time: number, Path: { string | number }, Value: any } },
}

Replication.replicateChanges.listen(function(Data: Packet)
	local _Replicator = Replicators[Data.Name]

	if _Replicator then
		local _Replica = _Replicator.__Replicas[Data.Id]

		if _Replica then
			if _Replica.__IsParent then
				warn("Parent replicas cannot be altered")
				return
			end

			table.sort(Data.Changes, function(A, B)
				return A.Time < B.Time
			end)

			local AlteredKeys = {}

			for _, Change in Data.Changes do
				task.spawn(function()
					local Path = Change.Path
					local _Data = _Replica.Data
					local _OldData = CopyDeep(_Replica.Data)

					if table.find(AlteredKeys, table.concat(Path, ":")) then
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

						if Array.is(_Data) then
							if Change.Value == nil then
								table.remove(_Data, LastKey)
							elseif _Data[LastKey] then
								_Data[LastKey] = Change.Value
							else
								table.insert(_Data, LastKey, Change.Value)
							end
						else
							_Data[LastKey] = Change.Value
						end

						_Replica.__Change:Fire(Path, _Data[LastKey], _OldData)
					end
				end)
			end
		end
	end
end)

Replication.getInitialReplicas.listen(function(_Replicas)
	table.sort(_Replicas, function(A, B)
		return A.IsParent and not B.IsParent
	end)

	for _, _Replica in _Replicas do
		local _Replicator = Replicators[_Replica.Name]

		if not _Replicator then
			_Replicator = NewReplicator(_Replica.Name, _Replica.IsParent)
		end

		task.defer(_Replicator.AddReplica, _Replicator, NewReplica(_Replica))
	end
end)

Replication.getInitialReplicas.send()

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
