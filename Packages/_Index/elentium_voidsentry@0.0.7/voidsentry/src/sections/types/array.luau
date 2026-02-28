local buffer_writer = require("../buffer_writer")
local type_node_export = require("../exports/type_node")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu16 = buffer_writer.writeu16
-- localize buffer read functions
local readu16 = buffer.readu16

type TypeNode = type_node_export.typeNode

return function(ValueType: TypeNode)
	return {
		name = "array",
		write = @native function(value: { any }): ()
			local len = #value
			if Config.VALIDATION_LEVEL >= 2 then
				if len > 65535 then
					error(`array.write: Array length ({len}) exceeds max length (65535).`)
				end
			end
			writeu16(len)
			for i = 1, len do
				ValueType.write(value[i])
			end
		end,

		read = @native function(b: buffer, cursor: number): ({ any }, number)
			local len = readu16(b, cursor)
			cursor += 2
			local value = table.create(len)
			for i = 1, len do
				value[i], cursor = ValueType.read(b, cursor)
			end
			return value, cursor
		end,
	}
end
