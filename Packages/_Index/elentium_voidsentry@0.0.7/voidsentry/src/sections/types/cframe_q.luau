--!strict
local buffer_writer = require("../buffer_writer")
local sqrt = math.sqrt
local cframe_new = CFrame.new

-- localize buffer_writer functions
local writef32 = buffer_writer.writef32
-- localize buffer read functions
local readf32 = buffer.readf32

--[[
    Quaternion cframe serialization, less precise but faster, recommended for most cases.
]]
@native
local function toQuaternion(cf: CFrame)
	local _, _, _, m00, m01, m02, m10, m11, m12, m20, m21, m22 = cf:GetComponents()

	local trace = m00 + m11 + m22
	local qx, qy, qz, qw

	if trace > 0 then
		local s = sqrt(trace + 1) * 2
		qw = 0.25 * s
		qx = (m21 - m12) / s
		qy = (m02 - m20) / s
		qz = (m10 - m01) / s
	elseif (m00 > m11) and (m00 > m22) then
		local s = sqrt(1 + m00 - m11 - m22) * 2
		qw = (m21 - m12) / s
		qx = 0.25 * s
		qy = (m01 + m10) / s
		qz = (m02 + m20) / s
	elseif m11 > m22 then
		local s = sqrt(1 + m11 - m00 - m22) * 2
		qw = (m02 - m20) / s
		qx = (m01 + m10) / s
		qy = 0.25 * s
		qz = (m12 + m21) / s
	else
		local s = sqrt(1 + m22 - m00 - m11) * 2
		qw = (m10 - m01) / s
		qx = (m02 + m20) / s
		qy = (m12 + m21) / s
		qz = 0.25 * s
	end

	return qx, qy, qz, qw
end

return {
	name = "cframe_q",
	write = @native function(value: CFrame): ()
		local pos = value.Position
		local qx, qy, qz, qw = toQuaternion(value)

		-- write position
		writef32(pos.X)
		writef32(pos.Y)
		writef32(pos.Z)

		-- write quaternion
		writef32(qx)
		writef32(qy)
		writef32(qz)
		writef32(qw)
	end,
	read = @native function(b: buffer, cursor: number): (CFrame, number)
		return cframe_new(
			readf32(b, cursor), -- x
			readf32(b, cursor + 4), -- y
			readf32(b, cursor + 8), -- z
			readf32(b, cursor + 12), -- qx
			readf32(b, cursor + 16), -- qy
			readf32(b, cursor + 20), -- qz
			readf32(b, cursor + 24) -- qw
		), cursor + 28
	end,
}
