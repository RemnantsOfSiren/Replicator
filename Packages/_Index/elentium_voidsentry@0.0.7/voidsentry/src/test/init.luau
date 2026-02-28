--!strict

local VoidSentry = require(".") -- adjust path if you decide to move the script

local Types = VoidSentry.Types
local DynamicSerializer = VoidSentry.Dynamic
local StaticSerializer = VoidSentry.Static

local string_format = string.format
local os_clock = os.clock

local DEFAULT_BENCH_ITERATIONS = 2000

local function benchmark(label: string, iterations: number, fn: () -> ())
	local start = os_clock()
	for _ = 1, iterations do
		fn()
	end
	local elapsedMs = (os_clock() - start) * 1000
	print(string_format("%s x%d: %.3f ms", label, iterations, elapsedMs))
end

local function expectError(name: string, fn: () -> any)
	local ok, err = pcall(fn)
	if ok then
		warn(`[EXPECTED ERROR FAILED] {name}: no error thrown`)
	else
		print(`[EXPECTED ERROR OK] {name}: {err}`)
	end
end

local function buildArray(len: number, value: any)
	local t = table.create(len)
	for i = 1, len do
		t[i] = value
	end
	return t
end

local function testStatic(name: string, serializer: any, ...: any)
	print(`___________ {name} (STATIC) ____________`)
	local input = table.pack(...)
	local b = serializer:serialize(nil, table.unpack(input, 1, input.n))
	print(`Buffer size: {buffer.len(b)}`)
	local results = table.pack(serializer:deserialize(nil, b))
	print("Serialized:", table.unpack(input, 1, input.n))
	print("Deserialized:", table.unpack(results, 1, results.n))
	benchmark(`${name} serialize`, DEFAULT_BENCH_ITERATIONS, function()
		serializer:serialize(nil, table.unpack(input, 1, input.n))
	end)
	benchmark(`${name} deserialize`, DEFAULT_BENCH_ITERATIONS, function()
		serializer:deserialize(nil, b)
	end)
	print("________________________")
end

local function testDynamic(name: string, ...: any)
	print(`___________ {name} (DYNAMIC) ____________`)
	local input = table.pack(...)
	local b = DynamicSerializer.serialize(nil, nil, table.unpack(input, 1, input.n))
	print(`Buffer size: {buffer.len(b)}`)
	local results = table.pack(DynamicSerializer.deserialize(nil, nil, b))
	print("Serialized:", table.unpack(input, 1, input.n))
	print("Deserialized:", table.unpack(results, 1, results.n))
	benchmark(`${name} serialize`, DEFAULT_BENCH_ITERATIONS, function()
		DynamicSerializer.serialize(nil, nil, table.unpack(input, 1, input.n))
	end)
	benchmark(`${name} deserialize`, DEFAULT_BENCH_ITERATIONS, function()
		DynamicSerializer.deserialize(nil, nil, b)
	end)
	print("________________________")
end

-- ========== NUMERIC TYPES ==========
print("\n========== NUMERIC TYPES ==========\n")

testStatic("INT32", StaticSerializer.new(0, Types.Int32), 1022)
testDynamic("INT32", 1022)

testStatic("INT16", StaticSerializer.new(0, Types.Int16), 1022)
testDynamic("INT16", 1022)

testStatic("INT8", StaticSerializer.new(0, Types.Int8), -10)
testDynamic("INT8", -10)

testStatic("UINT32", StaticSerializer.new(0, Types.UInt32), 1022)
testDynamic("UINT32", 1022)

testStatic("UINT16", StaticSerializer.new(0, Types.UInt16), 10)
testDynamic("UINT16", 10)

testStatic("UINT8", StaticSerializer.new(0, Types.UInt8), 255)
testDynamic("UINT8", 255)

testStatic("FLOAT32", StaticSerializer.new(0, Types.Float32), 3.141592653589793)
testDynamic("FLOAT32", 3.14159)

testStatic("FLOAT24", StaticSerializer.new(0, Types.Float24), 3.14)
testDynamic("FLOAT24", 3.14)

