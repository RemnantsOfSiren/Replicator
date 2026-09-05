--!strict
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

export type Config = Types.Config
export type ServerConfig = Types.ServerConfig
export type ClientConfig = Types.ClientConfig

export type ReplicatedTable = Types.ReplicatedTable
export type Connection = Types.Connection
export type ValidPath = Types.ValidPath
export type ToOptions = Types.ToOptions

local IsServer = game:GetService("RunService"):IsServer()

return {
	Server = (if IsServer
		then require(script.Server)
		else {
			NewReplica = function(_: Types.Config)
				Logger("Warn", "Attempting to call Server function on the Client!")
				return nil
			end,
		}) :: ServerReplicator,
	Client = (if not IsServer
		then require(script.Client)
		else {
			ListenToNewReplica = function(_Name: string, _Callback: (ClientReplica) -> ())
				Logger("Warn", "Attempting to call Client function on the Server!")
				return function() end
			end,
		}) :: ClientReplicator,
}