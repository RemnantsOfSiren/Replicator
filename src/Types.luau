local Trove = require(script.Parent.Parent.Trove) :: any
local Signal = require(script.Parent.Parent.Signal) :: any

export type ValidPath = { string | number } | string | number
export type ToOptions = { Player } | Player | "All"

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
	Destroying: typeof(Signal.new()),

	Destroy: (self: Replica) -> nil,
	ListenToWrite: (self: ServerReplica | ClientReplica, Method: string, Callback: (...any) -> nil) -> nil,
	ListenToChange: (self: ServerReplica | ClientReplica, Path: ValidPath, Callback: (...any) -> nil) -> nil,
	ListenToNewKey: (self: ServerReplica | ClientReplica, Path: ValidPath, Callback: (...any) -> nil) -> nil,
	ListenToKeyRemoved: (self: ServerReplica | ClientReplica, Path: ValidPath, Callback: (...any) -> nil) -> nil,
}

export type ServerReplica = Replica & {
	__Data: { [string | number]: any },
	To: ToOptions?,
	Parent: ServerReplica?,
	Set: (self: ServerReplica, Path: ValidPath, Value: any) -> nil,
	Write: (self: ServerReplica, Method: string, ...any) -> ...any,
}

export type ClientReplica = Replica & {
	Parent: ClientReplica?,
}

export type Packet = {
	Name: string,
	Id: string,
	Changes: {
		[string]: { Time: number, Path: { string | number }, Value: any },
	},
}

return {}
