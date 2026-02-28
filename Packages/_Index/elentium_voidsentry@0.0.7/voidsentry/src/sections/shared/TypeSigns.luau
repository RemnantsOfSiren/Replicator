local TypeSigns = {
	-- each type sign is 1 byte
	-- integer number (4 bytes)
	INT32 = 1,
	-- float number (4 bytes)
	FLOAT32 = 2,
	-- boolean (1 byte)
	BOOL = 3,
	-- string (2 + len bytes)
	STRING = 4,
	-- array (2 bytes(length count) + elem1Bytes + elem2Bytes + elem3Bytes + ...)
	ARRAY = 5,
	-- map (2 bytes(length count) + key1Bytes + value1Bytes + key2Bytes + value2Bytes + ...)
	MAP = 6,
	-- nil (0 bytes)
	NIL = 7,
	-- void: an empty table (0 bytes)
	VOID = 8,
	-- string (1 + len bytes)
	STRING_TINY = 9,
	-- array (1 bytes(length count) + elem1Bytes + elem2Bytes + elem3Bytes + ...)
	ARRAY_TINY = 10,
	-- small int(2 bytes)
	INT16 = 11,
	-- unknown type (0 bytes)
	UNKNOWN = 12,
	-- any type (dynamic, writes its own type sign + value)
	ANY = 13,
	-- vector3 (12 bytes - 3 floats)
	VECTOR3 = 14,
	-- vector2 (8 bytes - 2 floats)
	VECTOR2 = 15,
	-- cframe (48 bytes - full precision)
	CFRAME = 16,
	-- color3 (3 bytes - RGB)
	COLOR3 = 17,
	-- vector3int16 (6 bytes - 3 shorts)
	VECTOR3_INT16 = 18,
	-- vector2int16 (4 bytes - 2 shorts)
	VECTOR2_INT16 = 19,
	-- vector (12 bytes - 3 floats, Luau native vector type)
	VECTOR = 20,
	-- vectorF24 (9 bytes - 3 f24)
	VECTOR_F24 = 21,
	-- vectorInt16 (6 bytes - 3 shorts)
	VECTOR_INT16 = 22,
	-- bits (variable - array of bit values)
	BITS = 23,
	-- enum (2 bytes - enum value)
	ENUM = 24,
	-- instance (variable - class name + struct data)
	INSTANCE = 25,
}

-- create reverse mapping (number -> name) for deserialization
local TypeSignsReverse: { [number]: string } = {}
for name, sign in TypeSigns do
	TypeSignsReverse[sign] = name
end

TypeSigns.Reverse = TypeSignsReverse

return TypeSigns
