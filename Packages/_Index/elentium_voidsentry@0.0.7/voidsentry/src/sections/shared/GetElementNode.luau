local export_type_node = require("../exports/type_node")

type TypeNode = export_type_node.typeNode

-- when other updates will get added with more function types that are recognized by dynamic checker, new types should be added there
local array = require("../types/array")
local array_tiny = require("../types/array_tiny")
local map = require("../types/map")
local enum = require("../types/enum")
local instance = require("../types/instance")

-- the purpose of this function is to handle nodes like Array, Map that need a function call to return a node
-- instead of writing it in every single place we just have this one function
-- this is used during serialization when we have the actual value to infer types from
return function(variant: any, value: any): TypeNode
	if typeof(variant) == "function" then
		if variant == array or variant == array_tiny then
			-- for dynamic serialization, always use 'any' type for elements to support mixed types
			local anyType = require("../types/any" :: string)
			return variant(anyType)
		elseif variant == map then
			-- for dynamic serialization, always use 'any' type for keys and values to support mixed types
			local anyType = require("../types/any" :: string)
			return variant(anyType, anyType)
		elseif variant == enum then
			-- for Enum, get the Enum type from the EnumItem value
			if typeof(value) == "EnumItem" then
				return variant(value.EnumType)
			else
				error(`GetElementNode: Expected EnumItem for enum type, got {typeof(value)}`)
			end
		elseif variant == instance then
			-- for Instance, get the class name from the Instance value
			if typeof(value) == "Instance" then
				return variant(value.ClassName)
			else
				error(`GetElementNode: Expected Instance for instance type, got {typeof(value)}`)
			end
		end
	end

	return variant
end
