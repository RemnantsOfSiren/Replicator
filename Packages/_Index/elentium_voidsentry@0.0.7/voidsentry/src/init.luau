--[[
	VoidSentry V0.0.7

	Copyright 2026 IAMNOTULTRA3

	Apache 2.0 License
]]
--!strict
--!optimize 2

local export_type_node = require("@self/sections/exports/type_node")

export type DynamicSerializer = {
	serialize: (compressLevel: number?, offset: number?, ...any) -> buffer,
	deserialize: (compressLevel: number?, offset: number?, b: buffer) -> ...any,
}

type SerializeFn<T...> = (self: StaticObject<T...>, offset: number?, T...) -> buffer
type DeserializeFn<T...> = (self: StaticObject<T...>, offset: number?, b: buffer) -> T...

export type StaticObject<T...> = {
	schema: { export_type_node.typeNode },
	compressionLevel: number?,
	serialize: SerializeFn<T...>,
	deserialize: DeserializeFn<T...>,
}

export type StaticSerializer = {
	new: <T...>(compressionLevel: number?, T...) -> StaticObject<T...>,
}

local VoidSentry = {
	Static = (require("@self/sections/static_serializer") :: any) :: StaticSerializer,
	Dynamic = (require("@self/sections/dynamic_serializer") :: any) :: DynamicSerializer,
	Types = {
		Void = (require("@self/sections/types/void") :: any) :: { nil },
		Nil = (require("@self/sections/types/nil") :: any) :: nil,
		Int32 = (require("@self/sections/types/int32") :: any) :: number,
		Int16 = (require("@self/sections/types/int16") :: any) :: number,
		Int8 = (require("@self/sections/types/int8") :: any) :: number,
		UInt32 = (require("@self/sections/types/uint32") :: any) :: number,
		UInt16 = (require("@self/sections/types/uint16") :: any) :: number,
		UInt8 = (require("@self/sections/types/uint8") :: any) :: number,
		Float64 = (require("@self/sections/types/float64") :: any) :: number,
		Float32 = (require("@self/sections/types/float32") :: any) :: number,
		Float24 = (require("@self/sections/types/float24") :: any) :: number,
		Bool = (require("@self/sections/types/bool") :: any) :: boolean,
		BoolPacked = (require("@self/sections/types/boolean_packed") :: any) :: { boolean },
		String = (require("@self/sections/types/string") :: any) :: string,
		StringTiny = (require("@self/sections/types/string_tiny") :: any) :: string,
		StringFixed = (require("@self/sections/types/string_fixed") :: any) :: (len: number) -> string,
		StringNullTerminated = (require("@self/sections/types/string_null_terminated") :: any) :: string,
		Array = (require("@self/sections/types/array") :: any) :: <T>(ElementsType: T) -> { T },
		ArrayTiny = (require("@self/sections/types/array_tiny") :: any) :: <T>(ElementsType: T) -> { T },
		Map = (require("@self/sections/types/map") :: any) :: <K, V>(KeyType: K, ValueType: V) -> { [K]: V },
		Struct = (require("@self/sections/types/struct") :: any) :: <T>(Struct: T) -> T,
		ArrayFixed = (require("@self/sections/types/array_fixed") :: any) :: <T>(ElementsType: T, len: number) -> { T },
		MapFixed = (
				require("@self/sections/types/map_fixed") :: any
			) :: <K, V>(KeyType: K, ValueType: V, len: number) -> { [K]: V },
		Any = require("@self/sections/types/any") :: any,
		Vector3 = (require("@self/sections/types/vector3") :: any) :: Vector3,
		Vector3F24 = (require("@self/sections/types/vector3_f24") :: any) :: Vector3,
		Vector3int16 = (require("@self/sections/types/vector3_int16") :: any) :: Vector3int16,
		Vector2 = (require("@self/sections/types/vector2") :: any) :: Vector2,
		Vector2F24 = (require("@self/sections/types/vector2_f24") :: any) :: Vector2,
		Vector2int16 = (require("@self/sections/types/vector2_int16") :: any) :: Vector2int16,
		CFrame = (require("@self/sections/types/cframe") :: any) :: CFrame,
		CFrameQ = (require("@self/sections/types/cframe_q") :: any) :: CFrame,
		Color3 = (require("@self/sections/types/color3") :: any) :: Color3,
		Vector = (require("@self/sections/types/vector") :: any) :: vector,
		VectorF24 = (require("@self/sections/types/vector_f24") :: any) :: vector,
		VectorInt16 = (require("@self/sections/types/vector_int16") :: any) :: vector,
		Optional = (require("@self/sections/types/optional") :: any) :: <T>(Type: T) -> T?,
		Bits = (require("@self/sections/types/bits") :: any) :: {
			_8: (count: number) -> { number },
			_16: (count: number) -> { number },
			_32: (count: number) -> { number },
		},
		Enum = (require("@self/sections/types/enum") :: any) :: <T>(Enum: T & Enum) -> T,
		Instance = (require("@self/sections/types/instance") :: any) :: (ClassName: string) -> Instance,
	},
}

return VoidSentry
