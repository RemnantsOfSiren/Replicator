return {
	name = "unknown",
	write = function(value: unknown): never
		error(`Unknown type detected`)
	end,
	read = function(b: buffer, cursor: number): never
		error(`Unknown type detected`)
	end,

	transfer = true,
}
