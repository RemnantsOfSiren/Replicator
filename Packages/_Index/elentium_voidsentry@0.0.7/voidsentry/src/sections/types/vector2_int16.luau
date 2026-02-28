--!strict
local buffer_writer = require("../buffer_writer")
local vec2i16_new = Vector2int16.new

-- localize buffer_writer functions
local writei16 = buffer_writer.writei16
-- localize buffer read functions
local readi16 = buffer.readi16

return {
	name = "vector2_int16",
	write = @native function(value: Vector2int16): ()
		writei16(value.X)
		writei16(value.Y)
	end,
	read = @native function(b: buffer, cursor: number): (Vector2int16, number)
		return vec2i16_new(
			readi16(b, cursor),
			readi16(b, cursor + 2)
		), cursor + 4
	end,
}
