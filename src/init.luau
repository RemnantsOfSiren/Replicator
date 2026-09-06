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

export type Replica<T = any> = Types.Replica<T>
export type ServerReplica<T = any> = Types.ServerReplica<T>
export type ClientReplica<T = any> = Types.ClientReplica<T>

export type Config<T = any> = Types.Config<T>
export type ServerConfig<T = any> = Types.ServerConfig<T>
export type ClientConfig<T = any> = Types.ClientConfig<T>

export type ReplicatedTable<T = any> = Types.ReplicatedTable<T>
export type Connection = Types.Connection
export type ValidPath = Types.ValidPath
export type ToOptions = Types.ToOptions

return {
	Server = require(script.Server),
	Client = require(script.Client)
}