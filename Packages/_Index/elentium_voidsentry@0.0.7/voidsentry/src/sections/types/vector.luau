--!strict
local buffer_writer = require("../buffer_writer")
local vec_new = vector.create

-- localize buffer_writer functions
local writef32 = buffer_writer.writef32
-- localize buffer read functions
local readf32 = buffer.readf32

return {
	name = "vector",
	write = @native function(value: vector): ()
		writef32(value.x)
		writef32(value.y)
		writef32(value.z)
	end,
	read = @native function(b: buffer, cursor: number): (vector, number)
		return vec_new(
			readf32(b, cursor),
			readf32(b, cursor + 4),
			readf32(b, cursor + 8)
		), cursor + 12
	end,
}
