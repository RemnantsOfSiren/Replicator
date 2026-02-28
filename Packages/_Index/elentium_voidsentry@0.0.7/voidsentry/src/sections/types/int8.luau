local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")
local math_floor = math.floor

-- localize buffer_writer functions
local writei8 = buffer_writer.writei8
-- localize buffer read functions
local readi8 = buffer.readi8

local INT8_MIN = -128
local INT8_MAX = 127

return {
	name = "int8",
	write = @native function(value: number): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if math_floor(value) ~= value or value < INT8_MIN or value > INT8_MAX then
				error(`int8.write: Value {value} is out of range ({INT8_MIN}..{INT8_MAX}).`)
			end
		end
		writei8(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readi8(b, cursor), cursor + 1
	end,
}
