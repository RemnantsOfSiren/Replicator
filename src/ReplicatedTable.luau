local HttpService = game:GetService("HttpService")

local Logger = require(script.Parent.Logger)
local Sift = require(script.Parent.Parent.Sift)
local Signal = require(script.Parent.Parent.Signal)

local Serializer = require(script.Parent.Serializer)

local Dictionary = Sift.Dictionary
local CopyDeep = Dictionary.copyDeep

export type ReplicatedTable = typeof(setmetatable(
	{} :: {
		__type: "ReplicatedTable",
		__value: { [any]: any },
		__table: { [any]: any },
		__onChange: (Path: { [number]: { Key: string, IsNumber: boolean } }, Value: any, Action: string) -> nil,
		__oldtable: { [any]: any },
		__indicies: { string | number }?,
		get: (self: ReplicatedTable) -> { [any]: any },
		Get: (self: ReplicatedTable) -> { [any]: any },
		insert: (self: ReplicatedTable, ...any) -> nil,
		Insert: (self: ReplicatedTable, ...any) -> nil,
		remove: (self: ReplicatedTable, Index: number) -> nil,
		Remove: (self: ReplicatedTable, Index: number) -> nil,
		destroy: (self: ReplicatedTable) -> nil,
		Destroy: (self: ReplicatedTable) -> nil,
	},
	{}
))

local ValidKeyTypes = { "string", "number" }

local CreateReplicatedTable

local function Get(self: ReplicatedTable)
	return CopyDeep(self.__table)
end

