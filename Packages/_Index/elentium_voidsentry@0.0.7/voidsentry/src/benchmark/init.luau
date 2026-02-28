--!strict

local VoidSentry = require(".") -- adjust path if you move this file

local Types = VoidSentry.Types
local DynamicSerializer = VoidSentry.Dynamic
local StaticSerializer = VoidSentry.Static

local string_format = string.format
local os_clock = os.clock

local BENCHMARK_ITERATIONS = 2000

-- Benchmark helper function
local function benchmark(label: string, iterations: number, fn: () -> ()): number
	local start = os_clock()
	for _ = 1, iterations do
		fn()
	end
	local elapsedMs = (os_clock() - start) * 1000
	local avgMs = elapsedMs / iterations
	print(string_format("%s x%d: %.3f ms total (%.6f ms avg)", label, iterations, elapsedMs, avgMs))
	return elapsedMs
end

-- Test data samples
local testInt = 42
local testString = "Hello, World! This is a test string for benchmarking."
local testVector3 = Vector3.new(10.5, 20.3, 30.7)
local testBool = true
local testArray = { 1, 2, 3, 4, 5, 10, 20, 30 }
local testStruct = {
	Name = "TestPlayer",
	Level = 42,
	Position = Vector3.new(100, 50, 200),
	Health = 75.5,
	Premium = true,
}

print("\n" .. string.rep("=", 60))
print("VoidSentry Performance Benchmark")
print(string.rep("=", 60))
print(`Iterations per test: {BENCHMARK_ITERATIONS}`)
print(string.rep("=", 60) .. "\n")

-- ========== STATIC SERIALIZER BENCHMARKS ==========
print(
	"┌─ STATIC SERIALIZER BENCHMARKS ─────────────────────────┐"
)

-- Simple types
local simpleStatic = StaticSerializer.new(nil, Types.Int32, Types.String, Types.Bool)

print("\n  Simple Types (Int32, String, Bool):")
benchmark("    Static Serialize", BENCHMARK_ITERATIONS, function()
	simpleStatic:serialize(nil, testInt, testString, testBool)
end)
local serializedSimple = simpleStatic:serialize(nil, testInt, testString, testBool)
benchmark("    Static Deserialize", BENCHMARK_ITERATIONS, function()
	simpleStatic:deserialize(nil, serializedSimple)
end)

-- Vector types
local vectorStatic = StaticSerializer.new(nil, Types.Vector3, Types.Vector3F24)

print("\n  Vector Types (Vector3, Vector3F24):")
benchmark("    Static Serialize", BENCHMARK_ITERATIONS, function()
	vectorStatic:serialize(nil, testVector3, testVector3)
end)
local serializedVector = vectorStatic:serialize(nil, testVector3, testVector3)
benchmark("    Static Deserialize", BENCHMARK_ITERATIONS, function()
	vectorStatic:deserialize(nil, serializedVector)
end)

-- Array types
local arrayStatic = StaticSerializer.new(nil, Types.Array(Types.Int32))
print("\n  Array Types (Array<Int32>):")
benchmark("    Static Serialize", BENCHMARK_ITERATIONS, function()
	arrayStatic:serialize(nil, testArray)
end)
local serializedArray = arrayStatic:serialize(nil, testArray)
benchmark("    Static Deserialize", BENCHMARK_ITERATIONS, function()
	arrayStatic:deserialize(nil, serializedArray)
end)

-- Struct types
local structType = Types.Struct({
	Name = Types.String,
	Level = Types.Int32,
	Position = Types.Vector3,
	Health = Types.Float32,
	Premium = Types.Bool,
})
local structStatic = StaticSerializer.new(nil, structType)
print("\n  Struct Types (PlayerData):")
benchmark("    Static Serialize", BENCHMARK_ITERATIONS, function()
	structStatic:serialize(nil, testStruct)
end)
local serializedStruct = structStatic:serialize(nil, testStruct)
benchmark("    Static Deserialize", BENCHMARK_ITERATIONS, function()
	structStatic:deserialize(nil, serializedStruct)
end)

-- Complex nested types
local complexStatic = StaticSerializer.new(
	nil,
	Types.Struct({
		Id = Types.Int32,
		Inventory = Types.Array(Types.String),
		Stats = Types.Map(Types.String, Types.Int32),
	})
)
local complexData = {
	Id = 123,
	Inventory = { "Sword", "Shield", "Potion" },
	Stats = { Health = 100, Mana = 50, Score = 1000 },
}
print("\n  Complex Nested Types (Struct with Array and Map):")
benchmark("    Static Serialize", BENCHMARK_ITERATIONS, function()
	complexStatic:serialize(nil, complexData)
end)
local serializedComplex = complexStatic:serialize(nil, complexData)
benchmark("    Static Deserialize", BENCHMARK_ITERATIONS, function()
	complexStatic:deserialize(nil, serializedComplex)
end)

