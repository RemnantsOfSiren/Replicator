--!strict
local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writestring = buffer_writer.writestring
-- localize buffer read functions
local readstring = buffer.readstring

return function(len: number)
	return {
		name = "string_fixed",
		write = @native function(value: string): ()
			if Config.VALIDATION_LEVEL >= 2 then
				if len ~= #value then
					error(`string_fixed.write: String length ({#value}) does not match expected length ({len}).`)
				end
			end
			writestring(value, len)
		end,
		read = @native function(b: buffer, cursor: number): (string, number)
			return readstring(b, cursor, len), cursor + len
		end,
	}
end
