--!strict
local buffer_writer = require("../buffer_writer")
local vec2_new = Vector2.new

-- localize buffer_writer functions
local writef32 = buffer_writer.writef32
-- localize buffer read functions
local readf32 = buffer.readf32

return {
	name = "vector2",
	write = @native function(value: Vector2): ()
		writef32(value.X)
		writef32(value.Y)
	end,
	read = @native function(b: buffer, cursor: number): (Vector2, number)
		return vec2_new(
			readf32(b, cursor),
			readf32(b, cursor + 4)
		), cursor + 8
	end,
}
