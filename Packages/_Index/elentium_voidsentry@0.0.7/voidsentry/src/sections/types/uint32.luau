local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")
local math_floor = math.floor

-- localize buffer_writer functions
local writeu32 = buffer_writer.writeu32
-- localize buffer read functions
local readu32 = buffer.readu32

local UINT32_MIN = 0
local UINT32_MAX = 4294967295

return {
	name = "uint32",
	write = @native function(value: number): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if math_floor(value) ~= value or value < UINT32_MIN or value > UINT32_MAX then
				error(`uint32.write: Value {value} is out of range ({UINT32_MIN}..{UINT32_MAX}).`)
			end
		end
		writeu32(value)
	end,
	read = @native function(b: buffer, cursor: number): (number, number)
		return readu32(b, cursor), cursor + 4
	end,
}