testStatic("FLOAT64", StaticSerializer.new(0, Types.Float64), 3.141592653589793)
testDynamic("FLOAT64", 3.141592653589793)

-- ========== BOOLEAN TYPES ==========
print("\n========== BOOLEAN TYPES ==========\n")

testStatic("BOOL", StaticSerializer.new(0, Types.Bool), true)
testDynamic("BOOL", true)

testStatic(
	"BOOL_PACKED",
	StaticSerializer.new(0, Types.BoolPacked),
	{ true, false, true, false, true, false, true, false }
)
testDynamic("BOOL_PACKED", { true, false, true, false, true, false, true, false })

-- ========== STRING TYPES ==========
print("\n========== STRING TYPES ==========\n")

testStatic("STRING", StaticSerializer.new(0, Types.String), "Hello, World!")
testDynamic("STRING", "Hello, World!")

testStatic("STRING_TINY", StaticSerializer.new(0, Types.StringTiny), "hello, world!")
testDynamic("STRING_TINY", "hello!")

testStatic("STRING_FIXED", StaticSerializer.new(0, Types.StringFixed(13)), "hello, world!")
-- Note: StringFixed requires exact length, so dynamic serializer uses regular String

-- ========== VECTOR TYPES ==========
print("\n========== VECTOR TYPES ==========\n")

testStatic("VECTOR3", StaticSerializer.new(0, Types.Vector3), Vector3.new(3.14, 3.14, 3.14))
testDynamic("VECTOR3", Vector3.new(3.14, 3.14, 3.14))

testStatic("VECTOR3_F24", StaticSerializer.new(0, Types.Vector3F24), Vector3.new(3.14, 3.14, 3.14))
testDynamic("VECTOR3_F24", Vector3.new(3.14, 3.14, 3.14))

testStatic("VECTOR3_INT16", StaticSerializer.new(0, Types.Vector3int16), Vector3int16.new(100, 200, 300))
testDynamic("VECTOR3_INT16", Vector3int16.new(100, 200, 300))

testStatic("VECTOR2", StaticSerializer.new(0, Types.Vector2), Vector2.new(3.14, 3.14))
testDynamic("VECTOR2", Vector2.new(3.14, 3.14))

testStatic("VECTOR2_F24", StaticSerializer.new(0, Types.Vector2F24), Vector2.new(3.14, 3.14))
testDynamic("VECTOR2_F24", Vector2.new(3.14, 3.14))

testStatic("VECTOR2_INT16", StaticSerializer.new(0, Types.Vector2int16), Vector2int16.new(100, 200))
testDynamic("VECTOR2_INT16", Vector2int16.new(100, 200))

testStatic("VECTOR", StaticSerializer.new(0, Types.Vector), vector.create(3.14, 3.14, 3.14))
testDynamic("VECTOR", vector.create(3.14, 3.14, 3.14))

testStatic("VECTOR_F24", StaticSerializer.new(0, Types.VectorF24), vector.create(3.14, 3.14, 3.14))
testDynamic("VECTOR_F24", vector.create(3.14, 3.14, 3.14))

testStatic("VECTOR_INT16", StaticSerializer.new(0, Types.VectorInt16), vector.create(100, 200, 300))
testDynamic("VECTOR_INT16", vector.create(100, 200, 300))

-- ========== CFRAME TYPES ==========
print("\n========== CFRAME TYPES ==========\n")

testStatic("CFRAME", StaticSerializer.new(0, Types.CFrame), CFrame.new(0, 10, 0))
testDynamic("CFRAME", CFrame.new(0, 10, 0))

testStatic("CFRAME_Q", StaticSerializer.new(0, Types.CFrameQ), CFrame.new(0, 10, 0))
testDynamic("CFRAME_Q", CFrame.new(0, 10, 0))

-- ========== COLOR3 ==========
print("\n========== COLOR3 ==========\n")

testStatic("COLOR3", StaticSerializer.new(0, Types.Color3), Color3.new(1, 0, 0))
testDynamic("COLOR3", Color3.new(1, 0, 0))

-- ========== ARRAY TYPES ==========
print("\n========== ARRAY TYPES ==========\n")

