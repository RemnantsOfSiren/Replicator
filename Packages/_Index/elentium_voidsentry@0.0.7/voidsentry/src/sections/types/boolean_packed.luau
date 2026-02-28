--!strict
local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8

local bor = bit32.bor
local lshift = bit32.lshift
local band = bit32.band

return {
	name = "boolean_packed",
	write = @native function(value: { boolean }): ()
		if Config.VALIDATION_LEVEL >= 2 then
			if #value ~= 8 then
				error(`boolean_packed.write: Expected 8 booleans, got {#value}.`)
			end
		end
		local byte = 0x0
		for i = 1, #value do
			byte = bor(byte, lshift(value[i] and 0x1 or 0x0, i - 1))
		end
		writeu8(byte)
	end,
	read = @native function(b: buffer, cursor: number): ({ boolean }, number)
		local byte = readu8(b, cursor)
		local value: { boolean } = {}
		for i = 1, 8 do
			value[i] = band(byte, lshift(0x1, i - 1)) ~= 0x0
		end
		return value, cursor + 1
	end,
}
