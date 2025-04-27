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

_G.IsExperimentalReplicator = true

local IsServer = game:GetService("RunService"):IsServer()

if not _G.IsExperimentalReplicator then
    return (
        if IsServer
            then require(script.Server) :: ServerReplicator
            else require(script.Client) :: ClientReplicator
    ) :: ServerReplicator | ClientReplicator
else
    return {
        Types = Types,
        Server = (if IsServer then require(script.Server) else { NewReplica = function(_: Types.Config) Logger("Warn", "Attempting to call Server function on the Client~") end}) :: ServerReplicator,
        Client = (if not IsServer then require(script.Client) else { ListenToNewReplica = function(_: string, _: (ClientReplica) -> ()) Logger("Warn", "Attempting to call Client function on the Server!") end}) :: ClientReplicator,
    }
end