testStatic("ARRAY", StaticSerializer.new(0, Types.Array(Types.Int32)), { 1, 2, 3, 4, 5 })
testDynamic("ARRAY", { 1, 2, 3, 4, 5 })

testStatic("ARRAY_TINY", StaticSerializer.new(0, Types.ArrayTiny(Types.Int32)), { 1, 2, 3 })
testDynamic("ARRAY_TINY", { 1, 2, 3 })

testStatic("ARRAY_FIXED", StaticSerializer.new(0, Types.ArrayFixed(Types.Int32, 3)), { 1, 2, 3 })
-- Note: ArrayFixed requires exact length

testStatic("ARRAY_NESTED", StaticSerializer.new(0, Types.Array(Types.Array(Types.Int32))), { { 1, 2 }, { 3, 4 } })
testDynamic("ARRAY_NESTED", { { 1, 2 }, { 3, 4 } })

testStatic("ARRAY_MIXED", StaticSerializer.new(0, Types.Array(Types.Any)), { 1, "hello", true, Vector3.new(1, 2, 3) })
testDynamic("ARRAY_MIXED", { 1, "hello", true, Vector3.new(1, 2, 3) })

-- ========== MAP TYPES ==========
print("\n========== MAP TYPES ==========\n")

testStatic("MAP", StaticSerializer.new(0, Types.Map(Types.String, Types.Int32)), { hello = 1, world = 2 })
testDynamic("MAP", { hello = 1, world = 2 })

testStatic("MAP_FIXED", StaticSerializer.new(0, Types.MapFixed(Types.String, Types.Int32, 2)), { hello = 1, world = 2 })
-- Note: MapFixed requires exact length

testStatic("MAP_NESTED", StaticSerializer.new(0, Types.Map(Types.String, Types.Map(Types.String, Types.Int32))), {
	player1 = { health = 100, score = 50 },
	player2 = { health = 80, score = 75 },
})
testDynamic("MAP_NESTED", {
	player1 = { health = 100, score = 50 },
	player2 = { health = 80, score = 75 },
})

-- ========== STRUCT TYPES ==========
print("\n========== STRUCT TYPES ==========\n")

local PlayerData = Types.Struct({
	Name = Types.String,
	Level = Types.Int32,
	Position = Types.Vector3,
	Health = Types.Float32,
	Inventory = Types.Array(Types.String),
})

testStatic("STRUCT", StaticSerializer.new(0, PlayerData), {
	Name = "Player123",
	Level = 42,
	Position = Vector3.new(100, 50, 200),
	Health = 75.5,
	Inventory = { "Sword", "Shield", "Potion" },
})
testDynamic("STRUCT", {
	Name = "Player123",
	Level = 42,
	Position = Vector3.new(100, 50, 200),
	Health = 75.5,
	Inventory = { "Sword", "Shield", "Potion" },
})

-- ========== OPTIONAL TYPES ==========
print("\n========== OPTIONAL TYPES ==========\n")

testStatic("OPTIONAL_STRING", StaticSerializer.new(0, Types.Optional(Types.String)), "hello")
testStatic("OPTIONAL_NIL", StaticSerializer.new(0, Types.Optional(Types.String)), nil)
testDynamic("OPTIONAL_STRING", "hello")
testDynamic("OPTIONAL_NIL", nil)

-- ========== NIL HANDLING ==========
print("\n========== NIL HANDLING ==========\n")

local NilOnly = StaticSerializer.new(0, Types.Nil)
testStatic("NIL_ONLY_STATIC", NilOnly)
testDynamic("NIL_ONLY_DYNAMIC", nil)

local MixedNil = StaticSerializer.new(0, Types.Int32, Types.Nil, Types.Bool)
testStatic("MIXED_NIL_STATIC", MixedNil, 1, nil, true)
testDynamic("MIXED_NIL_DYNAMIC", 1, nil, true)

-- ========== BOUNDARY TESTS ==========
print("\n========== BOUNDARY TESTS ==========\n")

