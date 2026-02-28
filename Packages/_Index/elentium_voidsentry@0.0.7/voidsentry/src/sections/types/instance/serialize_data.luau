--!strict
-- Import types directly to avoid circular dependency
local type_node = require(script.Parent.Parent.Parent.exports.type_node)
local struct = require(script.Parent.Parent.struct)
local string = require(script.Parent.Parent.string)
local cframe = require(script.Parent.Parent.cframe)
local color3 = require(script.Parent.Parent.color3)
local float32 = require(script.Parent.Parent.float32)
local enum = require(script.Parent.Parent.enum)
local bool = require(script.Parent.Parent.bool)

type TypeNode = type_node.typeNode

local BasePart = struct({
	Name = string,
	CFrame = cframe,
	Color = color3,
	Transparency = float32,
	Material = enum(Enum.Material),
	CanCollide = bool,
	CanTouch = bool,
	CanQuery = bool,
	CastShadow = bool,
})

-- Define schemas using direct module imports
-- Each schema defines the properties to serialize for each class
return {
	Part = BasePart,
	MeshPart = BasePart,
} :: { [string]: TypeNode }
