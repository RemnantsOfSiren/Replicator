--!strict
local Types = require(script.Parent.Types)

return function(Path: Types.ValidPath): { string | number }
	if typeof(Path) == "string" then
		if Path:find(".") then
			return Path:split(".")
		elseif Path:find("/") then
			return Path:split("/")
		else
			return { Path }
		end
	end

	return Path :: { string | number }
end
