--!strict
local buffer_writer = require("../buffer_writer")
local vec_new = vector.create

-- localize buffer_writer functions
local writei16 = buffer_writer.writei16
-- localize buffer read functions
local readi16 = buffer.readi16

return {
	name = "vector_int16",
	write = @native function(value: vector): ()
		writei16(value.x)
		writei16(value.y)
		writei16(value.z)
	end,
	read = @native function(b: buffer, cursor: number): (vector, number)
		return vec_new(
			readi16(b, cursor),
			readi16(b, cursor + 2),
			readi16(b, cursor + 4)
		), cursor + 6
	end,
}
