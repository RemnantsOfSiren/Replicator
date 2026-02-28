--!strict
local buffer_writer = require("../buffer_writer")
local vec3i16_new = Vector3int16.new

-- localize buffer_writer functions
local writei16 = buffer_writer.writei16
-- localize buffer read functions
local readi16 = buffer.readi16

return {
	name = "vector3_int16",
	write = @native function(value: Vector3int16): ()
		writei16(value.X)
		writei16(value.Y)
		writei16(value.Z)
	end,
	read = @native function(b: buffer, cursor: number): (Vector3int16, number)
		return vec3i16_new(
			readi16(b, cursor),
			readi16(b, cursor + 2),
			readi16(b, cursor + 4)
		), cursor + 6
	end,
}
