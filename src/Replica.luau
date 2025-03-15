--!strict
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local Types = require(script.Parent.Types)
local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any
local Logger = require(script.Parent.Logger)
local Parser = require(script.Parent.Parser)

local Replica = {}
Replica.__index = Replica

export type Replica = typeof(setmetatable({} :: Types.Replica, Replica))

function Replica:Write(Method: string, Callback: (...any) -> nil)
	return self.__Write:Connect(function(_Method: string, Args: { any })
		if _Method == Method then
			task.spawn(Callback, unpack(Args))
		end
	end)
end

function Replica:ListenToKeyRemoved(Path: Types.ValidPath, Callback: (...any) -> nil)
	local ParsedPath = Parser(Path)

	return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
		if NewValue then
			return
		end

		local Match = true

		for Index = 1, #ParsedPath do
			local Key = ParsedPath[Index]
			if Key then
				OldValue = OldValue[Key]

				if Key ~= ChangedPath[Index] then
					Match = false
					break
				end
			end
		end

		if Match then
			local Key = ChangedPath[#ChangedPath]
			task.spawn(Callback, Key, OldValue[Key])
		end
	end)
end

function Replica:ListenToNewKey(Path: Types.ValidPath, Callback: (...any) -> nil)
	local ParsedPath = Parser(Path)

	return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
		for Index = 1, #ChangedPath do
			local Key = ChangedPath[Index]
			if Key then
				OldValue = OldValue[Key]
			end
		end

		if OldValue then
			return
		end

		local IsMatch = true

		if #ParsedPath ~= 0 then
			for Index, Key in pairs(ParsedPath) do
				local ChangedKey = ChangedPath[Index]
				if ChangedKey then
					if Key ~= ChangedKey then
						IsMatch = false
						break
					end
				end
			end
		end

		if IsMatch then
			task.spawn(Callback, ChangedPath[#ChangedPath], NewValue)
		end
	end)
end

function Replica:ListenToChange(Path: Types.ValidPath, Callback: (...any) -> nil, SuppressOld: boolean?)
	local ParsedPath = Parser(Path)

	local Connection

	Connection = self.__Change:Connect(function(ChangedPath: { string | number }, _, OldValue)
		local Match = true
		local Data = self.Data
		local Previous = if not SuppressOld then OldValue else nil

		for Index = 1, #ParsedPath do
			local Key = ParsedPath[Index]
			if Key then
				Data = Data[Key]

				if Previous and Previous[Key] then
					Previous = Previous[Key]
				end

				if Key ~= ChangedPath[Index] then
					Match = false
					break
				end
			end
		end

		if Match then
			task.spawn(Callback, Data, if SuppressOld then nil else Previous)
			if Data == nil then
				Connection:Disconnect()
			end
		end
	end)

	return Connection
end

function Replica:ListenToRaw(Callback: (...any) -> nil)
	return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
		if OldValue then
			for Index = 1, #ChangedPath do
				OldValue = OldValue[ChangedPath[Index]]
			end
		end

		task.spawn(Callback, ChangedPath, NewValue, OldValue)
	end)
end

function Replica:ObserveChange(Path: Types.ValidPath, Callback: (...any) -> nil)
	local ParsedPath = Parser(Path)

	local _Data = self.Data

	for Index = 1, #ParsedPath do
		local Key = ParsedPath[Index]
		if Key then
			_Data = _Data[Key]
		end
	end

	task.spawn(Callback, _Data, nil)
	return self:ListenToChange(Path, Callback, false)
end

function Replica:AddCleanupTask(Task: () -> nil, CleanupMethod: string | boolean?)
	return self.__Cleaner:Add(Task, if not CleanupMethod then true else CleanupMethod)
end

function Replica.new(Config: Types.Config): Replica
	if Config.WriteLib and not Config.WriteLib:IsA("ModuleScript") then
		return Logger("Warn", "WriteLib must be a ModuleScript.")
	end

	local Cleaner = Trove.new()

	local self = setmetatable({
		Id = if RunService:IsServer() then `{Config.Name}:{HttpService:GenerateGUID(false)}` else Config.Id,
		To = if RunService:IsServer() then Config.To else nil,
		Name = Config.Name,
		Tags = Config.Tags,
		Data = Config.Data,
		__IsParent = Config.IsParent,

		__Write = Cleaner:Construct(Signal),
		__Fired = Cleaner:Construct(Signal),
		__Change = Cleaner:Construct(Signal),
		Destroying = Cleaner:Construct(Signal),

		__Cleaner = Cleaner,
		__WriteLib = Config.WriteLib and require(Config.WriteLib) :: { [any]: any } or nil,
	}, Replica)

	self.__Cleaner:Connect(self.Destroying, function()
		self.__Cleaner:Destroy()
	end)

	return self
end

return Replica
