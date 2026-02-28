--!strict
local buffer_writer = require("../buffer_writer")
local table_pack = table.pack
local cframe_new = CFrame.new

-- localize buffer_writer functions
local writef32 = buffer_writer.writef32
-- localize buffer read functions
local readf32 = buffer.readf32

--[[
    Most precise cframe serialization, but also the most expensive.
]]
return {
	name = "cframe",
	write = @native function(value: CFrame): ()
		local components = table_pack(value:GetComponents())
		for i = 1, components.n do
			writef32(components[i])
		end
	end,
	read = @native function(b: buffer, cursor: number): (CFrame, number)
		return cframe_new(
			-- position
			readf32(b, cursor),
			readf32(b, cursor + 4),
			readf32(b, cursor + 8),
			-- r0
			readf32(b, cursor + 12),
			readf32(b, cursor + 16),
			readf32(b, cursor + 20),
			-- r1
			readf32(b, cursor + 24),
			readf32(b, cursor + 28),
			readf32(b, cursor + 32),
			-- r2
			readf32(b, cursor + 36),
			readf32(b, cursor + 40),
			readf32(b, cursor + 44)
		), cursor + 48
	end,
}
