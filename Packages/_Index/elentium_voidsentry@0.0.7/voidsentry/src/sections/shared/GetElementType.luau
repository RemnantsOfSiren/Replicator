-- localize
local math_floor = math.floor

local signed_int_max = 2 ^ 31 - 1
local signed_int_min = -2 ^ 31
local signed_short_max = 2 ^ 15 - 1
local signed_short_min = -2 ^ 15

return function(Element: any): string
	local elemType = typeof(Element)

	if elemType == "number" then
		-- determine whether it is a float or an int
		-- check if it's an integer first (fast path)
		if math_floor(Element) == Element then
			-- check if it fits in int range
			if Element >= signed_int_min and Element <= signed_int_max then
				-- check if it fits in short range (more common)
				if Element >= signed_short_min and Element <= signed_short_max then
					return "INT16"
				end
				return "INT32"
			end
		end
		return "FLOAT32"
	elseif elemType == "boolean" then
		return "BOOL"
	elseif elemType == "string" then
		return "STRING"
	elseif elemType == "Vector3" then
		return "VECTOR3"
	elseif elemType == "Vector2" then
		return "VECTOR2"
	elseif elemType == "CFrame" then
		return "CFRAME"
	elseif elemType == "Color3" then
		return "COLOR3"
	elseif elemType == "Vector3int16" then
		return "VECTOR3_INT16"
	elseif elemType == "Vector2int16" then
		return "VECTOR2_INT16"
	elseif elemType == "vector" then
		return "VECTOR"
	elseif elemType == "EnumItem" then
		return "ENUM"
	elseif elemType == "Instance" then
		return "INSTANCE"
	elseif elemType == "table" then
		local is_empty = next(Element) == nil
		if is_empty then
			return "VOID"
		end

		if #Element == 0 then
			return "MAP"
		end
		return (#Element > 255 and "ARRAY" or "ARRAY_TINY")
	elseif Element == nil then
		return "NIL"
	else
		return "UNKNOWN"
	end
end
