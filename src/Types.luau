--!strict
local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

type Signal = typeof(Signal.new())
type Cleaner = typeof(Trove.new())

export type ValidPath = { string | number } | string | number
export type ToOptions = { Player } | Player | "All"

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

	ListenToRaw: (self: Replica<T>, Callback: (...any) -> ()) -> Connection,
	ObserveChange: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> ()) -> Connection,
	ListenToChange: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> (), SuppressOld: boolean?) -> Connection,
	ListenToNewKey: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> ()) -> Connection,
	AddCleanupMethod: (self: Replica<T>, Method: any, CleanupMethod: any?) -> any,
	ListenToKeyRemoved: (self: Replica<T>, Path: ValidPath, Callback: (...any) -> ()) -> Connection,
}

export type ReplicatedTable<T = any> = typeof(setmetatable(
	{} :: {
		[any]: any,
		__type: "ReplicatedTable",
		__value: { [any]: any } & T,
		__table: T,
		__onChange: (Path: { PacketKey }, Value: any, Action: string) -> (),
		__oldtable: { [any]: any },
		__indicies: { string | number }?,
		Get: (self: ReplicatedTable<T>) -> T,
		Insert: (self: ReplicatedTable<T>, IndexOrValue: any, Value: any?) -> (),
		Remove: (self: ReplicatedTable<T>, Index: number) -> (),
		Destroy: (self: ReplicatedTable<T>) -> (),
	},
	{} :: {
		__iter: (self: ReplicatedTable<T>) -> () -> (any, any, (Value: any) -> ()),
	}
))

export type RemoteEvent = {
	fire: (Player: Player, Packet: { [any]: any }) -> (),
	fireAll: (Packet: { [any]: any }) -> (),
	fireList: (Players: { Player }, Packet: { [any]: any }) -> (),
}

export type ServerReplica<T = any> = Replica<T> & {
	Data: ReplicatedTable<T>,
	__Fire: (Event: RemoteEvent, Packet: { [any]: any }) -> (),
	__Ready: boolean?,
	__Parent: ServerReplica<T>?,
	__IsParent: boolean?,
	__ReplicateToChanged: Signal,

	To: ToOptions?,
	Parent: ServerReplica<T>?,

	Fire: (self: ServerReplica<T>, ...any) -> (),
	Write: (self: ServerReplica<T>, Method: string, ...any) -> ...any,
	Destroy: (self: ServerReplica<T>) -> (),
	SetValue: (self: ServerReplica<T>, Path: ValidPath, Value: any) -> (),
	SetParent: (self: ServerReplica<T>, Parent: ServerReplica<T>) -> (),
	DestroyFor: (self: ServerReplica<T>, Player: Player) -> (),
	GetChildren: (self: ServerReplica<T>) -> { [string]: ServerReplica<T> },
	ReplicateFor: (self: ServerReplica<T>, Player: Player) -> (),
	OnServerEvent: (self: ServerReplica<T>, Callback: (Player: Player, ...any) -> ()) -> Connection,
}

export type ClientReplica<T = any> = Replica<T> & {
	Data: T?,
	Parent: ClientReplica<T>?,
	__IsParent: boolean?,
	__Parent: ClientReplica<T>?,

	Write: (self: ClientReplica<T>, Method: string, Callback: (...any) -> ()) -> Connection,
	Fire: (self: ClientReplica<T>, ...any) -> (),
	Destroy: (self: ClientReplica<T>) -> (),
	GetChildren: (self: ClientReplica<T>) -> { [string]: ClientReplica<T> },
	OnClientEvent: (self: ClientReplica<T>, Callback: (...any) -> ()) -> Connection,
}

export type PacketKey = {
	Key: string,
	IsNumber: boolean,
}

export type ChangePacket = {
	Path: { PacketKey },
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

export type ServerConfig<T = any> = Config<T> & {
	Parent: ServerReplica<any>?,
}

export type ClientConfig<T = any> = Config<T> & {
	Id: string,
	Parent: string?,
}

export type ServerReplicator = {
	NewReplica: (Config: ServerConfig<any>) -> ServerReplica<any>?,
}

export type ClientReplicator = {
	ListenToNewReplica: (Name: string, Callback: (Replica: ClientReplica<any>) -> ()) -> () -> (),
}

return {}
