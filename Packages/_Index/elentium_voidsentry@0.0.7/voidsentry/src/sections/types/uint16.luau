local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")
local math_floor = math.floor

-- localize buffer_writer functions
local writeu16 = buffer_writer.writeu16
-- localize buffer read functions
local readu16 = buffer.readu16

local UINT16_MIN = 0
local UINT16_MAX = 65535

return {
	name = "uint16",
	write = @native function(value: number): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if math_floor(value) ~= value or value < UINT16_MIN or value > UINT16_MAX then
				error(`uint16.write: Value {value} is out of range ({UINT16_MIN}..{UINT16_MAX}).`)
			end
		end
		writeu16(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readu16(b, cursor), cursor + 2
	end,
}
