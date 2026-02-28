--!strict
local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
local writeu16 = buffer_writer.writeu16
local writeu32 = buffer_writer.writeu32
-- localize buffer read functions
local readu8 = buffer.readu8
local readu16 = buffer.readu16
local readu32 = buffer.readu32

type bits = number

local function node(
	name: string,
	count: number,
	step: number,
	write_fn: (value: number) -> (),
	read_fn: (b: buffer, cursor: number) -> number,
	mask: number
)
	return {
		name = name,
		write = @native function(value: { bits }): ()
			if Config.VALIDATION_LEVEL >= 2 then
				if #value ~= count then
					error(`bits.write: Expected {count} values, got {#value}.`)
				end
				for i = 1, count do
					local v = value[i]
					if type(v) ~= "number" or v < 0 or v > mask then
						error(`bits.write: Invalid value at index {i}. Must be 0..{mask}.`)
					end
				end
			end
			for i = 1, count do
				write_fn(bit32.band(value[i], mask))
			end
		end,
		read = @native function(b: buffer, cursor: number): ({ bits }, number)
			local bitsArray = {}
			for i = 1, count do
				bitsArray[i] = read_fn(b, cursor)
				cursor += step
			end
			return bitsArray, cursor
		end,
	}
end

return {
	_8 = function(count: number)
		return node("8_bit_array", count, 1, writeu8, readu8, 0xFF)
	end,
	_16 = function(count: number)
		return node("16_bit_array", count, 2, writeu16, readu16, 0xFFFF)
	end,
	_32 = function(count: number)
		return node("32_bit_array", count, 4, writeu32, readu32, 0xFFFFFFFF)
	end,
}
