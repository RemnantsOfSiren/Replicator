local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu16 = buffer_writer.writeu16
local writestring = buffer_writer.writestring
-- localize buffer read functions
local readu16 = buffer.readu16
local readstring = buffer.readstring

return {
	name = "string",
	write = @native function(value: string): ()
		local len = #value
		if Config.VALIDATION_LEVEL >= 2 then
			if len > 65535 then
				error(`string.write: String length ({len}) exceeds max length (65535).`)
			end
		end
		writeu16(len)
		writestring(value)
	end,
	read = @native function(b: buffer, cursor: number): (string, number)
		local len = readu16(b, cursor)
		cursor += 2
		return readstring(b, cursor, len), cursor + len
	end,
}
