local buffer_writer = require("../buffer_writer")
local Config = require("../shared/Config")

-- localize buffer_writer functions
local writeu8 = buffer_writer.writeu8
local writestring = buffer_writer.writestring
-- localize buffer read functions
local readu8 = buffer.readu8
local readstring = buffer.readstring

return {
	name = "string_tiny",
	write = @native function(value: string): ()
		local len = #value
		if Config.VALIDATION_LEVEL >= 2 then
			if len > 255 then
				error(`string_tiny.write: String length ({len}) exceeds max length (255).`)
			end
		end
		writeu8(len)
		writestring(value)
	end,
	read = @native function(b: buffer, cursor: number): (string, number)
		local len = readu8(b, cursor)
		cursor += 1
		return readstring(b, cursor, len), cursor + len
	end,
}
