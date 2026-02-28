--!strict
local buffer_writer = require("../buffer_writer")
local vec3_new = Vector3.new

-- localize buffer_writer functions
local writef32 = buffer_writer.writef32
-- localize buffer read functions
local readf32 = buffer.readf32

return {
	name = "vector3",
	write = @native function(value: Vector3): ()
		writef32(value.X)
		writef32(value.Y)
		writef32(value.Z)
	end,
	read = @native function(b: buffer, cursor: number): (Vector3, number)
		return vec3_new(
			readf32(b, cursor),
			readf32(b, cursor + 4),
			readf32(b, cursor + 8)
		), cursor + 12
	end,
}
