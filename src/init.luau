local Types = require(script.Types)
local Logger = require(script.Logger)

--[=[
    @class Replica
]=]

--[=[
    @class Replicator
]=]

export type ServerReplicator = Types.ServerReplicator
export type ClientReplicator = Types.ClientReplicator

export type ServerReplica = Types.ServerReplica
export type ClientReplica = Types.ClientReplica

return (
	if game:GetService("RunService"):IsServer()
		then require(script.Server) :: ServerReplicator
		else require(script.Client) :: ClientReplicator
) :: ServerReplicator | ClientReplicator
-- local IsServer = game:GetService("RunService"):IsServer()

-- return {
--     Server = (if IsServer then require(script.Server) else { NewReplica = function(_: Types.Config) Logger("Warn", "Attempting to call Server function on the Client~") end}) :: ServerReplicator,
--     Client = (if not IsServer then require(script.Client) else { ListenToNewReplica = function(_: string, _: (ClientReplica) -> ()) Logger("Warn", "Attempting to call Client function on the Server!") end}) :: ClientReplicator,
-- }
