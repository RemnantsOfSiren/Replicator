--!native
--!optimize 2
--!strict
-- [ Services ]
local EncodingService = game:GetService("EncodingService")

-- [ Variables ]
local buffer_writer = require("./buffer_writer")
local export_type_node = require("./exports/type_node")
local Config = require("./shared/Config")

-- localize buffer_writer functions
local write_init = buffer_writer.init
local write_get_cursor = buffer_writer.get_cursor
local write_get_buffer = buffer_writer.get_buffer

type TypeNode = export_type_node.typeNode

-- localize
local blen = buffer.len
local b_copy = buffer.copy
local b_create = buffer.create

-- [ API ]
local serializer = {}
serializer.__index = serializer
function serializer.new(compressionLevel: number?, ...: TypeNode)
	local self = setmetatable({}, serializer)
	self.schema = { ... }

	-- validation: compression level range check
	if Config.VALIDATION_LEVEL >= 1 then
		if typeof(compressionLevel) == "number" and (compressionLevel < -7 or compressionLevel > 22) then
			error(`Invalid compression level: {compressionLevel}. Must be between -7 and 22`)
		end
	end

	self.compressionLevel = compressionLevel
	return self
end

function serializer:serialize(start_cursor: number?, ...: any): buffer
	local input = table.pack(...)
	local schema: { TypeNode } = self.schema

	if Config.VALIDATION_LEVEL >= 1 then
		local inputCount = input.n
		local schemaCount = #schema

		if inputCount < schemaCount then
			local trailingAllowedCount = 0
			for i = schemaCount, inputCount + 1, -1 do
				local node = schema[i]
				if node and (node.name == "optional" or node.name == "nil") then
					trailingAllowedCount += 1
				else
					break
				end
			end

			if inputCount + trailingAllowedCount < schemaCount then
				error(`Schema mismatch: expected {schemaCount} values, got {inputCount}`)
			end
		elseif inputCount > schemaCount then
			error(`Schema mismatch: expected {schemaCount} values, got {inputCount}`)
		end

		if start_cursor ~= nil and start_cursor < 0 then
			error(`Invalid cursor: {start_cursor}. Must be >= 0`)
		end
	end

	write_init(start_cursor)
	for i, node: TypeNode in schema do
		local value = input[i] -- will be nil if not provided, which is fine for optional types
		node.write(value)
	end

	-- trim the buffer to actual size
	local cursor = write_get_cursor()
	local b = write_get_buffer()
	local len = blen(b)
	if len > cursor then
		local old_buf = b
		b = b_create(cursor)
		b_copy(b, 0, old_buf, 0, cursor)
	end

	if typeof(self.compressionLevel) == "number" then
		b = EncodingService:CompressBuffer(b, Enum.CompressionAlgorithm.Zstd, self.compressionLevel)
	end

	return b
end

function serializer:deserialize(cursor: number?, b: buffer): ...any
	-- validation: cursor check
	if Config.VALIDATION_LEVEL >= 1 then
		if cursor ~= nil and cursor < 0 then
			error(`Invalid cursor: {cursor}. Must be >= 0`)
		end
	end

	if typeof(self.compressionLevel) == "number" then
		b = EncodingService:DecompressBuffer(b, Enum.CompressionAlgorithm.Zstd)
	end

	local schema: { TypeNode } = self.schema
	local schemaCount = #schema
	local result = table.create(schemaCount)
	cursor = cursor or 0
	for i = 1, schemaCount do
		local node = schema[i]
		result[i], cursor = node.read(b, cursor :: number)
	end

	return table.unpack(result, 1, schemaCount)
end

return serializer
