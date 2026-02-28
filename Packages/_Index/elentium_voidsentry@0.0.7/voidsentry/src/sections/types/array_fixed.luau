--!strict
local type_node_export = require("../exports/type_node")
local Config = require("../shared/Config")

type TypeNode = type_node_export.typeNode

return function(ValueType: TypeNode, len: number)
	return {
		name = "array_fixed",
		write = @native function(value: { any }): ()
			if Config.VALIDATION_LEVEL >= 2 then
				if len ~= #value then
					error(`array_fixed.write: Array length ({#value}) does not match expected length ({len}).`)
				end
			end
			for i = 1, len do
				ValueType.write(value[i])
			end
		end,

		read = @native function(b: buffer, cursor: number): ({ any }, number)
			local value = table.create(len)
			for i = 1, len do
				value[i], cursor = ValueType.read(b, cursor)
			end
			return value, cursor
		end,
	}
end