-- With compression
local compressedStatic = StaticSerializer.new(5, Types.Int32, Types.String, Types.Bool)
print("\n  With Compression (Level 5):")
benchmark("    Static Serialize (Compressed)", BENCHMARK_ITERATIONS, function()
	compressedStatic:serialize(nil, testInt, testString, testBool)
end)
local serializedCompressed = compressedStatic:serialize(nil, testInt, testString, testBool)
benchmark("    Static Deserialize (Compressed)", BENCHMARK_ITERATIONS, function()
	compressedStatic:deserialize(nil, serializedCompressed)
end)

print(
	"\n└──────────────────────────────────────────────────────────┘"
)

-- ========== DYNAMIC SERIALIZER BENCHMARKS ==========
print(
	"\n┌─ DYNAMIC SERIALIZER BENCHMARKS ────────────────────────┐"
)

-- Simple types
print("\n  Simple Types (Int32, String, Bool):")
benchmark("    Dynamic Serialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, testInt, testString, testBool)
end)
local dynamicSerializedSimple = DynamicSerializer.serialize(nil, nil, testInt, testString, testBool)
benchmark("    Dynamic Deserialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, dynamicSerializedSimple)
end)

-- Vector types
print("\n  Vector Types (Vector3):")
benchmark("    Dynamic Serialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, testVector3)
end)
local dynamicSerializedVector = DynamicSerializer.serialize(nil, nil, testVector3)
benchmark("    Dynamic Deserialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, dynamicSerializedVector)
end)

-- Array types
print("\n  Array Types (Mixed Array):")
benchmark("    Dynamic Serialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, testArray)
end)
local dynamicSerializedArray = DynamicSerializer.serialize(nil, nil, testArray)
benchmark("    Dynamic Deserialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, dynamicSerializedArray)
end)

-- Struct types (as table)
print("\n  Struct Types (PlayerData as Table):")
benchmark("    Dynamic Serialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, testStruct)
end)
local dynamicSerializedStruct = DynamicSerializer.serialize(nil, nil, testStruct)
benchmark("    Dynamic Deserialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, dynamicSerializedStruct)
end)

-- Complex nested types
print("\n  Complex Nested Types (Nested Tables):")
benchmark("    Dynamic Serialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, complexData)
end)
local dynamicSerializedComplex = DynamicSerializer.serialize(nil, nil, complexData)
benchmark("    Dynamic Deserialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, dynamicSerializedComplex)
end)

-- Mixed types
local mixedTypes = { 42, "hello", true, Vector3.new(1, 2, 3), { 1, 2, 3 }, { key = "value" } }
print("\n  Mixed Types (Multiple Different Types):")
benchmark("    Dynamic Serialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(nil, nil, table.unpack(mixedTypes))
end)
local dynamicSerializedMixed = DynamicSerializer.serialize(nil, nil, table.unpack(mixedTypes))
benchmark("    Dynamic Deserialize", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(nil, nil, dynamicSerializedMixed)
end)

-- With compression
print("\n  With Compression (Level 5):")
benchmark("    Dynamic Serialize (Compressed)", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.serialize(5, nil, testInt, testString, testBool)
end)
local dynamicSerializedCompressed = DynamicSerializer.serialize(5, nil, testInt, testString, testBool)
benchmark("    Dynamic Deserialize (Compressed)", BENCHMARK_ITERATIONS, function()
	DynamicSerializer.deserialize(5, nil, dynamicSerializedCompressed)
end)

print(
	"\n└──────────────────────────────────────────────────────────┘"
)

-- ========== COMPARISON SUMMARY ==========
print("\n" .. string.rep("=", 60))
print("BENCHMARK SUMMARY")
print(string.rep("=", 60))

-- Run comparison benchmarks
local simpleStaticTime = benchmark("Static Simple (Total)", BENCHMARK_ITERATIONS, function()
	local b = simpleStatic:serialize(nil, testInt, testString, testBool)
	simpleStatic:deserialize(nil, b)
end)

local simpleDynamicTime = benchmark("Dynamic Simple (Total)", BENCHMARK_ITERATIONS, function()
	local b = DynamicSerializer.serialize(nil, nil, testInt, testString, testBool)
	DynamicSerializer.deserialize(nil, nil, b)
end)

local ratio = simpleDynamicTime / simpleStaticTime
print(string_format("\nStatic vs Dynamic Ratio: %.2fx faster (Static is faster)", ratio))
print(
	string_format(
		"Overhead per operation: %.6f ms (Dynamic adds ~%.6f ms)",
		(simpleDynamicTime - simpleStaticTime) / BENCHMARK_ITERATIONS,
		(simpleDynamicTime - simpleStaticTime) / BENCHMARK_ITERATIONS
	)
)

print("\n" .. string.rep("=", 60))
print("Benchmark completed!")
print(string.rep("=", 60) .. "\n")
