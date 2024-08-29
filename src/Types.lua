
local Types = {}

local Trove = require(script.Parent.Parent.Trove) :: { any }

export type ReplicateTo = { Player } | Player | "All"

export type Indices = { string | number } | string | number
type Listener = (ClientReplica, Indices, (Indices, any, any) -> ()) -> (RBXScriptConnection)

export type Signal = {
	Connect: RBXScriptConnection,
}
export type Cleaner = typeof(Trove.new())

export type ClientWriteLib = {[string]: (ClientReplica, any) -> (any)}
export type ServerWriteLib = {[string]: (ServerReplica, any) -> (any)}

export type ClientReplica = {
	WriteFunctionFlag: boolean,
	WriteLib: ClientWriteLib?,
	Id: string,
	Tags: {any},
	Data: {any},

	ConnectOnClientEvent: (ClientReplica, (...any) -> ()) -> (() -> ()),
	AddCleanupTask: (ClientReplica, () -> nil) -> (),
	Update: (self: ClientReplica, Indices, any, any) -> (),
	Changed: Signal,
	Destroying: Signal,
	Cleaner: Cleaner,

	ListenToWrite: Listener,
	ListenToChange: Listener,
	ListenToNewKey: Listener,
	ListenToKeyRemoved: Listener,

	FireServer: (...any) -> (),
	Destroy: (ClientReplica) -> (),

	Set: () -> (), -- useless
	
	_Callbacks: {[string]: {(any) -> (any)}},
	_WriteCallbacks: {[string]: {(any) -> (any)}}
}

export type ReplicaConfig = {
	Name: string,
	Tags: { any }?,
	Data: { any },
	To: ReplicateTo,
}

export type ServerReplica = {
	Name: string,
	To: ReplicateTo,
	Tags: {any},
	Data: {any},
	WriteLibModule: ModuleScript?,
	WriteLib: ServerWriteLib?,
	ServerEvents: {(...any) -> ()},

	Changed: Signal,
	Destroying: Signal,

	ConnectOnServerEvent: (self: ServerReplica, Callback: (...any) -> ()) -> (() -> ()),
	AddCleanupTask: (self: ServerReplica, CallbackOrObject: any, Method: string?) -> (),
	Write: (self: ServerReplica, Method: string, ...any) -> (any),
	Set: (self: ServerReplica, Indices: Indices, Value: any) -> (),
	ListenToChange: Listener,
	ListenToNewKey: Listener,
	ListenToKeyRemoved: Listener,
	Cleaner: Cleaner,
	FireClient: (Player: Player, ...any) -> (),
	FireAllClients: (...any) -> (),
	Destroy: (self: ServerReplica) -> ()
}

return Types