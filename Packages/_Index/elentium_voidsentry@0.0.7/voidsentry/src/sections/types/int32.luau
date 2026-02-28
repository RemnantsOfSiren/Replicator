local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")
local math_floor = math.floor

-- localize buffer_writer functions
local writei32 = buffer_writer.writei32
-- localize buffer read functions
local readi32 = buffer.readi32

local INT32_MIN = -2147483648
local INT32_MAX = 2147483647

return {
	name = "int32",
	write = @native function(value: number): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if math_floor(value) ~= value or value < INT32_MIN or value > INT32_MAX then
				error(`int32.write: Value {value} is out of range ({INT32_MIN}..{INT32_MAX}).`)
			end
		end
		writei32(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readi32(b, cursor), cursor + 4
	end,
}
