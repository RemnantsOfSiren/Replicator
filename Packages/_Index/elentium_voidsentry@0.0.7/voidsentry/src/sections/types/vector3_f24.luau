--!strict
local f24 = require("./float24")
local vec3_new = Vector3.new

return {
	name = "vector3_f24",
	write = @native function(value: Vector3): ()
		f24.write(value.X)
		f24.write(value.Y)
		f24.write(value.Z)
	end,
	read = @native function(b: buffer, cursor: number): (Vector3, number)
		local x, y, z
		x, cursor = f24.read(b, cursor)
		y, cursor = f24.read(b, cursor)
		z, cursor = f24.read(b, cursor)
		return vec3_new(x, y, z), cursor
	end,
}
