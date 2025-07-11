--!strict
local Sift = require(script.Parent.Parent.Sift) :: any

local Net = require(script.Parent.Net.Client)
local Types = require(script.Parent.Types)
local Logger = require(script.Parent.Logger)

local Array = Sift.Array
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

-- Net.updateReplica.on(function(Data: Types.Packet)
-- 	local _Replica = Replicas[Data.Id]

-- 	if _Replica then
-- 		table.sort(Data.Changes, function(A, B)
-- 			return A.Time < B.Time
-- 		end)

-- 		for _, Change in Data.Changes do
-- 			local Path = Change.Path
-- 			local _Data = _Replica.Data

-- 			if not _Data then
-- 				continue
-- 			end

-- 			for I = 1, #Path - 1 do
-- 				local Key = Path[I]
-- 				_Data = _Data[Key]

-- 				if type(_Data) ~= "table" then
-- 					Logger("Warn", `Replica ({_Replica.Id}) attempting to index a non table value at key {Key}.`)
-- 				end

-- 				if not _Data then
-- 					return
-- 				end
-- 			end

			
-- 			if _Data then
-- 				local _OldData = CopyDeep(_Replica.Data)
-- 				local LastKey = Path[#Path]

-- 				local Value = Change.Value

-- 				if
-- 					LastKey ~= nil
-- 					and type(LastKey) == "number"
-- 					and (Array.is(_Data) or Dictionary.count(_Data) == 0)
-- 				then
-- 					if Value == nil then
-- 						table.remove(_Data :: { [number]: any }, LastKey :: number)
-- 					elseif _Data[LastKey] then
-- 						_Data[LastKey] = Value
-- 					else
-- 						table.insert(_Data :: { [number]: any }, LastKey :: number, Value)
-- 					end
-- 				else
-- 					pcall(function()
-- 						_Data[LastKey] = Value
-- 					end)
-- 				end

-- 				_Replica.__Change:Fire(Path, _Data[LastKey], _OldData)
-- 			end
-- 		end
-- 	end
-- end)

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

local function BatchUpdateReplica(Id: string, Changes: {{ Path: { [any]: any }, Value: any, Time: number }})
	if #Changes == 0 then
		return
	end

	table.sort(Changes, function(A, B)
		return A.Time < B.Time
	end)

	local _Replica = Replicas[Id]

	if not _Replica then
		return
	end

	for _, Change in Changes do
		local Path = Change.Path
		local Value = Change.Value
		local _Data = _Replica.Data
		
		if not _Data then
			continue
		end
		
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
			local LastKey = Path[#Path]
			local OldData = _Data[LastKey]
			_Data[LastKey] = Value
			_Replica.__Change:Fire(Path, Value, OldData)
		end
		
		task.wait()
	end
end

Net.updateReplicas.on(function(Data)
	for Id, Changes in Data do
		if #Changes == 0 then
			continue
		end

		task.spawn(BatchUpdateReplica, Id, Changes)
	end
end)

task.defer(function()
	local _Replicas = Net.getInitialReplicas.invoke()

	table.sort(_Replicas, function(A: {[any]: any}, B: {[any]: any})
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
