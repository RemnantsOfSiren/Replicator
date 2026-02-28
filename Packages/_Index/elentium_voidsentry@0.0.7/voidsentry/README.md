# VoidSentry

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

**A high-performance buffer serialization library for Roblox**

VoidSentry is a powerful, low-level buffer serializer designed for efficient data transmission in Roblox games. It provides both static (schema-based) and dynamic (schemaless) serialization with support for a wide range of data types.

## Features

- **Two Serialization Modes**
  - **Static Serializer**: Schema-based serialization for maximum performance
  - **Dynamic Serializer**: Flexible schemaless serialization with type inference

- **Rich Type Support**: 30+ built-in types including primitives, Roblox types, and complex data structures

- **Optional Compression**: Built-in Zstd compression support for reduced bandwidth

- **Type Safety**: Full strict-mode Luau type annotations for better IDE support

- **High Performance**: Native optimizations and efficient buffer operations

- **Zero Dependencies**: Standalone library with no external requirements

## Installation

### Using Wally

Add VoidSentry to your `wally.toml`:

```toml
[dependencies]
VoidSentry = "elentium/voidsentry@0.0.7"
```

Then run:

```bash
wally install
```

### Manual Installation

1. Download the latest release
2. Place the `VoidSentry` folder in your `ReplicatedStorage.Packages`
3. Require it in your scripts

## Quick Start

### Static Serializer (Recommended for Performance)

The static serializer requires you to define a schema upfront, but offers the best performance:

```luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoidSentry = require(ReplicatedStorage.Packages.VoidSentry)

local Types = VoidSentry.Types

-- Create a serializer with a fixed schema
local Serializer = VoidSentry.Static.new(
    nil, -- No compression
    Types.Int32,
    Types.String,
    Types.Struct({
        Hello = Types.String,
        World = Types.Int32,
    })
)

-- Serialize data
local b = Serializer:serialize(
    nil, -- No offset
    42,
    "Hello, world!",
    {
        Hello = "hi",
        World = 999,
    }
)

print("Buffer size:", buffer.len(b)) -- 27 bytes

-- Deserialize data
local int, str, struct = Serializer:deserialize(nil, b)
print(int, str, struct) -- 42, "Hello, world!", {Hello = "hi", World = 999}
```

### Dynamic Serializer (Flexible)

The dynamic serializer automatically infers types, offering more flexibility at the cost of performance:

```luau
--!strict
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VoidSentry = require(ReplicatedStorage.Packages.VoidSentry)

local Dynamic = VoidSentry.Dynamic

-- No schema required!
local buffer = Dynamic.serialize(
    nil, -- No compression
    nil, -- No offset
    42,
    "Dynamic serialization",
    Vector3.new(10, 20, 30),
    true
)

-- Deserialize automatically
local int, str, vec, bool = Dynamic.deserialize(nil, nil, buffer)
print(int, str, vec, bool)
```

## API Reference

### Static Serializer

#### `VoidSentry.Static.new(compressionLevel: number?, ...TypeNode): StaticObject`

Creates a new static serializer with a fixed schema.

**Parameters:**

- `compressionLevel` (optional): Zstd compression level (-7 to 22, or `nil` for no compression)
- `...TypeNode`: Variable number of type nodes defining the schema

**Returns:** A `StaticObject` with `serialize` and `deserialize` methods

#### `StaticObject:serialize(offset: number?, ...values): buffer`

Serializes data according to the schema.

**Parameters:**

- `offset` (optional): Starting byte offset in the buffer (reserves `offset` bytes at the beginning for custom metadata)
- `...values`: Values matching the schema types

**Returns:** A buffer containing the serialized data

#### `StaticObject:deserialize(offset: number?, buffer: buffer): ...values`

Deserializes data from a buffer.

**Parameters:**

- `offset` (optional): Starting byte offset to read from (skips `offset` bytes at the beginning, e.g., custom metadata)
- `buffer`: The buffer to deserialize

**Returns:** One or multiple values matching the schema

### Dynamic Serializer

#### `VoidSentry.Dynamic.serialize(compressionLevel: number?, offset: number?, ...values): buffer`

Serializes data with automatic type inference.

**Parameters:**

- `compressionLevel` (optional): Zstd compression level (-7 to 22)
- `offset` (optional): Starting byte offset (reserves `offset` bytes at the beginning for custom metadata)
- `...values`: Any serializable values

**Returns:** A buffer with type information and data

#### `VoidSentry.Dynamic.deserialize(compressionLevel: number?, offset: number?, buffer: buffer): ...values`

Deserializes data with embedded type information.

**Parameters:**

- `compressionLevel` (optional): Must match serialization compression level
- `offset` (optional): Starting byte offset (skips `offset` bytes at the beginning, e.g., custom metadata)
- `buffer`: The buffer to deserialize

**Returns:** All values that were serialized

## Available Types

### Numeric Types

