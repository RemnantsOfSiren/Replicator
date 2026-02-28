--[[
	@description: Validation level is a number that determines the level of validation that will be performed on the data.
	@levels:
	0 - No validation
	1 - Basic validation(schema size, value type validation)
	2 - Deep validation(every type is strictly checked, buffer out-of-bounds checks, etc)
]]
return {
	VALIDATION_LEVEL = 2,
}
