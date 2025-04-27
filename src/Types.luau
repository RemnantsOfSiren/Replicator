local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

type Signal = typeof(Signal.new())
type Cleaner = typeof(Trove.new())

export type ValidPath = { string | number } | string | number
export type ToOptions = { Player } | Player | "All"

export type Hook = (
	self: Replica,
	Path: ValidPath,
	Callback: (...any) -> nil,
	SuppressOld: boolean?
) -> { Disconnect: () -> nil }

export type Replica = {
	Id: string,
	Name: string,
	Tags: { any }?,
	__OldData: { [string | number]: any }?,

	WriteLib: ModuleScript?,
	__WriteLib: { [any]: any }?,

	__Fired: Signal,
	__Write: Signal,
	__Change: Signal,
	__Cleaner: Cleaner,
	Destroying: Signal,

	ListenToWrite: Hook?,
	ListenToChange: Hook?,
	ListenToNewKey: Hook?,
	AddCleanupMethod: (self: Replica, Method: any, CleanupMethod: any?) -> any,
	ListenToKeyRemoved: Hook?,
}

export type ReplicaTable = typeof(setmetatable({}, {})) & {
	Get: (self: ReplicaTable) -> any,
	Insert: (self: ReplicaTable, Key: (string | number)?, Value: any) -> nil,
	Remove: (self: ReplicaTable, Key: string | number) -> nil,
}

export type RemoteEvent = {
	fire: (Player: Player, Packet: { [any]: any }) -> nil,
	fireAll: (Packet: { [any]: any }) -> nil,
	fireList: (Players: { Player }, Packet: { [any]: any }) -> nil,
}

export type ServerReplica = Replica & {
	Data: ReplicaTable,
	__Fire: (Event: RemoteEvent, Packet: { [any]: any }) -> nil,
	__Ready: boolean?,
	__Changes: { [any]: any },
	__IsParent: boolean?,
	__ReplicateToChanged: Signal,

	To: ToOptions?,
	Parent: ServerReplica?,

	Write: (self: ServerReplica, Method: string, ...any) -> ...any,
	Destroy: (self: ServerReplica) -> nil,
	SetValue: (self: ServerReplica, Path: ValidPath, Value: any) -> nil,
	SetParent: (self: ServerReplica, Parent: ServerReplica?) -> nil,
	DestroyFor: (self: ServerReplica, Player: Player) -> nil,
	ReplicateFor: (self: ServerReplica, Player: Player) -> nil,
}

export type ClientReplica = Replica & {
	Data: { [string | number]: any }?,
	Parent: ClientReplica?,
	Destroy: (self: ClientReplica) -> nil,
}

export type Packet = {
	Id: string,
	Changes: {
		[number]: { Time: number, Path: { string | number }, Value: any },
	},
}

export type Config = {
	Name: string,
	Tags: { any }?,
	Data: { [string | number]: any }?,
	WriteLib: ModuleScript?,
	IsParent: boolean?,
}

export type ServerConfig = Config & {
	To: ToOptions,
	Parent: ServerReplica?,
}

export type ClientConfig = Config & {
	Id: string,
	Parent: string?,
}

export type ServerReplicator = {
	NewReplica: (Config: Config) -> ServerReplica,
}

export type ClientReplicator = {
	ListenToNewReplica: (Name: string, Callback: (Replica: ClientReplica) -> nil) -> { Disconnect: () -> nil },
}

return {}