| Type | Description | Size | Range |
|------|-------------|------|-------|
| `Types.Int8` | Signed 8-bit integer | 1 byte | -128 to 127 |
| `Types.UInt8` | Unsigned 8-bit integer | 1 byte | 0 to 255 |
| `Types.Int16` | Signed 16-bit integer | 2 bytes | -32,768 to 32,767 |
| `Types.UInt16` | Unsigned 16-bit integer | 2 bytes | 0 to 65,535 |
| `Types.Int32` | Signed 32-bit integer | 4 bytes | -2³¹ to 2³¹-1 |
| `Types.UInt32` | Unsigned 32-bit integer | 4 bytes | 0 to 2³²-1 |
| `Types.Float32` | 32-bit floating point | 4 bytes | IEEE 754 single precision |
| `Types.Float64` | 64-bit floating point | 8 bytes | IEEE 754 double precision |
| `Types.Float24` | 24-bit floating point | 3 bytes | Reduced precision (custom format) |

### String Types

| Type | Description | Max Size |
|------|-------------|----------|
| `Types.String` | Standard string | 65,535 + 2 bytes (16-bit length prefix) |
| `Types.StringTiny` | Compact string | 255 + 1 byte (8-bit length prefix) |
| `Types.StringFixed` | Fixed length string | User-defined length |
| `Types.StringNullTerminated` | Null-terminated string (C-style) | Unlimited |

### Boolean & Special Types

- `Types.Bool` - Boolean value (1 byte)
- `Types.Void` - Empty table (0 bytes)
- `Types.Nil` - Nil value (0 bytes)
- `Types.Any` - Any type (dynamic, includes type information)

### Roblox Types

| Type | Description | Size |
|------|-------------|------|
| `Types.Vector3` | Full precision Vector3 | 12 bytes |
| `Types.Vector3F24` | Reduced precision Vector3 | 9 bytes |
| `Types.Vector3int16` | Integer Vector3 | 6 bytes |
| `Types.Vector2` | Full precision Vector2 | 8 bytes |
| `Types.Vector2F24` | Reduced precision Vector2 | 6 bytes |
| `Types.Vector2int16` | Integer Vector2 | 4 bytes |
| `Types.Vector` | Full precision vector (Luau native vector type) | 12 bytes |
| `Types.VectorF24` | Reduced precision vector | 9 bytes |
| `Types.VectorInt16` | Integer vector | 6 bytes |
| `Types.CFrame` | Full precision CFrame | 48 bytes |
| `Types.CFrameQ` | Quaternion CFrame | 28 bytes |
| `Types.Color3` | RGB color | 3 bytes |
| `Types.Enum` | Enum value (requires Enum parameter) | 2 bytes |
| `Types.Instance` | Roblox Instance (requires ClassName) | Variable |

### Collection Types

#### `Types.Array(elementType)`

Creates a variable-size array type with 16-bit length prefix (max 65,535 elements).

```luau
local NumberArray = Types.Array(Types.Int32)
local VectorArray = Types.Array(Types.Vector3)
```

#### `Types.ArrayTiny(elementType)`

Creates a compact array type with 8-bit length prefix (max 255 elements).

```luau
local SmallArray = Types.ArrayTiny(Types.Float32)
```

#### `Types.ArrayFixed(elementType, length)`

Creates a fixed-size array with no length prefix.

```luau
local FixedArray = Types.ArrayFixed(Types.Int32, 10) -- Exactly 10 elements
```

#### `Types.Map(keyType, valueType)`

Creates a map/dictionary type with 16-bit length prefix (max 65,535 entries).

```luau
local StringToIntMap = Types.Map(Types.String, Types.Int32)
local IdToPlayerMap = Types.Map(Types.Int32, Types.String)
```

#### `Types.MapFixed(keyType, valueType, length)`

Creates a fixed-size map with no length prefix.

```luau
local FixedMap = Types.MapFixed(Types.String, Types.Bool, 10) -- Exactly 10 entries
```

#### `Types.Struct(schema)`

Creates a fixed structure with named fields.

```luau
local PlayerData = Types.Struct({
    Name = Types.String,
    Level = Types.Int32,
    Position = Types.Vector3,
    Inventory = Types.Array(Types.String)
})
```

#### `Types.Optional(type)`

Makes a type optional (nullable).

```luau
local OptionalString = Types.Optional(Types.String)
local OptionalInt = Types.Optional(Types.Int32)
```

#### `Types.BoolPacked`

Creates an array of exactly 8 booleans, each taking 1 bit of memory (totals 1 byte).

```luau
local PackedBools = Types.BoolPacked
-- Serialize: {true, false, true, false, true, false, true, false}
```

#### `Types.Bits._8(count)`, `Types.Bits._16(count)`, `Types.Bits._32(count)`

Creates a fixed-size array of bit values (8-bit, 16-bit, or 32-bit unsigned integers).

```luau
local Bits8 = Types.Bits._8(4)  -- Array of 4 bytes (8-bit values)
local Bits16 = Types.Bits._16(2) -- Array of 2 shorts (16-bit values)
local Bits32 = Types.Bits._32(1) -- Array of 1 int (32-bit values)
```

#### `Types.Enum(EnumType)`

Serializes an EnumItem value. Requires the Enum type as a parameter.