testStatic("INT8_MIN", StaticSerializer.new(0, Types.Int8), -128)
testStatic("INT8_MAX", StaticSerializer.new(0, Types.Int8), 127)
testStatic("UINT8_MIN", StaticSerializer.new(0, Types.UInt8), 0)
testStatic("UINT8_MAX", StaticSerializer.new(0, Types.UInt8), 255)

testStatic("INT16_MIN", StaticSerializer.new(0, Types.Int16), -32768)
testStatic("INT16_MAX", StaticSerializer.new(0, Types.Int16), 32767)
testStatic("UINT16_MIN", StaticSerializer.new(0, Types.UInt16), 0)
testStatic("UINT16_MAX", StaticSerializer.new(0, Types.UInt16), 65535)

testStatic("INT32_MIN", StaticSerializer.new(0, Types.Int32), -2147483648)
testStatic("INT32_MAX", StaticSerializer.new(0, Types.Int32), 2147483647)
testStatic("UINT32_MIN", StaticSerializer.new(0, Types.UInt32), 0)
testStatic("UINT32_MAX", StaticSerializer.new(0, Types.UInt32), 4294967295)

local tinyStringMax = string.rep("a", 255)
testStatic("STRING_TINY_MAX", StaticSerializer.new(0, Types.StringTiny), tinyStringMax)
testDynamic("STRING_TINY_MAX", tinyStringMax)

local tinyArrayMax = buildArray(255, 1)
testStatic("ARRAY_TINY_MAX", StaticSerializer.new(0, Types.ArrayTiny(Types.Int32)), tinyArrayMax)
testDynamic("ARRAY_TINY_MAX", tinyArrayMax)

-- ========== SPECIAL TYPES ==========
print("\n========== SPECIAL TYPES ==========\n")

testStatic("VOID", StaticSerializer.new(0, Types.Void), {})
testDynamic("VOID", {})

testStatic("NIL", StaticSerializer.new(0, Types.Nil), nil)
testDynamic("NIL", nil)

-- ========== BITS TYPES ==========
print("\n========== BITS TYPES ==========\n")

testStatic("BITS_8", StaticSerializer.new(0, Types.Bits._8(4)), { 255, 128, 64, 32 })
testDynamic("BITS_8", { 255, 128, 64, 32 })

testStatic("BITS_16", StaticSerializer.new(0, Types.Bits._16(2)), { 65535, 32768 })
testDynamic("BITS_16", { 65535, 32768 })

testStatic("BITS_32", StaticSerializer.new(0, Types.Bits._32(1)), { 4294967295 })
testDynamic("BITS_32", { 4294967295 })

-- ========== ENUM TYPES ==========
print("\n========== ENUM TYPES ==========\n")

testStatic("ENUM_MATERIAL", StaticSerializer.new(0, Types.Enum(Enum.Material)), Enum.Material.Plastic)
testDynamic("ENUM_MATERIAL", Enum.Material.Plastic)

testStatic(
	"ENUM_HUMANOID_STATE",
	StaticSerializer.new(0, Types.Enum(Enum.HumanoidStateType)),
	Enum.HumanoidStateType.Running
)
testDynamic("ENUM_HUMANOID_STATE", Enum.HumanoidStateType.Running)

-- ========== INSTANCE TYPES ==========
print("\n========== INSTANCE TYPES ==========\n")

-- Create test Part instance
local testPart = Instance.new("Part")
testPart.Name = "TestPart"
testPart.CFrame = CFrame.new(10, 20, 30)
testPart.Color = Color3.new(1, 0.5, 0.25)
testPart.Transparency = 0.5
testPart.Material = Enum.Material.Neon
testPart.CanCollide = false
testPart.CanTouch = true
testPart.CanQuery = false
testPart.CastShadow = true

