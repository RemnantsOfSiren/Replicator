--!strict
local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

type Signal = typeof(Signal.new())
type Cleaner = typeof(Trove.new())

export type ValidPath = { string | number } | string | number
export type ToOptions = { Player } | Player | "All"

-- The object returned by any of the `ListenTo*` / `ObserveChange` methods.
-- Call `:Disconnect()` on it to stop listening.
export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Replica<T = any> = {
	Id: string,
	Name: string,
	Tags: { any }?,
	__OldData: T?,

	WriteLib: ModuleScript?,
	__WriteLib: { [any]: any }?,

	__Fired: Signal,
	__Write: Signal,
	__Change: Signal,
	__Cleaner: Cleaner,
	Destroying: Signal,

	ListenToRaw: (self: Replica<T>, Callback: (...any) -> nil) -> Connection,
	ObserveChange: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> nil) -> Connection,
	ListenToChange: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> nil, SuppressOld: boolean?) -> Connection,
	ListenToNewKey: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> nil) -> Connection,
	AddCleanupMethod: (self: Replica<T>, Method: any, CleanupMethod: any?) -> any,
	ListenToKeyRemoved: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> nil) -> Connection,
}

export type ReplicatedTable<T = any> = typeof(setmetatable(
	{} :: {
		__type: "ReplicatedTable",
		__value: { [any]: any } & T,
		__table: T,
		__onChange: (Path: { [number]: { Key: string, IsNumber: boolean } }, Value: any, Action: string) -> nil,
		__oldtable: { [any]: any },
		__indicies: { string | number }?,
		Get: (self: ReplicatedTable<T>) -> any,
		Insert: (self: ReplicatedTable<T>, Key: (string | number)?, Value: any) -> nil,
		Remove: (self: ReplicatedTable<T>, Key: string | number) -> nil,
	},
{}))

export type RemoteEvent = {
	fire: (Player: Player, Packet: { [any]: any }) -> nil,
	fireAll: (Packet: { [any]: any }) -> nil,
	fireList: (Players: { Player }, Packet: { [any]: any }) -> nil,
}

export type ServerReplica<T = any> = Replica<T> & {
	Data: ReplicatedTable<T>,
	__Fire: (Event: RemoteEvent, Packet: { [any]: any }) -> nil,
	__Ready: boolean?,
	__Parent: ServerReplica<T>?,
	__IsParent: boolean?,
	__ReplicateToChanged: Signal,

	To: ToOptions?,
	Parent: ServerReplica<T>?,

	Fire: (self: ServerReplica<T>, ...any) -> (),
	Write: (self: ServerReplica<T>, Method: string, ...any) -> ...any,
	Destroy: (self: ServerReplica<T>) -> nil,
	SetValue: (self: ServerReplica<T>, Path: ValidPath, Value: any) -> nil,
	SetParent: (self: ServerReplica<T>, Parent: ServerReplica<T>?) -> nil,
	DestroyFor: (self: ServerReplica<T>, Player: Player) -> nil,
	GetChildren: (self: ServerReplica<T>) -> { [string]: ServerReplica<T> },
	ReplicateFor: (self: ServerReplica<T>, Player: Player) -> nil,
	OnServerEvent: (self: ServerReplica<T>, Callback: (Player: Player, ...any) -> nil) -> Connection,
}

export type ClientReplica<T = any> = Replica<T> & {
	Data: T?,
	Parent: ClientReplica<T>?,
	__IsParent: boolean?,
	__Parent: ClientReplica<T>?,

	Write: (self: ClientReplica<T>, Method: string, Callback: (...any) -> nil) -> Connection,
	Fire: (self: ClientReplica<T>, ...any) -> (),
	Destroy: (self: ClientReplica<T>) -> nil,
	GetChildren: (self: ClientReplica<T>) -> { [string]: ClientReplica<T> },
	OnClientEvent: (self: ClientReplica<T>, Callback: (...any) -> nil) -> Connection,
}

export type PacketKey = {
	Key: string,
	IsNumber: boolean,
}

export type ChangePacket = {
	Path: { [number]: PacketKey },
    Value: unknown?,
    Action: string,
}

export type Packet = {
	Id: string,
	Changes: { ChangePacket },
}

export type Config<T = any> = {
	Id: string?,
	To: ToOptions?,
	Name: string,
	Tags: { any }?,
	Data: T?,
	WriteLib: ModuleScript?,
	IsParent: boolean?,
}

export type ServerConfig = Config<any> & {
	To: ToOptions,
	Parent: ServerReplica<any>?,
}

export type ClientConfig = Config<any> & {
	Id: string,
	Parent: string?,
}

export type ServerReplicator = {
	NewReplica: <T>(Config: Config<T>) -> ServerReplica<T>?,
}

export type ClientReplicator = {
	ListenToNewReplica: <T>(Name: string, Callback: (Replica: ClientReplica<T>) -> nil) -> () -> (),
}

return {}
