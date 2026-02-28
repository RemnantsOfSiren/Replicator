--!strict
local buffer_writer = require("../buffer_writer")
local color3_new = Color3.fromRGB

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

return {
	name = "color3",
	write = @native function(value: Color3): ()
		writeu8(bit32.band(value.R * 255, 0xFF))
		writeu8(bit32.band(value.G * 255, 0xFF))
		writeu8(bit32.band(value.B * 255, 0xFF))
	end,
	read = @native function(b: buffer, cursor: number): (Color3, number)
		return color3_new(
			readu8(b, cursor),
			readu8(b, cursor + 1),
			readu8(b, cursor + 2)
		), cursor + 3
	end,
}