local function Insert(self: ReplicatedTable, ...: any)
	self.__oldtable = self:Get()
	local Args = { ... }
	local InsertIndices = table.clone(self.__indicies or {})
	local Index = if #Args > 1 then Args[1] else #self.__table + 1
	local _Value = if #Args > 1 then Args[2] else Args[1]
	InsertIndices[#InsertIndices + 1] = Index
	table.insert(self.__table, Index, _Value)

	local Path = table.clone(self.__indicies or {})
	Path[#Path + 1] = Index

	if _Value and type(_Value) == "table" then
		local NewReplicatedTable = CreateReplicatedTable(_Value, InsertIndices, self)
		rawset(self.__value, Index, NewReplicatedTable)
	end
	
	self.__onChange(Serializer.ConvertToPacket(Path), _Value, "Insert")
end

local function Remove(self: ReplicatedTable, Index: number)
	self.__oldtable = self:Get()
	local _Indicies = table.clone(self.__indicies or {})
	_Indicies[#_Indicies + 1] = Index
	local _Value = table.remove(self.__table, Index)

	local Path = table.clone(self.__indicies or {})
	Path[#Path + 1] = Index

	if rawget(self.__value, Index) and _Value and type(_Value) == "table" then
		rawset(self.__value, Index, nil)
	end
	
	self.__onChange(Serializer.ConvertToPacket(Path), _Value, "Remove")
end

local function Destroy(self: ReplicatedTable)
	for _, Value in self.__value do
		if Value.__type == "ReplicatedTable" then
			Value:Destroy()
		end
	end

	table.clear(self)
end

CreateReplicatedTable = function(
	Table: { [any]: any },
	Indicies: { string | number }?,
	OnChange: (Path: { [number]: { Key: string, IsNumber: boolean } }, Value: any, Action: string) -> nil
): ReplicatedTable
	local Id = HttpService:GenerateGUID(false):sub(1, 7)

	local ReplicatedTable = setmetatable({
		__type = "ReplicatedTable",
		__table = Table,
		__value = {},
		__oldtable = CopyDeep(Table),
		__indicies = Indicies or {},
		__onChange = OnChange,
	}, {
		__index = function(self, Key)
			return rawget(self.__value, Key) or rawget(Table, Key)
		end,

		__newindex = function(self, Key, Value)
			local validKey = table.find(ValidKeyTypes, typeof(Key))

			if not validKey then
				warn(`Attempt to assign a value to a key that is not a string or number. {type(Key)} was given.`)
				return
			end

			local IsTable = type(Value) == "table"
			self.__oldtable = self:Get()

			if IsTable and Value.__type == "Replicated Table" then
				return
			end
			
			local _Indicies = table.clone(Indicies or {})
			_Indicies[#_Indicies + 1] = Key

			if IsTable then
				local NewReplicatedTable = CreateReplicatedTable(Value, _Indicies, OnChange)
				rawset(self.__value, Key, NewReplicatedTable)
			end
			
			if Sift.Array.is(Table) and Value == nil then
				Logger("Warn", "Use :Remove() to remove an element from an array.")
				return
			else
				local TValue = rawget(Table, Key)
				
				if (IsTable and type(TValue) == "table" and Dictionary.equalsDeep(Value, TValue)) or (not IsTable and TValue == Value) then
					return
				end
				
				rawset(Table, Key, Value)
				OnChange(Serializer.ConvertToPacket(_Indicies), Value, "Set")
			end

			if rawget(self.__value, Key) and Value == nil then
				rawset(self.__value, Key, nil)
			end

			if (Sift.Array.is(Table) or Sift.Dictionary.count(Table) == 0) and not rawget(self, "Insert") then
				rawset(self, "Insert", Insert)
				rawset(self, "insert", Insert)
				rawset(self, "Remove", Remove)
				rawset(self, "remove", Remove)
			elseif not Sift.Array.is(Table) and rawget(self, "Insert") then
				rawset(self, "Insert", nil :: any)
				rawset(self, "insert", nil :: any)
				rawset(self, "Remove", nil :: any)
				rawset(self, "remove", nil :: any)
			end
		end,

		__tostring = function()
			return `[[ReplicatedTable:{Id}]]`
		end,

		__iter = function(self)
			local AlreadyVisited = {}
			local Cleaner = {}

			return function(): (any, any, any)
				for Index, Value in pairs(Table) do
					if not table.find(AlreadyVisited, Index) then
						table.insert(AlreadyVisited, Index)

						local _Indicies = table.clone(Indicies or {})
						_Indicies[#_Indicies + 1] = Index
						Value = if type(Value) == "table" then CreateReplicatedTable(Value, _Indicies, OnChange) else Value

						return Index,
							Value,
							function(NewValue)
								local IsReplicatedTable = type(NewValue) == "table"
									and NewValue.__type
									and NewValue.__type == "Replicated Table"

								if IsReplicatedTable then
									rawset(Table, Index, NewValue:Get())
									rawset(self.__value, Index, NewValue)
									OnChange(Serializer.ConvertToPacket(_Indicies), NewValue:Get(), "Set")
								else
									rawset(Table, Index, NewValue)
									OnChange(Serializer.ConvertToPacket(_Indicies), NewValue, "Set")
								end
							end
					end
				end

				table.clear(Cleaner)
				table.clear(AlreadyVisited)
				return nil, nil, nil
			end
		end,
	})
	
	rawset(ReplicatedTable, "Get", Get)
	rawset(ReplicatedTable, "get", Get)

	for Index, Value in Table do
		if type(Value) == "table" then
			if Value.__type and Value.__type == "Replicated Table" then
				rawset(ReplicatedTable, Index, Value)
			else
				ReplicatedTable[Index] = Value
			end
		end
	end

	if Sift.Array.is(Table) or Sift.Dictionary.count(Table) == 0 then
		rawset(ReplicatedTable, "Insert", Insert)
		rawset(ReplicatedTable, "insert", Insert)
		rawset(ReplicatedTable, "Remove", Remove)
		rawset(ReplicatedTable, "remove", Remove)
	end

	rawset(ReplicatedTable, "Destroy", Destroy)
	rawset(ReplicatedTable, "destroy", Destroy)

	return ReplicatedTable
end

return CreateReplicatedTable