--!strict
local f24 = require("./float24")
local vec_new = vector.create

return {
	name = "vector_f24",
	write = @native function(value: vector): ()
		f24.write(value.x)
		f24.write(value.y)
		f24.write(value.z)
	end,
	read = @native function(b: buffer, cursor: number): (vector, number)
		local x, y, z
		x, cursor = f24.read(b, cursor)
		y, cursor = f24.read(b, cursor)
		z, cursor = f24.read(b, cursor)
		return vec_new(x, y, z), cursor
	end,
}
