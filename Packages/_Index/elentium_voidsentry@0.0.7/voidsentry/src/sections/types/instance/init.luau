--!strict
local Config = require("../shared/Config")
local serialize_data = require("@self/serialize_data")

return function(ClassName: string)
	local structTypeNode = serialize_data[ClassName]
	if not structTypeNode then
		error(`No serialize data found for class: {ClassName}`)
	end

	if structTypeNode.name ~= "struct" then
		error(`Serialize data for class {ClassName} is not a struct`)
	end

	return {
		name = "instance",
		className = ClassName,
		write = @native function(value: Instance): ()
			if Config.VALIDATION_LEVEL >= 2 then
				if value.ClassName ~= ClassName then
					error(`Instance.write: Expected {ClassName}, got {value.ClassName}`)
				end
			end

			-- convert Instance properties to a table for struct serialization
			local props = {}
			for propName in (structTypeNode :: any)._schema do
				props[propName] = (value :: any)[propName]
			end

			-- use struct's write function
			structTypeNode.write(props)
		end,
		read = @native function(b: buffer, cursor: number): (Instance, number)
			-- read the struct data into a table
			local props: { [string]: any }
			props, cursor = structTypeNode.read(b, cursor)

			-- create the Instance and apply properties
			local instance = Instance.new(ClassName)
			for propName, propValue in props do
				(instance :: any)[propName] = propValue
			end

			return instance, cursor
		end,
	}
end
