--!strict
local HttpService = game:GetService("HttpService")
local RunService = game:GetService("RunService")

local Logger = require(script.Parent.Logger)
local Parser = require(script.Parent.Parser)
local Signal = require(script.Parent.Parent.Signal) :: any
local Trove = require(script.Parent.Parent.Trove) :: any
local Types = require(script.Parent.Types)

local Replica = {}
Replica.__index = Replica

export type Replica = typeof(setmetatable({} :: Types.Replica, Replica)) & {}

local function IsReplicatedTable(Value: any): boolean
	return type(Value) == "table" and Value.__type == "ReplicatedTable"
end

local function IsLooseEqual(ChangedPath, Path)
	for I = 1, #Path do
		if ChangedPath[I] ~= Path[I] then
			return false
		end
	end

	return true
end

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
		if not IsLooseEqual(ChangedPath, ParsedPath) then
			return
		end

		for Index = 1, #ParsedPath do
			local Key = ParsedPath[Index]
			if Key then
				NewValue = NewValue[Key]
				OldValue = OldValue[Key]
			end
		end

		if NewValue then
			return
		end

		local Key = ParsedPath[#ParsedPath]
		task.spawn(Callback, Key, OldValue)
	end)
end

function Replica:ListenToNewKey(Path: Types.ValidPath, Callback: (...any) -> nil)
	local ParsedPath = Parser(Path)

	return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
		if not IsLooseEqual(ChangedPath, ParsedPath) then
			return
		end

		for Index = 1, #ParsedPath do
			local Key = ParsedPath[Index]
			if Key then
				NewValue = NewValue[Key]
				OldValue = OldValue[Key]
			end
		end

		if OldValue then
			return
		end

		local Index = ChangedPath[#ParsedPath]
		task.spawn(Callback, Index, NewValue)
	end)
end

function Replica:ListenToChange(Path: Types.ValidPath, Callback: (...any) -> nil, SuppressOld: boolean?)
	local ParsedPath = Parser(Path)

	return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
		if not IsLooseEqual(ChangedPath, ParsedPath) then
			return
		end

		local Previous = if not SuppressOld then OldValue else nil

		for Index = 1, #ParsedPath do
			local Key = ParsedPath[Index]
			if Key then
				NewValue = NewValue[Key]

				if Previous and Previous[Key] then
					Previous = Previous[Key]
				end
			end
		end

		task.spawn(Callback, NewValue, if SuppressOld then nil else Previous)
	end)
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

	local _Data = if IsReplicatedTable(self.Data) then self.Data:Get() else self.Data

	for Index = 1, #ParsedPath do
		local Key = ParsedPath[Index]
		if Key then
			_Data = _Data[Key]
		end
	end

	task.spawn(Callback, _Data, _Data)

	return self:ListenToChange(Path, Callback, false)
end

function Replica:AddCleanupMethod(Cleanup: any, CleanupMethod: (string | boolean)?)
	return self.__Cleaner:Add(Cleanup, CleanupMethod)
end

function Replica.new(Config: Types.Config): Replica
	if Config.WriteLib and not Config.WriteLib:IsA("ModuleScript") then
		return Logger("Warn", "WriteLib must be a ModuleScript.")
	end

	local Cleaner = Trove.new()

	local self = setmetatable({
		Id = if RunService:IsServer() then `{Config.Name}:{HttpService:GenerateGUID(false):sub(1, 7)}` else Config.Id,
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
		if self.__Cleaner then
			self.__Cleaner:Destroy()
		end
	end)

	return self
end

return Replica
