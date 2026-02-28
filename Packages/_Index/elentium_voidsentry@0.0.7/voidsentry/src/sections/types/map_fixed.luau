--!strict
local type_node_export = require("../exports/type_node")
local Config = require("../shared/Config")

type TypeNode = type_node_export.typeNode

return function(KeyType: TypeNode, ValueType: TypeNode, len: number)
	return {
		name = "map_fixed",
		write = @native function(value: { any }): ()
			if Config.VALIDATION_LEVEL >= 2 then
				local count = 0
				for _ in value do
					count += 1
				end
				if len ~= count then
					error(`map_fixed.write: Map length ({count}) does not match expected length ({len}).`)
				end
			end
			for k, v in value do
				KeyType.write(k)
				ValueType.write(v)
			end
		end,

		read = @native function(b: buffer, cursor: number): ({ [any]: any }, number)
			local value = {}
			for _ = 1, len do
				local k
				k, cursor = KeyType.read(b, cursor)
				value[k], cursor = ValueType.read(b, cursor)
			end
			return value, cursor
		end,
	}
end
