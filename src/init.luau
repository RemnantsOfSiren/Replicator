local Types = require(script.Types)

--[=[
    @class Replica
]=]

--[=[
    @class Replicator
]=]

export type ServerReplica = Types.ServerReplica
export type ClientReplica = Types.ClientReplica

return (
	if game:GetService("RunService"):IsServer() then require(script.Server) else require(script.Client)
) :: Types.ServerReplicator | Types.ClientReplicator
