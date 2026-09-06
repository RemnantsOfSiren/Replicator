--!strict
local Types = require(script.Parent.Types)

return function(Path: Types.ValidPath): { string | number }
	if typeof(Path) == "string" then
		if Path:find(".", 1, true) then
			return Path:split(".") :: { string | number }
		elseif Path:find("/") then
			return Path:split("/") :: { string | number }
		else
			return { Path }
		end
	end

	return Path :: { string | number }
end