print("___________ INSTANCE_PART (STATIC) ____________")
local PartSerializer = StaticSerializer.new(0, Types.Instance("Part"))
local b_part = PartSerializer:serialize(nil, testPart)
print(`Buffer size: {buffer.len(b_part)}`)
local deserializedPart: Part = PartSerializer:deserialize(nil, b_part)
print("Original Part:", testPart.Name, testPart.CFrame, testPart.Color, testPart.Transparency, testPart.Material)
print(
	"Deserialized Part:",
	deserializedPart.Name,
	deserializedPart.CFrame,
	deserializedPart.Color,
	deserializedPart.Transparency,
	deserializedPart.Material
)
print(
	"Properties match:",
	deserializedPart.Name == testPart.Name,
	deserializedPart.CFrame == testPart.CFrame,
	deserializedPart.Transparency == testPart.Transparency,
	deserializedPart.CanCollide == testPart.CanCollide
)
benchmark(`INSTANCE_PART serialize`, DEFAULT_BENCH_ITERATIONS, function()
	PartSerializer:serialize(nil, testPart)
end)
benchmark(`INSTANCE_PART deserialize`, DEFAULT_BENCH_ITERATIONS, function()
	PartSerializer:deserialize(nil, b_part)
end)
print("________________________")

print("___________ INSTANCE_PART (DYNAMIC) ____________")
local b_part_dynamic = DynamicSerializer.serialize(nil, nil, testPart)
print(`Buffer size: {buffer.len(b_part_dynamic)}`)
local deserializedPartDynamic: Part = DynamicSerializer.deserialize(nil, nil, b_part_dynamic)
print("Original Part:", testPart.Name, testPart.CFrame, testPart.Color)
print("Deserialized Part:", deserializedPartDynamic.Name, deserializedPartDynamic.CFrame, deserializedPartDynamic.Color)
benchmark(`INSTANCE_PART_DYNAMIC serialize`, DEFAULT_BENCH_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, testPart)
end)
benchmark(`INSTANCE_PART_DYNAMIC deserialize`, DEFAULT_BENCH_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, b_part_dynamic)
end)
print("________________________")

-- Test MeshPart
local testMeshPart = Instance.new("MeshPart")
testMeshPart.Name = "TestMeshPart"
testMeshPart.CFrame = CFrame.new(100, 50, 200)
testMeshPart.Color = Color3.new(0, 1, 0)
testMeshPart.Transparency = 0.25
testMeshPart.Material = Enum.Material.Glass
testMeshPart.CanCollide = true
testMeshPart.CanTouch = false
testMeshPart.CanQuery = true
testMeshPart.CastShadow = false

print("___________ INSTANCE_MESHPART (STATIC) ____________")
local MeshPartSerializer = StaticSerializer.new(0, Types.Instance("MeshPart"))
local b_meshpart = MeshPartSerializer:serialize(nil, testMeshPart)
print(`Buffer size: {buffer.len(b_meshpart)}`)
local deserializedMeshPart: MeshPart = MeshPartSerializer:deserialize(nil, b_meshpart)
print("Original MeshPart:", testMeshPart.Name, testMeshPart.CFrame, testMeshPart.Color, testMeshPart.Material)
print(
	"Deserialized MeshPart:",
	deserializedMeshPart.Name,
	deserializedMeshPart.CFrame,
	deserializedMeshPart.Color,
	deserializedMeshPart.Material
)
benchmark(`INSTANCE_MESHPART serialize`, DEFAULT_BENCH_ITERATIONS, function()
	MeshPartSerializer:serialize(nil, testMeshPart)
end)
benchmark(`INSTANCE_MESHPART deserialize`, DEFAULT_BENCH_ITERATIONS, function()
	MeshPartSerializer:deserialize(nil, b_meshpart)
end)
print("________________________")

-- Test Array of Instances
print("___________ INSTANCE_ARRAY (STATIC) ____________")
local InstanceArraySerializer = StaticSerializer.new(0, Types.ArrayTiny(Types.Instance("Part")))
-- Note: This test assumes both parts are serialized with Part schema
-- Create two Part instances for this test
local part1 = Instance.new("Part")
part1.Name = "Part1"
part1.CFrame = CFrame.new(1, 2, 3)
part1.Color = Color3.new(1, 0, 0)
part1.Transparency = 0.1
part1.Material = Enum.Material.Plastic
part1.CanCollide = true
part1.CanTouch = true
part1.CanQuery = true
part1.CastShadow = true

