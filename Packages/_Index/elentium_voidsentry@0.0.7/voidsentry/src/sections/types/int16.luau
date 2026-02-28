local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")
local math_floor = math.floor

-- localize buffer_writer functions
local writei16 = buffer_writer.writei16
-- localize buffer read functions
local readi16 = buffer.readi16

local INT16_MIN = -32768
local INT16_MAX = 32767

return {
	name = "int16",
	write = @native function(value: number): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if math_floor(value) ~= value or value < INT16_MIN or value > INT16_MAX then
				error(`int16.write: Value {value} is out of range ({INT16_MIN}..{INT16_MAX}).`)
			end
		end
		writei16(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readi16(b, cursor), cursor + 2
	end,
}
