local export_type_node = require("../exports/type_node")
local TypeSigns = require("./TypeSigns")
local Config = require("./Config")

type TypeNode = export_type_node.typeNode

local array = require("../types/array")
local array_tiny = require("../types/array_tiny")
local map = require("../types/map")
local read_u8 = buffer.readu8
local read_u16 = buffer.readu16
local read_string = buffer.readstring
local blen = buffer.len

-- use the reverse mapping from TypeSigns
local TypeSignsReverse = TypeSigns.Reverse

-- this function builds a type node from serialized type information
-- it reads type signs from the buffer to reconstruct nested type structures
-- used during deserialization when we dont have the actual value
return function(b: buffer, cursor: number): (TypeNode, number)
	-- validation: buffer bounds check
	if Config.VALIDATION_LEVEL >= 1 then
		if cursor < 0 or cursor >= blen(b) then
			error(`BuildTypeNode: Buffer out of bounds. Cursor: {cursor}, Buffer length: {blen(b)}`)
		end
	end

	local sign = read_u8(b, cursor)
	cursor += 1

	local typeName = TypeSignsReverse[sign]
	if not typeName then
		error(`BuildTypeNode: Invalid type sign {sign} at cursor {cursor - 1}. Buffer length: {buffer.len(b)}`)
	end
	local typeModule = require(`../types/{typeName:lower()}`)

	-- if it's an enum type, read the Enum type name and reconstruct the Enum type
	if typeName == "ENUM" then
		-- read the Enum type name length and name
		local nameLen = read_u16(b, cursor)
		cursor += 2
		local enumTypeName = read_string(b, cursor, nameLen)
		cursor += nameLen

		-- get the Enum type from Enum[enumTypeName]
		local enumType = Enum[enumTypeName]
		if not enumType then
			error(`BuildTypeNode: Invalid Enum type name: {enumTypeName}`)
		end

		return typeModule(enumType), cursor
	-- if it's an instance type, read the class name and reconstruct the Instance type
	elseif typeName == "INSTANCE" then
		-- read the class name length and name
		local nameLen = read_u8(b, cursor)
		cursor += 1
		local className = read_string(b, cursor, nameLen)
		cursor += nameLen

		return typeModule(className), cursor
	-- if it's a function type (array, map, array_tiny), use 'any' for nested types in dynamic serialization
	elseif typeof(typeModule) == "function" then
		if typeModule == array or typeModule == array_tiny then
			-- in dynamic serialization, arrays always have 'any' element type
			-- no need to read nested type sign since it's always 'any'
			local anyType = require("../types/any" :: string)
			return typeModule(anyType), cursor
		elseif typeModule == map then
			-- in dynamic serialization, maps always have 'any' key and value types
			-- no need to read nested type signs since they're always 'any'
			local anyType = require("../types/any" :: string)
			return typeModule(anyType, anyType), cursor
		end
	end

	-- simple type, just return the module
	return typeModule, cursor
end
