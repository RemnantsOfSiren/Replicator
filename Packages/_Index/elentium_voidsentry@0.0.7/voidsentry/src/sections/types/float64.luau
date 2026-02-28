--!strict
local buffer_writer = require("../buffer_writer")

-- localize buffer_writer functions
local writef64 = buffer_writer.writef64
-- localize buffer read functions
local readf64 = buffer.readf64

return {
	name = "float64",
	write = @native function(value: number): ()
		writef64(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readf64(b, cursor), cursor + 8
	end,
}
