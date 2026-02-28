--!strict
local buffer_writer = require("../buffer_writer")
local math_frexp = math.frexp
local math_clamp = math.clamp
local math_floor = math.floor
local math_pow = math.pow
local bit32_extract = bit32.extract
local bit32_lshift = bit32.lshift

-- localize buffer_writer functions
local fill = buffer_writer.fill
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

return {
	name = "float24",
	write = @native function(value: number): ()
		if value == 0 then
			fill(0, 3)
			return
		end

		local sign = 0
		if value < 0 then
			sign = 1
			value = -value
		end

		local mantissa, exponent = math_frexp(value)
		-- standard IEEE: mantissa is in [0.5, 1).
		-- we shift it to fit 16 bits (multiply by 2^16)
		-- we adjust exponent for the bias (63)
		local e = math_clamp(exponent + 63, 0, 127)
		local m = math_floor((mantissa * 2 - 1) * 65536 + 0.5)

		-- pack: [S EEEEEEE] [MMMMMMMM] [MMMMMMMM]
		writeu8((sign * 128) + e)
		writeu8(bit32_extract(m, 8, 8))
		writeu8(bit32_extract(m, 0, 8))
	end,

	read = @native function(b: buffer, cursor: number): (number, number)
		local b1 = readu8(b, cursor)
		local b2 = readu8(b, cursor + 1)
		local b3 = readu8(b, cursor + 2)

		local sign = bit32_extract(b1, 7, 1) == 1 and -1 or 1
		local exponent = bit32_extract(b1, 0, 7)
		local m_raw = bit32_lshift(b2, 8) + b3

		if exponent == 0 and m_raw == 0 then
			return 0, cursor + 3
		end

		-- reconstruct: (1 + m/2^16) * 2^(e - bias - 1)
		local mantissa = (m_raw / 65536) + 1
		local value = sign * mantissa * math_pow(2, exponent - 63 - 1)

		return value, cursor + 3
	end,
}
