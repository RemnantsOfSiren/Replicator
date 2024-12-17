local ByteNet = require(script.Parent.Parent.ByteNet)

return ByteNet.defineNamespace("Replication", function()
	local Replica = ByteNet.struct({
		Id = ByteNet.string,
		Name = ByteNet.string,
		Tags = ByteNet.optional(ByteNet.array(ByteNet.unknown)),
		Data = ByteNet.optional(ByteNet.unknown),
		WriteLib = ByteNet.optional(ByteNet.inst),
		Parent = ByteNet.optional(ByteNet.string),
		IsParent = ByteNet.optional(ByteNet.bool),
	})

	return {
		createReplica = ByteNet.definePacket({
			value = Replica,
		}),

		getInitialReplicas = ByteNet.definePacket({
			value = ByteNet.optional(ByteNet.array(Replica)),
		}),

		replicateChanges = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.string,
				Changes = ByteNet.array(ByteNet.struct({
					Time = ByteNet.float64,
					Path = ByteNet.array(ByteNet.unknown),
					Value = ByteNet.unknown,
				})),
			}),
		}),

		fireEvent = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.string,
				Args = ByteNet.array(ByteNet.unknown),
			}),
		}),

		changeParent = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.string,
				Parent = ByteNet.string,
			}),
		}),

		destroyReplica = ByteNet.definePacket({
			value = ByteNet.string,
		}),

		replicateWrite = ByteNet.definePacket({
			value = ByteNet.struct({
				Id = ByteNet.string,
				Method = ByteNet.string,
				Args = ByteNet.array(ByteNet.unknown),
			}),
		}),
	}
end)
