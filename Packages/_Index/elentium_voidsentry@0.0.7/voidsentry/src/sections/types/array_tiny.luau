local buffer_writer = require("../buffer_writer")
local type_node_export = require("../exports/type_node")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

type TypeNode = type_node_export.typeNode

return function(ValueType: TypeNode)
	return {
		name = "array_tiny",
		write = @native function(value: { any }): ()
			local len = #value
			if Config.VALIDATION_LEVEL >= 2 then
				if len > 255 then
					error(`array_tiny.write: Array length ({len}) exceeds max length (255).`)
				end
			end
			writeu8(len)
			for i = 1, len do
				ValueType.write(value[i])
			end
		end,

		read = @native function(b: buffer, cursor: number): ({ any }, number)
			local len = readu8(b, cursor)
			cursor += 1
			local value = table.create(len)
			for i = 1, len do
				value[i], cursor = ValueType.read(b, cursor)
			end
			return value, cursor
		end,
	}
end
