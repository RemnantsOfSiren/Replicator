local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")
local math_floor = math.floor

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

local UINT8_MIN = 0
local UINT8_MAX = 255

return {
	name = "uint8",
	write = @native function(value: number): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if math_floor(value) ~= value or value < UINT8_MIN or value > UINT8_MAX then
				error(`uint8.write: Value {value} is out of range ({UINT8_MIN}..{UINT8_MAX}).`)
			end
		end
		writeu8(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readu8(b, cursor), cursor + 1
	end,
}
