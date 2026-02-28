--!strict
local f24 = require("./float24")
local vec2_new = Vector2.new

return {
	name = "vector2_f24",
	write = @native function(value: Vector2): ()
		f24.write(value.X)
		f24.write(value.Y)
	end,
	read = @native function(b: buffer, cursor: number): (Vector2, number)
		local x, y
		x, cursor = f24.read(b, cursor)
		y, cursor = f24.read(b, cursor)
		return vec2_new(x, y), cursor
	end,
}
