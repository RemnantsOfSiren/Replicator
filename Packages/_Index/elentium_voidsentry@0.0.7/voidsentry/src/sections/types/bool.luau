local buffer_writer = require("../buffer_writer")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

return {
	name = "bool",
	write = @native function(value: boolean): ()
		writeu8(value and 1 or 0)
	end,
	read = @native function(b: buffer, cursor: number): (boolean, number)
		return readu8(b, cursor) == 1, cursor + 1
	end,
}
