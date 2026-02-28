--!strict
local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu16 = buffer_writer.writeu16
-- localize buffer read functions
local readu16 = buffer.readu16

return function(Enum: Enum)
	return {
		name = "enum",
		write = @native function(value: EnumItem): ()
			if Config.VALIDATION_LEVEL >= 2 then
				if typeof(value) ~= "EnumItem" then
					error(`enum.write: Expected EnumItem, got {typeof(value)}`)
				end
				if value.EnumType ~= Enum then
					error(`enum.write: EnumItem belongs to {value.EnumType}, expected {Enum}`)
				end
			end
			writeu16(value.Value)
		end,
		read = @native function(b: buffer, cursor: number): (EnumItem, number)
			return Enum:FromValue(readu16(b, cursor)), cursor + 2
		end,
	}
end
