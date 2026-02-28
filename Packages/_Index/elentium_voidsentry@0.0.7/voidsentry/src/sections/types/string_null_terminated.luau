--!strict
local buffer_writer = require("../buffer_writer")

-- localize buffer_writer functions
local writestring = buffer_writer.writestring
local writeu8 = buffer_writer.writeu8
-- localize buffer read functions
local readu8 = buffer.readu8
local readstring = buffer.readstring

return {
	name = "string_null_terminated",
	write = @native function(value: string): ()
		writestring(value)
		-- write null terminator
		writeu8(0)
	end,
	read = @native function(b: buffer, cursor: number): (string, number)
		local len = 0
		
		-- find null terminator
		while true do
			local byte = readu8(b, cursor + len)
			if byte == 0 then
				break
			end
			len += 1
		end
		
		return readstring(b, cursor, len), cursor + len + 1 -- +1 for null terminator
	end,
}
