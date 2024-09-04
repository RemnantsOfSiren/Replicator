return function(ObjectToParse: { string | number } | string)
	return (if typeof(ObjectToParse) == "string"
			then string.split(
				ObjectToParse,
				(string.find(ObjectToParse, "%.") and "%.") or (string.find(ObjectToParse, "/") and "/")
			)
			else ObjectToParse) :: { any }
end