local part2 = Instance.new("Part")
part2.Name = "Part2"
part2.CFrame = CFrame.new(4, 5, 6)
part2.Color = Color3.new(0, 1, 0)
part2.Transparency = 0.2
part2.Material = Enum.Material.Metal
part2.CanCollide = false
part2.CanTouch = false
part2.CanQuery = false
part2.CastShadow = false

local partsArray: { Part } = { part1, part2 }
local b_parts_array = InstanceArraySerializer:serialize(nil, partsArray)
print(`Buffer size: {buffer.len(b_parts_array)}`)
local deserializedPartsArray: { Part } = InstanceArraySerializer:deserialize(nil, b_parts_array)
print("Original array length:", #partsArray)
print("Deserialized array length:", #deserializedPartsArray)
print("First part name:", deserializedPartsArray[1].Name, "Second part name:", deserializedPartsArray[2].Name)
benchmark(`INSTANCE_ARRAY serialize`, DEFAULT_BENCH_ITERATIONS, function()
	InstanceArraySerializer:serialize(nil, partsArray)
end)
benchmark(`INSTANCE_ARRAY deserialize`, DEFAULT_BENCH_ITERATIONS, function()
	InstanceArraySerializer:deserialize(nil, b_parts_array)
end)
print("________________________")

-- Clean up test instances
testPart:Destroy()
testMeshPart:Destroy()
part1:Destroy()
part2:Destroy()
for _, p in deserializedPartsArray :: { Part } do
	p:Destroy()
end
deserializedPart:Destroy()
deserializedPartDynamic:Destroy()
deserializedMeshPart:Destroy()

-- ========== DEEP NESTED TYPES ==========
print("\n========== DEEP NESTED TYPES ==========\n")

local DeepStruct = Types.Struct({
	Id = Types.Int32,
	Meta = Types.Struct({
		Name = Types.String,
		Tags = Types.Array(Types.StringTiny),
		Flags = Types.Bits._8(4),
	}),
	Stats = Types.Map(Types.String, Types.Array(Types.Float32)),
	OptionalNote = Types.Optional(Types.StringTiny),
})

local DeepSerializer = StaticSerializer.new(0, DeepStruct, Types.Array(Types.Map(Types.String, Types.Any)))

local deepValue = {
	Id = 123,
	Meta = {
		Name = "Void",
		Tags = { "alpha", "beta", "gamma" },
		Flags = { 255, 128, 64, 32 },
	},
	Stats = {
		Health = { 100.5, 98.25, 75.0 },
		Mana = { 50.0, 25.5 },
	},
	OptionalNote = nil,
}

local deepArray = {
	{ key = "value", nested = { 1, true, nil, "x" } },
	{ other = { hello = "world", num = 2 } },
}

testStatic("DEEP_STRUCT", DeepSerializer, deepValue, deepArray)
testDynamic("DEEP_DYNAMIC", deepValue, deepArray)

-- ========== COMPLEX DYNAMIC TESTS ==========
print("\n========== COMPLEX DYNAMIC TESTS ==========\n")

testDynamic("MIXED_TYPES", 42, "hello", true, Vector3.new(1, 2, 3), { 1, 2, 3 }, { key = "value" })

testDynamic("NESTED_STRUCTURE", {
	player = {
		name = "Test",
		stats = {
			health = 100,
			mana = 50,
		},
		items = { "sword", "shield" },
	},
	timestamp = 1234567890,
})

-- ========== ERROR VALIDATION TESTS ==========
print("\n========== ERROR VALIDATION TESTS ==========\n")

expectError("STRING_TINY_TOO_LONG", function()
	local s = string.rep("a", 256)
	local ser = StaticSerializer.new(0, Types.StringTiny)
	ser:serialize(nil, s)
	return nil
end)

expectError("ARRAY_TINY_TOO_LONG", function()
	local arr = buildArray(256, 1)
	local ser = StaticSerializer.new(0, Types.ArrayTiny(Types.UInt8))
	ser:serialize(nil, arr)
	return nil
end)

expectError("BOOL_PACKED_BAD_LEN", function()
	local ser = StaticSerializer.new(0, Types.BoolPacked)
	ser:serialize(nil, { true, false })
	return nil
end)

expectError("BITS_COUNT_MISMATCH", function()
	local ser = StaticSerializer.new(0, Types.Bits._16(2))
	ser:serialize(nil, { 1 })
	return nil
end)

expectError("INT8_OUT_OF_RANGE", function()
	local ser = StaticSerializer.new(0, Types.Int8)
	ser:serialize(nil, 200)
	return nil
end)

expectError("UINT8_OUT_OF_RANGE", function()
	local ser = StaticSerializer.new(0, Types.UInt8)
	ser:serialize(nil, -1)
	return nil
end)

expectError("INT16_OUT_OF_RANGE", function()
	local ser = StaticSerializer.new(0, Types.Int16)
	ser:serialize(nil, 40000)
	return nil
end)

expectError("UINT16_OUT_OF_RANGE", function()
	local ser = StaticSerializer.new(0, Types.UInt16)
	ser:serialize(nil, -1)
	return nil
end)

expectError("INT32_OUT_OF_RANGE", function()
	local ser = StaticSerializer.new(0, Types.Int32)
	ser:serialize(nil, 2147483648)
	return nil
end)

expectError("UINT32_OUT_OF_RANGE", function()
	local ser = StaticSerializer.new(0, Types.UInt32)
	ser:serialize(nil, -1)
	return nil
end)

expectError("INSTANCE_INVALID_CLASS", function()
	-- Try to create serializer for unsupported class
	Types.Instance("UnsupportedClassName")
	return nil
end)

expectError("INSTANCE_CLASS_MISMATCH", function()
	-- Try to serialize a MeshPart with a Part serializer (class mismatch)
	local ser = StaticSerializer.new(0, Types.Instance("Part"))
	local meshPart = Instance.new("MeshPart")
	ser:serialize(nil, meshPart)
	meshPart:Destroy()
	return nil
end)

-- ========== COMPRESSION TESTS ==========
print("\n========== COMPRESSION TESTS ==========\n")

print("___________ COMPRESSION (STATIC) ____________")
local CompressedStatic = StaticSerializer.new(5, Types.String, Types.Int32, Types.Vector3)
local str_data = "Hello, World!"
local int_data = 42
local vec_data = Vector3.new(1, 2, 3)
local b_compressed = CompressedStatic:serialize(nil, str_data, int_data, vec_data)
print(`Compressed buffer size: {buffer.len(b_compressed)}`)
local uncompressed_str, uncompressed_int, uncompressed_vec = CompressedStatic:deserialize(nil, b_compressed)
print("Deserialized:", uncompressed_str, uncompressed_int, uncompressed_vec)
print("________________________")

print("___________ COMPRESSION (DYNAMIC) ____________")
local b_dynamic_compressed = DynamicSerializer.serialize(5, nil, "Hello, World!", 42, Vector3.new(1, 2, 3))
print(`Compressed buffer size: {buffer.len(b_dynamic_compressed)}`)
local uncompressed_dynamic = { DynamicSerializer.deserialize(5, nil, b_dynamic_compressed) }
print("Deserialized:", table.unpack(uncompressed_dynamic))
print("________________________")

-- ========== OFFSET TESTS ==========
print("\n========== OFFSET TESTS ==========\n")

print("___________ OFFSET (STATIC) ____________")
local OffsetStatic = StaticSerializer.new(0, Types.Int32, Types.String)
local b_offset = OffsetStatic:serialize(10, 42, "test") -- Offset of 10 bytes
print(`Buffer size with offset: {buffer.len(b_offset)}`)
local offset_result = { OffsetStatic:deserialize(10, b_offset) }
print("Deserialized:", table.unpack(offset_result))
print("________________________")

print("___________ OFFSET (DYNAMIC) ____________")
local b_dynamic_offset = DynamicSerializer.serialize(nil, 10, 42, "test")
print(`Buffer size with offset: {buffer.len(b_dynamic_offset)}`)
local offset_dynamic_result = { DynamicSerializer.deserialize(nil, 10, b_dynamic_offset) }
print("Deserialized:", table.unpack(offset_dynamic_result))
print("________________________")

print("\n========== ALL TESTS COMPLETE! ==========\n")
