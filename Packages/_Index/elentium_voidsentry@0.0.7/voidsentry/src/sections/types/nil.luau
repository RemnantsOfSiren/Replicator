return {
	name = "nil",
	write = function(value: nil): ()
		-- nil writes nothing
	end,
	read = function(b: buffer, cursor: number): (nil, number)
		return nil, cursor
	end,
}
