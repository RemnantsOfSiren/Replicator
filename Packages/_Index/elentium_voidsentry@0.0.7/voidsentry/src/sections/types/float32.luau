local buffer_writer = require("../buffer_writer")

-- localize buffer_writer functions
local writef32 = buffer_writer.writef32
-- localize buffer read functions
local readf32 = buffer.readf32

return {
	name = "float32",
	write = @native function(value: number): ()
		writef32(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readf32(b, cursor), cursor + 4
	end,
}
