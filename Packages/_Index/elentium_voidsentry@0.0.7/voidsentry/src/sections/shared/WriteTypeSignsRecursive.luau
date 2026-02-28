local buffer_writer = require("../buffer_writer")
local TypeSigns = require("./TypeSigns")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
local writeu16 = buffer_writer.writeu16
local writestring = buffer_writer.writestring

-- helper function to write type signs recursively for nested types
return function(typeNode: any, value: any): ()
	local typeName = typeNode.name
	local baseType = typeName:upper()

	-- write the type sign
	local sign = TypeSigns[baseType] :: number
	writeu8(sign)

	-- if this is an enum type, write the Enum type name
	if typeName == "enum" then
		-- store the Enum type name so we can reconstruct it during deserialization
		local enumTypeName = tostring(value.EnumType) -- since Enum does not have a name property, we just use tostring which actually gives the name
		writeu16(#enumTypeName)
		writestring(enumTypeName)
	-- if this is an instance type, write the class name
	elseif typeName == "instance" then
		-- store the class name so we can reconstruct it during deserialization
		local className = typeNode.className
		writeu8(#className)
		writestring(className)
	end
	-- for arrays and maps in dynamic serialization, we don't write nested type signs
	-- since they always have 'any' types. BuildTypeNode will assume 'any' when reading.
end
