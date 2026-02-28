local buffer_writer = require("../buffer_writer")
local type_node_export = require("../exports/type_node")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu16 = buffer_writer.writeu16
-- localize buffer read functions
local readu16 = buffer.readu16

type TypeNode = type_node_export.typeNode

return function(KeyType: TypeNode, ValueType: TypeNode)
	return {
		name = "map",
		write = @native function(value: { any }): ()
			local len = 0
			for _ in value do
				len += 1
			end
			if Config.VALIDATION_LEVEL >= 2 then
				if len > 65535 then
					error(`map.write: Map length ({len}) exceeds max length (65535).`)
				end
			end
			writeu16(len)
			for k, v in value do
				KeyType.write(k)
				ValueType.write(v)
			end
		end,

		read = @native function(b: buffer, cursor: number): ({ [any]: any }, number)
			local len = readu16(b, cursor)
			cursor += 2
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
