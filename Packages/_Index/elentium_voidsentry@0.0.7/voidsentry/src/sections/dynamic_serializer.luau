--!native
--!optimize 2

-- [ Services ]
local EncodingService = game:GetService("EncodingService")

-- [ Variables ]
local buffer_writer = require("./buffer_writer")
local TypeSigns = require("./shared/TypeSigns")

-- localize buffer_writer functions
local write_init = buffer_writer.init
local write_get_cursor = buffer_writer.get_cursor
local write_get_buffer = buffer_writer.get_buffer

-- localize
local blen = buffer.len
local b_create = buffer.create
local b_copy = buffer.copy

-- init types
local export_type_node = require("./exports/type_node")
local Config = require("./shared/Config")
type typeNode = export_type_node.typeNode

local types: {
	[string]: typeNode | ((...any) -> typeNode),
} = {}
for type, sign in TypeSigns do
	-- skip the Reverse table and only process string type names with numeric signs
	if typeof(type) == "string" and typeof(sign) == "number" then
		types[type] = require(`./types/{type:lower()}`)
	end
end

local GetElementType = require("./shared/GetElementType")
local GetElementNode = require("./shared/GetElementNode")
local BuildTypeNode = require("./shared/BuildTypeNode")
local WriteTypeSignsRecursive = require("./shared/WriteTypeSignsRecursive")

-- [ API ]
local serializer = {}

function serializer.serialize(compressLevel: number?, start_cursor: number?, ...: any): buffer
	-- validation: compression level range check
	if Config.VALIDATION_LEVEL >= 1 then
		if typeof(compressLevel) == "number" and (compressLevel < -7 or compressLevel > 22) then
			error(`Invalid compression level: {compressLevel}. Must be between -7 and 22`)
		end

		-- validation: cursor check
		if start_cursor ~= nil and start_cursor < 0 then
			error(`Invalid cursor: {start_cursor}. Must be >= 0`)
		end
	end

	local input = table.pack(...)
	local inputCount = input.n
	local writes: { { typeNode: typeNode, value: any } } = table.create(inputCount)

	for i = 1, inputCount do
		local value = input[i]
		local type = GetElementType(value)
		if type == "unknown" then
			error(`Unknown type detected(unsupported serialization type: {typeof(value)})`)
		end

		local typeModule = types[type]
		local typeNode = GetElementNode(typeModule, value)
		writes[i] = { typeNode = typeNode, value = value }
	end

	write_init(start_cursor)

	for _, write in writes do
		-- write type signs recursively (including nested types)
		WriteTypeSignsRecursive(write.typeNode, write.value)
		-- write the actual value data
		write.typeNode.write(write.value)
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

	if typeof(compressLevel) == "number" then
		b = EncodingService:CompressBuffer(b, Enum.CompressionAlgorithm.Zstd, compressLevel)
	end

	return b
end

function serializer.deserialize(compressLevel: number?, cursor: number?, b: buffer): ...any
	-- validation: compression level range check
	if Config.VALIDATION_LEVEL >= 1 then
		if typeof(compressLevel) == "number" and (compressLevel < -7 or compressLevel > 22) then
			error(`Invalid compression level: {compressLevel}. Must be between -7 and 22`)
		end

		-- validation: cursor check
		if cursor ~= nil and cursor < 0 then
			error(`Invalid cursor: {cursor}. Must be >= 0`)
		end
	end

	if typeof(compressLevel) == "number" then
		b = EncodingService:DecompressBuffer(b, Enum.CompressionAlgorithm.Zstd)
	end

	local len = blen(b)
	cursor = cursor or 0
	local result = {}
	local resultCount = 0

	while cursor < len do
		-- build type node recursively from serialized type signs
		local typeNode: typeNode
		typeNode, cursor = BuildTypeNode(b, cursor)

		-- read the actual value using the type node
		local val: any
		val, cursor = typeNode.read(b, cursor)
		resultCount += 1
		result[resultCount] = val
	end

	return table.unpack(result, 1, resultCount)
end

serializer.GetElementType = GetElementType

return serializer
