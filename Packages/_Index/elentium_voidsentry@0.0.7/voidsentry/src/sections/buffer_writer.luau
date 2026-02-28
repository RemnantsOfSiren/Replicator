--!native
--!optimize 2
--!strict
local blen = buffer.len
local bcopy = buffer.copy
local bcreate = buffer.create

-- buffer write operations
local b_writeu8 = buffer.writeu8
local b_writeu16 = buffer.writeu16
local b_writeu32 = buffer.writeu32
local b_writei8 = buffer.writei8
local b_writei16 = buffer.writei16
local b_writei32 = buffer.writei32
local b_writef32 = buffer.writef32
local b_writef64 = buffer.writef64
local b_writestring = buffer.writestring
local b_fill = buffer.fill

local buf: buffer = nil :: any
local cursor: number = 0

local function alloc(bytes: number)
	local new_cursor = cursor + bytes
	local len = blen(buf)
	if new_cursor > len then
		local new_len = len
		while new_cursor > new_len do
			new_len = new_len * 1.5 // 1
		end
		local old_buf = buf
		buf = bcreate(new_len)
		bcopy(buf, 0, old_buf, 0, cursor)
	end
end

local buffer_writer = {}

function buffer_writer.init(start_cursor: number?): ()
	cursor = start_cursor or 0
	buf = bcreate(64 + cursor)
end

function buffer_writer.get_cursor(): number
	return cursor
end

function buffer_writer.get_buffer(): buffer
	return buf
end

-- write operations (allocate + write in one call to ensure fresh buffer reference)
function buffer_writer.writeu8(value: number): ()
	alloc(1)
	b_writeu8(buf, cursor, value)
	cursor += 1
end

function buffer_writer.writeu16(value: number): ()
	alloc(2)
	b_writeu16(buf, cursor, value)
	cursor += 2
end

function buffer_writer.writeu32(value: number): ()
	alloc(4)
	b_writeu32(buf, cursor, value)
	cursor += 4
end

function buffer_writer.writei8(value: number): ()
	alloc(1)
	b_writei8(buf, cursor, value)
	cursor += 1
end

function buffer_writer.writei16(value: number): ()
	alloc(2)
	b_writei16(buf, cursor, value)
	cursor += 2
end

function buffer_writer.writei32(value: number): ()
	alloc(4)
	b_writei32(buf, cursor, value)
	cursor += 4
end

function buffer_writer.writef32(value: number): ()
	alloc(4)
	b_writef32(buf, cursor, value)
	cursor += 4
end

function buffer_writer.writef64(value: number): ()
	alloc(8)
	b_writef64(buf, cursor, value)
	cursor += 8
end

function buffer_writer.writestring(value: string, len: number?): ()
	local str_len = len or #value
	alloc(str_len)
	b_writestring(buf, cursor, value, str_len)
	cursor += str_len
end

function buffer_writer.fill(value: number, count: number): ()
	alloc(count)
	b_fill(buf, cursor, value, count)
	cursor += count
end

return buffer_writer
