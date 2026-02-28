local type_node_export = require("../exports/type_node")

type TypeNode = type_node_export.typeNode

return function<T>(Struct: { [any]: TypeNode } & T)
	return {
		name = "struct",
		_schema = Struct, -- expose schema for Instance type iteration
		write = @native function(value: { [any]: any }): ()
			for k, v in Struct :: { [any]: TypeNode } do
				v.write((value :: { [any]: TypeNode })[k])
			end
		end,

		read = @native function(b: buffer, cursor: number): ({ [any]: TypeNode }, number)
			local value = {}
			for k, v in Struct :: { [any]: TypeNode } do
				value[k], cursor = v.read(b, cursor)
			end
			return value, cursor
		end,
	}
end