```luau
local MaterialEnum = Types.Enum(Enum.Material)
local HumanoidStateEnum = Types.Enum(Enum.HumanoidStateType)

-- Serialize
local b = Serializer:serialize(nil, Enum.Material.Plastic)

-- Deserialize
local material = Serializer:deserialize(nil, b)
```

#### `Types.Instance(ClassName)`

Serializes a Roblox Instance by its properties. Requires pre-defined serialization schemas for each class.

**Currently supported classes:**

- `Part` - Serializes Name, CFrame, Color, Transparency, Material, CanCollide, CanTouch, CanQuery, CastShadow
- `MeshPart` - Same properties as Part

```luau
-- Static serialization
local PartSerializer = VoidSentry.Static.new(nil, Types.Instance("Part"))

local part = Instance.new("Part")
part.Name = "MyPart"
part.CFrame = CFrame.new(10, 5, 0)
part.Color = Color3.new(1, 0, 0)
part.Transparency = 0.5

local b = PartSerializer:serialize(nil, part)

-- Deserialize creates a new Instance with the serialized properties
local deserializedPart = PartSerializer:deserialize(nil, b)
```

**Dynamic serialization** also supports Instance types:

```luau
local part = workspace.SomePart
local b = VoidSentry.Dynamic.serialize(nil, nil, part)
local deserializedPart = VoidSentry.Dynamic.deserialize(nil, nil, b)
```

> **Note:** The Instance type creates new instances on deserialization. It does not preserve parent-child relationships or references to other instances. For custom classes, you can extend the serialization data in `src/sections/types/instance/serialize_data.luau`.

## Usage Examples

### Example 1: Player Data Replication

```luau
local PlayerDataSerializer = VoidSentry.Static.new(
    5, -- Compression level 5
    Types.Struct({
        UserId = Types.Int32,
        Username = Types.String,
        Position = Types.Vector3,
        Health = Types.Float32,
        Inventory = Types.Array(Types.String),
        Level = Types.Int32,
        Premium = Types.Bool
    })
)

local data = {
    UserId = 123456,
    Username = "Player123",
    Position = Vector3.new(100, 50, 200),
    Health = 75.5,
    Inventory = {"Sword", "Shield", "Potion"},
    Level = 42,
    Premium = true
}

local b = PlayerDataSerializer:serialize(nil, data)
-- Send buffer over RemoteEvent
```

### Example 2: Game State Snapshot

```luau
local GameStateSerializer = VoidSentry.Static.new(
    nil, -- No compression for speed
    Types.Int32, -- Timestamp
    Types.Array(Types.Struct({
        PlayerId = Types.Int32,
        Position = Types.Vector3F24, -- Reduced precision
        Rotation = Types.CFrameQ, -- Compact CFrame
    })),
    Types.Map(Types.String, Types.Int32) -- Entity counts
)

local timestamp = os.time()
local players = {
    {PlayerId = 1, Position = Vector3.new(0, 5, 0), Rotation = CFrame.new()},
    {PlayerId = 2, Position = Vector3.new(10, 5, 10), Rotation = CFrame.new()},
}
local entityCounts = {
    Zombies = 15,
    Treasure = 3,
}

local b = GameStateSerializer:serialize(nil, timestamp, players, entityCounts)
```

### Example 3: Dynamic Configuration

```luau
-- When you don't know the data structure ahead of time
local config = {
    maxPlayers = 50,
    mapName = "Desert Arena",
    spawnPoint = Vector3.new(0, 10, 0),
    enablePvP = true,
    difficulty = 2.5
}

local b = VoidSentry.Dynamic.serialize(10, nil, config)

-- Later, deserialize
local loadedConfig = VoidSentry.Dynamic.deserialize(10, nil, b)
```

## Performance Tips

1. **Use Static Serializer When Possible**: It's significantly faster than dynamic serialization
2. **Choose Appropriate Types**: Use `Vector3F24` instead of `Vector3` if you don't need full precision
3. **Compression Trade-offs**: Compression reduces bandwidth but increases CPU usage
4. **Batch Serialization**: Serialize multiple values at once rather than separately
5. **Reuse Serializers**: Create serializer objects once and reuse them
6. **Use Tiny Variants**: `StringTiny` and `ArrayTiny` save bytes for small data
7. **Select Appropriate Numeric Types**: Use `Int16` or `Int8` when values fit in smaller ranges

## Advanced Features

### Custom Offsets

You can specify a starting offset to write data at specific positions:

```luau
-- Write at offset 20
local b = Serializer:serialize(20, myData)
print(buffer.len(b)) -- Buffer has 20 extra bytes at the beginning for custom use
```

### Compression Levels

Zstd compression levels (-7 to 22):

- **-7 to 3**: Fast compression, lower ratio
- **5 to 10**: Balanced (recommended)
- **15 to 22**: Maximum compression, slower

## Contributing

Contributions are welcome! Please feel free to submit issues or pull requests.

## License

This project is licensed under the Apache 2.0 License. See the [LICENSE](LICENSE) file for details.

## Author

**IAMNOTULTRA3** (a.k.a elentium/elite)

## Support

For questions, issues, or feature requests, please open an issue on the repository or contact the author.
