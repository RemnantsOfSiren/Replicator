return {
	name = "void",
	write = function(value: {}): ()
		-- void writes nothing
	end,
	read = function(b: buffer, cursor: number): ({}, number)
		return {}, cursor
	end,
}
