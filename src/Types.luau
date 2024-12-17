local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

export type ValidPath = { string | number } | string | number
export type ToOptions = { Player } | Player | "All"
export type Hook = (self: ServerReplica | ClientReplica, Path: ValidPath, Callback: (...any) -> nil) -> { Disconnect: () -> nil }

export type Replica = {
	Id: string,
	Name: string,
	Tags: { any },
	Data: { [string | number]: any }?,
	OldData: { [string | number]: any }?,

	WriteLib: ModuleScript?,
	__WriteLib: { [any]: any }?,

	__Cleaner: typeof(Trove.new()),
	__Write: typeof(Signal.new()),
	__Change: typeof(Signal.new()),
	__Fired: typeof(Signal.new()),
	Destroying: typeof(Signal.new()),

	Destroy: (self: Replica) -> nil,
	ListenToWrite: Hook?,
	ListenToChange: Hook?,
	ListenToNewKey: Hook?,
	ListenToKeyRemoved: Hook?,
}

export type ServerReplica = Replica & {
	__Data: { [string | number]: any }?,
	__Ready: boolean?,
	__IsParent: boolean?,
	
	To: ToOptions?,
	Parent: ServerReplica?,
	SetParent: (self: ServerReplica, Parent: ServerReplica?) -> nil,
	Write: (self: ServerReplica, Method: string, ...any) -> ...any,
}

export type ClientReplica = Replica & {
	Parent: ClientReplica?,
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
	Parent: (ServerReplica | ClientReplica)?,
	To: ToOptions?,
}

return {}
