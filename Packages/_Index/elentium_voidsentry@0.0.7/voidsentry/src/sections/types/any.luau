local buffer_writer = require("../buffer_writer")
local GetElementType = require("../shared/GetElementType")
local TypeSigns = require("../shared/TypeSigns")
local export_type_node = require("../exports/type_node")
local GetElementNode = require("../shared/GetElementNode")
local BuildTypeNode = require("../shared/BuildTypeNode")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
local writeu16 = buffer_writer.writeu16
local writestring = buffer_writer.writestring

type TypeNode = export_type_node.typeNode

local mapModule = require("./map")
local arrayModule = require("./array")
local array_tinyModule = require("./array_tiny")
local enumModule = require("./enum")
local instanceModule = require("./instance")

local anyType
anyType = {
	name = "any",
	write = @native function(value: any): ()
		local t = GetElementType(value)

		-- for arrays and maps, use Any type for elements to support mixed types
		local mod: TypeNode
		if t == "ARRAY" then
			mod = arrayModule(anyType)
		elseif t == "ARRAY_TINY" then
			mod = array_tinyModule(anyType)
		elseif t == "MAP" then
			mod = mapModule(anyType, anyType)
		elseif t == "ENUM" then
			mod = enumModule(value.EnumType)
		elseif t == "INSTANCE" then
			mod = instanceModule(value.ClassName)
		else
			mod = GetElementNode(require(`./{t:lower()}`), value)
		end

		-- write the nested type sign first
		local typeName = mod.name
		local baseType = typeName:upper()
		local sign = TypeSigns[baseType] :: number
		writeu8(sign)

		-- for Enum types, write the Enum type name so BuildTypeNode can reconstruct it
		if t == "ENUM" then
			local enumTypeName = tostring(value.EnumType)
			writeu16(#enumTypeName)
			writestring(enumTypeName)
		-- for Instance types, write the class name so BuildTypeNode can reconstruct it
		elseif t == "INSTANCE" then
			local className = value.ClassName
			writeu8(#className)
			writestring(className)
		end

		-- for arrays and maps in dynamic serialization, we don't write nested type signs
		-- since they always have 'any' types. BuildTypeNode will assume 'any' when reading.

		-- write the actual value
		mod.write(value)
	end,
	read = @native function(b: buffer, cursor: number): (any, number)
		-- build the type node recursively
		local mod: TypeNode
		mod, cursor = BuildTypeNode(b, cursor) -- BuildTypeNode reads the type sign and advances cursor
		-- read the value
		local value: any
		value, cursor = mod.read(b, cursor)
		return value, cursor
	end,
}

return anyType
