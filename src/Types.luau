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

export type ReplicatedTable<T = any> = T & typeof(setmetatable(
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

type function ToReplicatedTable(input, packetKey)	
	local function indexer(key, value)
		return { index = key, readresult = value, writeresult = value }
	end
	
	local function fn(params, returns)
		return types.newfunction({ head = params }, { head = returns })
	end

	local nilType = types.singleton(nil)
	local anyMap = types.newtable({}, indexer(types.any, types.any))

	local function makeReplicated(T)
		local meta = types.newtable({})
		local body = types.newtable({}, indexer(types.any, types.any), meta)
		local self = types.intersectionof(T, body)

		local props = {
			__type = types.singleton("ReplicatedTable"),
			__value = types.intersectionof(anyMap, T),
			__table = T,
			__onChange = fn({
				types.newtable({}, indexer(types.number, packetKey)),
				types.any,
				types.string,
			}, {}),
			__oldtable = anyMap,
			__indicies = types.unionof(
				types.newtable({}, indexer(types.number, types.unionof(types.string, types.number))),
				nilType
			),
			Get = fn({ self }, { T }),
			Insert = fn({ self, types.any, types.unionof(types.any, nilType) }, {}),
			Remove = fn({ self, types.number }, {}),
			Destroy = fn({ self }, {}),
		}
		for name, ty in props do
			body:setproperty(types.singleton(name), ty)
		end

		meta:setproperty(
			types.singleton("__iter"),
			fn({ self }, { fn({}, { types.any, types.any, fn({ types.any }, {}) }) })
		)

		return self
	end

	local cache = {}

	local function transform(ty)
		if cache[ty] then
			return cache[ty]
		end

		if ty:is("table") then
			local props = {}
			for key, prop in ty:properties() do
				props[key] = {
					read = if prop.read then transform(prop.read) else nil,
					write = if prop.write then transform(prop.write) else nil,
				}
			end

			local idx = ty:indexer()
			local newIndexer = nil
			if idx then
				local read = transform(idx.readresult)
				newIndexer = {
					index = idx.index,
					readresult = read,
					writeresult = if idx.writeresult then transform(idx.writeresult) else read,
				}
			end
			
			local result = makeReplicated(types.newtable(props, newIndexer))
			cache[ty] = result
			return result
		elseif ty:is("union") or ty:is("intersection") then
			local parts = {}
			for _, part in ty:components() do
				table.insert(parts, transform(part))
			end
			return if ty:is("union")
				then types.unionof(table.unpack(parts))
				else types.intersectionof(table.unpack(parts))
		end

		return ty
	end

	return transform(input)
end

export type RemoteEvent = {
	fire: (Player: Player, Packet: { [any]: any }) -> (),
	fireAll: (Packet: { [any]: any }) -> (),
	fireList: (Players: { Player }, Packet: { [any]: any }) -> (),
}

export type ServerReplica<T = any> = Replica<T> & {
	Data: ToReplicatedTable<T, {}>,
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
