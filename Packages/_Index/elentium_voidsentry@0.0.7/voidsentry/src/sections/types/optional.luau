--!strict
local buffer_writer = require("../buffer_writer")
local type_node_export = require("../exports/type_node")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

type TypeNode = type_node_export.typeNode

return function(Type: TypeNode)
	return {
		name = "optional",
		write = @native function(value: any?): ()
			writeu8(value == nil and 1 or 0)
			if value ~= nil then
				Type.write(value)
			end
		end,
		read = @native function(b: buffer, cursor: number): (any?, number)
			local exists = readu8(b, cursor)
			if exists == 1 then
				return nil, cursor + 1
			end
			return Type.read(b, cursor + 1)
		end,
	}
end
