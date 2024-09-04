local HttpService = game:GetService("HttpService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Util = require(script.Parent.Table) :: { any }
local Parser = require(script.Parent.Parser) :: ({ string | number } | string) -> { any }

local BridgeNet = require(script.Parent.Parent.BridgeNet) :: { any }
local LemonSignal = require(script.Parent.Parent.Signal) :: { any }
local Trove = require(script.Parent.Parent.Trove) :: { any }
local Types = require(script.Parent.Types) :: { any }

export type ReplicaConfig = {
	Name: string,
	Tags: { any }?,
	Data: { any },
	To: { Player } | Player | "All",
	WriteLib: ModuleScript?,
}

local Replicas = {}
local WriteLibCache = {}

local function LoadWriteLib(WriteLibModule: ModuleScript)
	local FoundWriteLib = WriteLibCache[WriteLibModule]

	if FoundWriteLib then -- Already cached a WriteLib module
		return FoundWriteLib
	end

	if WriteLibModule.ClassName ~= "ModuleScript" then
		warn("WriteLib must be a ModuleScript!")
		return
	end

	if not WriteLibModule:IsDescendantOf(ReplicatedStorage) then
		warn("WriteLib must be a descendant of ReplicatedStorage!")
		return
	end

	local LoadedWriteLib = require(WriteLibModule)

	if typeof(LoadedWriteLib) ~= "table" then
		warn("WriteLib must return a table!")
		return
	end

	WriteLibCache[WriteLibModule] = LoadedWriteLib

	return LoadedWriteLib
end

local MainBridge = BridgeNet.ServerBridge("ReplicaServer")

MainBridge.OnServerInvoke = function(Player)
	local _Replicas = {}

	for Id, Replica in pairs(Replicas) do
		if
			(typeof(Replica.To) == "string" and Replica.To:lower() == "all")
			or (typeof(Replica.To) == "table" and table.find(Replica.To, Player))
			or (Replica.To == Player)
		then
			if not _Replicas[Replica.Name] then
				_Replicas[Replica.Name] = {}
			end

			_Replicas[Replica.Name][Id] = {
				Tags = Util.CopyTable(Replica.Tags, true),
				Data = Util.CopyTable(Replica.Data, true),
				WriteLib = Replica.WriteLibModule,
			}
		end
	end

	return _Replicas
end

local ReplicaServer = {}

function ReplicaServer.NewReplica(Config: ReplicaConfig): Types.ServerReplica
	local Id = HttpService:GenerateGUID(false)

	local WriteFunctionFlag: boolean = false

	local Replica = {
		WriteLibModule = Config.WriteLib,
		Tags = Config.Tags or {},
		To = Config.To,
		Name = Config.Name,
		Cleaner = Trove.new(),
		ServerEvents = {},
		Changed = LemonSignal.new(),
		Destroying = LemonSignal.new(),
		Id = Id,
	}

	Replica.WriteLib = Replica.WriteLibModule and LoadWriteLib(Replica.WriteLibModule)

	local function FireBridge(Args)
		if Config.To == "All" then
			MainBridge:Fire(BridgeNet.AllPlayers(), Args)
		elseif typeof(Config.To) == "table" then
			MainBridge:Fire(BridgeNet.Players(Config.To), Args)
		else
			MainBridge:Fire(Config.To, Args)
		end
	end

	function Replica:ConnectOnServerEvent(Callback: (...any) -> ())
		table.insert(self.ServerEvents, Callback)

		return function()
			table.remove(self.ServerEvents, table.find(self.ServerEvents, Callback))
		end
	end

	FireBridge({ "Create", Config.Name, Id, Replica.Tags, Config.Data, Replica.WriteLibModule })

	Replica.Changed:Connect(function(Indices, Value, OldValue)
		FireBridge({ "Changed", Config.Name, Id, Indices, Value, OldValue })
	end)

	Replica.Cleaner:Add(
		MainBridge:Connect(function(Player, Args)
			local Event = Args[1]

			if Event ~= "Request" then
				return
			end

			if Args[2] == Config.Name and Args[3] == Id then
				for _, Callback in Replica.ServerEvents do
					task.spawn(Callback, Player, table.unpack(Args, 4))
				end
			end
		end),
		"Disconnect"
	)

	Replica.Data = Config.Data
	Replica._OldData = Util.CopyTable(Replica.Data, true)

	local function Update(Indicies: { string | number }, Value: any)
		Replica._OldData = Util.CopyTable(Replica.Data, true)
		local Pointer = Replica.Data

		for I = 1, #Indicies - 1 do
			local Index = Indicies[I]
			Pointer = Pointer[Index] ~= nil and Pointer[Index] or Pointer[tonumber(Index)]
			if Pointer == nil then
				return warn(`Invalid Index: {Index}`)
			end
		end

		local LastIndex = Indicies[#Indicies]
		local Operator = if typeof(LastIndex) == "string" then LastIndex:match("[+%%-*/^]$") else nil

		if Operator then
			LastIndex = LastIndex:sub(1, LastIndex:find(Operator) - 1)
			Indicies[#Indicies] = LastIndex

			if type(Value) == "table" and not (Operator:find("+") or Operator:find("-")) then
				return warn("Invalid Operator for Table")
			end

			local CurrentValue = Pointer[LastIndex]

			if CurrentValue then
				if Operator:find("+") then
					if typeof(CurrentValue) == "table" then
						Value = Util.JoinTables(CurrentValue, { Value })

						local Keys = {}

						for Key in Value do
							if not CurrentValue[Key] then
								table.insert(Keys, Key)
							end
						end

						for _, Key in Keys do
							local _Indicies = table.clone(Indicies)
							_Indicies[#_Indicies + 1] = Key
							Replica.Changed:Fire(_Indicies, Value[Key], nil)
							CurrentValue[Key] = Value[Key]
						end

						return
					else
						CurrentValue += Value
					end
				elseif Operator:find("-") then
					if type(CurrentValue) == "table" then
						if type(Value) ~= "table" or type(Value) ~= "userdata" then
							Replica.Changed:Fire(Indicies, nil, CurrentValue)
							table.remove(CurrentValue, table.find(CurrentValue, Value))
						else
							local Keys = {}

							for Key in CurrentValue do
								if Util.Equals(CurrentValue[Key], Value) then
									table.insert(Keys, Key)
								end
							end

							for _, Key in Keys do
								local _Indicies = table.clone(Indicies)
								_Indicies[#_Indicies + 1] = Key
								if typeof(Key) == "number" then
									Replica.Changed:Fire(_Indicies, nil, CurrentValue[Key])
									table.remove(CurrentValue, Key)
								else
									Replica.Changed:Fire(_Indicies, nil, CurrentValue[Key])
									CurrentValue[Key] = nil
								end
							end
						end

						return
					else
						CurrentValue -= Value
					end
				elseif Operator:find("*") then
					CurrentValue *= Value
				elseif Operator:find("/") then
					CurrentValue /= Value
				elseif Operator:find("^") then
					CurrentValue ^= Value
				elseif Operator:find("%") then
					CurrentValue %= Value
				end
				
				Value = CurrentValue
			end
		end

		local IndexType = if tonumber(LastIndex) then "number" else "string"

		LastIndex = IndexType == "string" and LastIndex or tonumber(LastIndex)
		local OldValue = Pointer[LastIndex]

		if typeof(OldValue) == "table" and typeof(Value) == "table" and Util.Equals(OldValue, Value, true) then
			return
		end

		if OldValue ~= Value then
			Pointer[LastIndex] = Value
			Indicies[#Indicies] = LastIndex
			Replica.Changed:Fire(Indicies, Value, OldValue)
		end

		return
	end

	function Replica:FireClient(...)
        FireBridge({ "FireClient", Config.Name, Id, ... })
	end

	function Replica:AddCleanupTask(Task: () -> nil, OptionalCleanupMethod: any?)
		self.Cleaner:Add(Task, OptionalCleanupMethod or true)
	end

	function Replica:Write(WriteFunction: string, ...)
		if self.WriteLib then
			if not Replica.WriteLib[WriteFunction] then
				warn(`Write Function {WriteFunction} was not in WriteLib!`)
				return
			end

			local Func = Replica.WriteLib[WriteFunction]

			if WriteFunctionFlag then
				return Func(Replica, ...)
			end

			WriteFunctionFlag = true

			local ReturnedValues = Func(Replica, ...)

			WriteFunctionFlag = false

			FireBridge({ "Write", Replica.Name, Id, WriteFunction, ... })

			return ReturnedValues
		end
		
		return nil
	end

	function Replica:Set(Indicies: { string | number } | string, Value)
		local _Indicies = Parser(Indicies)

		if #_Indicies == 0 and typeof(Value) == "table" then
			if Util.Equals(self.Data, Value, true) then
				return
			end

			local OldData = Util.CopyTable(self.Data, true)
			for Index, _Value in Value do
				if not OldData[Index] or OldData[Index] ~= _Value then
					self.Data[Index] = _Value
				end
			end
			self.Changed:Fire({}, self.Data, OldData)
		else
			Update(_Indicies, if typeof(Value) == "table" then Util.CopyTable(Value, true) else Value)
		end

		return nil
	end

	function Replica:ListenToChange(Indicies: { string | number } | string, Callback)
		local _Indicies = Parser(Indicies)

		return self.Changed:Connect(function(ChangedIndicies)
			local Match = true
			local _Data = self.Data
			local _OldData = self._OldData

			for I, Index in pairs(_Indicies) do
				_Data = _Data[Index]
				_OldData = _OldData[Index]

				if Index ~= ChangedIndicies[I] then
					Match = false
					break
				end
			end

			if Match then
				task.spawn(Callback, _Data, _OldData)
			end
		end)
	end

	function Replica:ListenToNewKey(Indicies: { string | number } | string, Callback)
		local _Indicies = Parser(Indicies)

		return self.Changed:Connect(function(ChangedIndices, Value, OldValue)
			if not OldValue and ChangedIndices[#ChangedIndices - 1] == _Indicies[#_Indicies] then
				task.spawn(Callback, Value, ChangedIndices[#ChangedIndices])
			end
		end)
	end

	function Replica:ListenToKeyRemoved(Indicies: { string | number } | string, Callback)
		local _Indicies = Parser(Indicies)

		return self.Changed:Connect(function(ChangedIndices, Value, OldValue)
			if not Value and ChangedIndices[#ChangedIndices - 1] == _Indicies[#_Indicies] then
				task.spawn(Callback, OldValue, ChangedIndices[#ChangedIndices])
			end
		end)
	end

	function Replica:Destroy()
		FireBridge({ "Destroy", Config.Name, Id })
		self.Destroying:Fire()
		task.delay(1, self.Destroying.Destroy, self.Destroying)
		self.Changed:Destroy()
		self.Cleaner:Destroy()
		table.clear(self.Changed)
		table.clear(self.Cleaner)
		table.clear(self)
	end

	Replicas[Id] = Replica

	return Replica
end

return ReplicaServer