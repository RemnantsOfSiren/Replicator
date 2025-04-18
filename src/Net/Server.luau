--!strict
--!native
--!optimize 2
--!nolint LocalShadow
--#selene: allow(shadowing)
-- File generated by Blink v0.15.6 (https://github.com/1Axen/Blink)
-- This file is not meant to be edited

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local BASE_EVENT_NAME = "REPLICATOR_BLINK"
local Invocations = 0

local SendSize = 64
local SendOffset = 0
local SendCursor = 0
local SendBuffer = buffer.create(64)
local SendInstances = {}

local RecieveCursor = 0
local RecieveBuffer = buffer.create(64)

local RecieveInstances = {}
local RecieveInstanceCursor = 0

local Null = newproxy()

type Entry = {
    value: any,
    next: Entry?
}

type Queue = {
    head: Entry?,
    tail: Entry?
}

type BufferSave = {
    Size: number, 
    Cursor: number, 
    Buffer: buffer, 
    Instances: {Instance}
}

local function Read(Bytes: number)
    local Offset = RecieveCursor
    RecieveCursor += Bytes
    return Offset
end

local function Save(): BufferSave
    return {
        Size = SendSize,
        Cursor = SendCursor,
        Buffer = SendBuffer,
        Instances = SendInstances
    }
end

local function Load(Save: BufferSave?)
    if Save then
        SendSize = Save.Size
        SendCursor = Save.Cursor
        SendOffset = Save.Cursor
        SendBuffer = Save.Buffer
        SendInstances = Save.Instances
        return
    end

    SendSize = 64
    SendCursor = 0
    SendOffset = 0
    SendBuffer = buffer.create(64)
    SendInstances = {}
end

local function Invoke()
    if Invocations == 255 then
        Invocations = 0
    end

    local Invocation = Invocations
    Invocations += 1
    return Invocation
end

local function Allocate(Bytes: number)
    local InUse = (SendCursor + Bytes)
    if InUse > SendSize then
        --> Avoid resizing the buffer for every write
        while InUse > SendSize do
            SendSize *= 1.5
        end

        local Buffer = buffer.create(SendSize)
        buffer.copy(Buffer, 0, SendBuffer, 0, SendCursor)
        SendBuffer = Buffer
    end

    SendOffset = SendCursor
    SendCursor += Bytes
    
    return SendOffset
end

local function CreateQueue(): Queue
    return {
        head = nil,
        tail = nil
    }
end

local function Pop(queue: Queue): any
    local head = queue.head
    if head == nil then
        return
    end

    queue.head = head.next
    return head.value
end

local function Push(queue: Queue, value: any)
    local entry: Entry = {
        value = value,
        next = nil
    }

    if queue.tail ~= nil then
        queue.tail.next = entry
    end

    queue.tail = entry

    if queue.head == nil then
        queue.head = entry
    end
end

local Calls = table.create(256)

local Events: any = {
    Reliable = table.create(256),
    Unreliable = table.create(256)
}

local Queue: any = {
    Reliable = table.create(256),
    Unreliable = table.create(256)
}

Queue.Reliable[2] = table.create(256)
Queue.Reliable[7] = table.create(256)
export type unknownArray = {[number]: any}
export type replica = { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? }
export type replicaChange = { Time: number, Path: {[number]: any}, Value: any? }
export type arrayOfChanges = {[number]: { Time: number, Path: {[number]: any}, Value: any? }}
local function WriteEVENT_createReplica(Value: { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? }): ()
	-- Allocate BLOCK: 9 bytes
	local BLOCK_START = Allocate(9)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 0)
	local Length = #Value.Id
	buffer.writeu16(SendBuffer, BLOCK_START + 1, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Id, Length)
	local Length = #Value.Name
	buffer.writeu16(SendBuffer, BLOCK_START + 3, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Name, Length)
	buffer.writeu8(SendBuffer, BLOCK_START + 5, Value.Tags ~= nil and 1 or 0)
	if Value.Tags ~= nil then
		table.insert(SendInstances, Value.Tags or Null)
	end
	buffer.writeu8(SendBuffer, BLOCK_START + 6, Value.Data ~= nil and 1 or 0)
	if Value.Data ~= nil then
		table.insert(SendInstances, Value.Data or Null)
	end
	buffer.writeu8(SendBuffer, BLOCK_START + 7, Value.Parent ~= nil and 1 or 0)
	if Value.Parent ~= nil then
		-- Allocate BLOCK: 2 bytes
		local BLOCK_START = Allocate(2)
		local Length = #Value.Parent
		buffer.writeu16(SendBuffer, BLOCK_START + 0, Length)
		Allocate(Length)
		buffer.writestring(SendBuffer, SendOffset, Value.Parent, Length)
	end
	table.insert(SendInstances, Value.WriteLib or Null)
	buffer.writeu8(SendBuffer, BLOCK_START + 8, Value.IsParent ~= nil and 1 or 0)
	if Value.IsParent ~= nil then
		-- Allocate BLOCK: 1 bytes
		local BLOCK_START = Allocate(1)
		buffer.writeu8(SendBuffer, BLOCK_START + 0, Value.IsParent and 1 or 0)
	end
end

local function WriteEVENT_updateReplica(Value: { Id: string, Changes: {[number]: { Time: number, Path: {[number]: any}, Value: any? }} }): ()
	-- Allocate BLOCK: 5 bytes
	local BLOCK_START = Allocate(5)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 1)
	local Length = #Value.Id
	buffer.writeu16(SendBuffer, BLOCK_START + 1, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Id, Length)
	local Elements_1 = 0
	for Key_1, Element_1 in Value.Changes do
		Elements_1 += 1
		local OFFSET_0 = Allocate(1)
		buffer.writeu8(SendBuffer, OFFSET_0, Key_1)
		local OFFSET_1 = Allocate(8)
		buffer.writef64(SendBuffer, OFFSET_1, Element_1.Time)
		local OFFSET_2 = Allocate(2)
		local Elements_2 = 0
		for Key_2, Element_2 in Element_1.Path do
			Elements_2 += 1
			local OFFSET_0 = Allocate(1)
			buffer.writeu8(SendBuffer, OFFSET_0, Key_2)
			table.insert(SendInstances, Element_2 or Null)
		end
		buffer.writeu16(SendBuffer, OFFSET_2, Elements_2)
		local OFFSET_3 = Allocate(1)
		buffer.writeu8(SendBuffer, OFFSET_3, Element_1.Value ~= nil and 1 or 0)
		if Element_1.Value ~= nil then
			table.insert(SendInstances, Element_1.Value or Null)
		end
	end
	buffer.writeu16(SendBuffer, BLOCK_START + 3, Elements_1)
end

local function ReadEVENT_fireServerEvent(): ({ Id: string, Args: {[number]: any} })
	-- Read BLOCK: 4 bytes
	local BLOCK_START = Read(4)
	local Value = {} :: any
	local Length = buffer.readu16(RecieveBuffer, BLOCK_START + 0)
	Value.Id = buffer.readstring(RecieveBuffer, Read(Length), Length)
	Value.Args = {}
	local Elements_1 = buffer.readu16(RecieveBuffer, BLOCK_START + 2)
	for _ = 1, Elements_1 do
		local OFFSET_0 = Read(1)
		local Key_1 = buffer.readu8(RecieveBuffer, OFFSET_0)
		RecieveInstanceCursor += 1
		local Element_1 = RecieveInstances[RecieveInstanceCursor]
		Value.Args[Key_1] = Element_1
	end
	return Value
end

local function WriteEVENT_fireClientEvent(Value: { Id: string, Args: {[number]: any} }): ()
	-- Allocate BLOCK: 5 bytes
	local BLOCK_START = Allocate(5)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 3)
	local Length = #Value.Id
	buffer.writeu16(SendBuffer, BLOCK_START + 1, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Id, Length)
	local Elements_1 = 0
	for Key_1, Element_1 in Value.Args do
		Elements_1 += 1
		local OFFSET_0 = Allocate(1)
		buffer.writeu8(SendBuffer, OFFSET_0, Key_1)
		table.insert(SendInstances, Element_1 or Null)
	end
	buffer.writeu16(SendBuffer, BLOCK_START + 3, Elements_1)
end

local function WriteEVENT_changeParent(Value: { Id: string, Parent: string? }): ()
	-- Allocate BLOCK: 4 bytes
	local BLOCK_START = Allocate(4)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 4)
	local Length = #Value.Id
	buffer.writeu16(SendBuffer, BLOCK_START + 1, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Id, Length)
	buffer.writeu8(SendBuffer, BLOCK_START + 3, Value.Parent ~= nil and 1 or 0)
	if Value.Parent ~= nil then
		-- Allocate BLOCK: 2 bytes
		local BLOCK_START = Allocate(2)
		local Length = #Value.Parent
		buffer.writeu16(SendBuffer, BLOCK_START + 0, Length)
		Allocate(Length)
		buffer.writestring(SendBuffer, SendOffset, Value.Parent, Length)
	end
end

local function WriteEVENT_destroyReplica(Value: string): ()
	-- Allocate BLOCK: 3 bytes
	local BLOCK_START = Allocate(3)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 5)
	local Length = #Value
	buffer.writeu16(SendBuffer, BLOCK_START + 1, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value, Length)
end

local function WriteEVENT_replicaWrite(Value: { Id: string, Method: string, Args: {[number]: any}? }): ()
	-- Allocate BLOCK: 6 bytes
	local BLOCK_START = Allocate(6)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 6)
	local Length = #Value.Id
	buffer.writeu16(SendBuffer, BLOCK_START + 1, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Id, Length)
	local Length = #Value.Method
	buffer.writeu16(SendBuffer, BLOCK_START + 3, Length)
	Allocate(Length)
	buffer.writestring(SendBuffer, SendOffset, Value.Method, Length)
	buffer.writeu8(SendBuffer, BLOCK_START + 5, Value.Args ~= nil and 1 or 0)
	if Value.Args ~= nil then
		-- Allocate BLOCK: 2 bytes
		local BLOCK_START = Allocate(2)
		local Elements_2 = 0
		for Key_2, Element_2 in Value.Args do
			Elements_2 += 1
			local OFFSET_0 = Allocate(1)
			buffer.writeu8(SendBuffer, OFFSET_0, Key_2)
			table.insert(SendInstances, Element_2 or Null)
		end
		buffer.writeu16(SendBuffer, BLOCK_START + 0, Elements_2)
	end
end

local function ReadFUNCTION_DATA_getInitialReplicas(): (nil)
	return nil
end

local function WriteFUNCTION_RETURN_getInitialReplicas(Value: { { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? } }, InvocationIdentifier: number): ()
	-- Allocate BLOCK: 4 bytes
	local BLOCK_START = Allocate(4)
	buffer.writeu8(SendBuffer, BLOCK_START + 0, 7)
	buffer.writeu8(SendBuffer, BLOCK_START + 1, InvocationIdentifier)
	buffer.writeu8(SendBuffer, BLOCK_START + 2, 1)
	-- START ARRAY
	buffer.writeu8(SendBuffer, BLOCK_START + 3, #Value)
		-- Allocate BLOCK: 8 bytes
	local ARRAY_START_1 = Allocate(8 * #Value)
	for Index = 1, #Value do
		local Item_1 = Value[Index]
		local Length = #Item_1.Id
		-- Allocate 2
		local OPERATION_OFFSET = ARRAY_START_1
		ARRAY_START_1 += 2
		buffer.writeu16(SendBuffer, OPERATION_OFFSET, Length)
		Allocate(Length)
		buffer.writestring(SendBuffer, SendOffset, Item_1.Id, Length)
		local Length = #Item_1.Name
		-- Allocate 2
		local OPERATION_OFFSET = ARRAY_START_1
		ARRAY_START_1 += 2
		buffer.writeu16(SendBuffer, OPERATION_OFFSET, Length)
		Allocate(Length)
		buffer.writestring(SendBuffer, SendOffset, Item_1.Name, Length)
		-- Allocate 1
		local OPERATION_OFFSET = ARRAY_START_1
		ARRAY_START_1 += 1
		buffer.writeu8(SendBuffer, OPERATION_OFFSET, Item_1.Tags ~= nil and 1 or 0)
		if Item_1.Tags ~= nil then
			table.insert(SendInstances, Item_1.Tags or Null)
		end
		-- Allocate 1
		local OPERATION_OFFSET = ARRAY_START_1
		ARRAY_START_1 += 1
		buffer.writeu8(SendBuffer, OPERATION_OFFSET, Item_1.Data ~= nil and 1 or 0)
		if Item_1.Data ~= nil then
			table.insert(SendInstances, Item_1.Data or Null)
		end
		-- Allocate 1
		local OPERATION_OFFSET = ARRAY_START_1
		ARRAY_START_1 += 1
		buffer.writeu8(SendBuffer, OPERATION_OFFSET, Item_1.Parent ~= nil and 1 or 0)
		if Item_1.Parent ~= nil then
			-- Allocate BLOCK: 2 bytes
			local BLOCK_START = Allocate(2)
			local Length = #Item_1.Parent
			buffer.writeu16(SendBuffer, BLOCK_START + 0, Length)
			Allocate(Length)
			buffer.writestring(SendBuffer, SendOffset, Item_1.Parent, Length)
		end
		table.insert(SendInstances, Item_1.WriteLib or Null)
		-- Allocate 1
		local OPERATION_OFFSET = ARRAY_START_1
		ARRAY_START_1 += 1
		buffer.writeu8(SendBuffer, OPERATION_OFFSET, Item_1.IsParent ~= nil and 1 or 0)
		if Item_1.IsParent ~= nil then
			-- Allocate BLOCK: 1 bytes
			local BLOCK_START = Allocate(1)
			buffer.writeu8(SendBuffer, BLOCK_START + 0, Item_1.IsParent and 1 or 0)
		end
	end
	-- END ARRAY
end

if not RunService:IsRunning() then
	local NOOP = function() end
	local Returns = table.freeze({
	createReplica = {
		fire = NOOP,
		fireAll = NOOP,
		fireList = NOOP,
		fireExcept = NOOP
	},
	updateReplica = {
		fire = NOOP,
		fireAll = NOOP,
		fireList = NOOP,
		fireExcept = NOOP
	},
	fireServerEvent = {
		on = NOOP
	},
	fireClientEvent = {
		fire = NOOP,
		fireAll = NOOP,
		fireList = NOOP,
		fireExcept = NOOP
	},
	changeParent = {
		fire = NOOP,
		fireAll = NOOP,
		fireList = NOOP,
		fireExcept = NOOP
	},
	destroyReplica = {
		fire = NOOP,
		fireAll = NOOP,
		fireList = NOOP,
		fireExcept = NOOP
	},
	replicaWrite = {
		fire = NOOP,
		fireAll = NOOP,
		fireList = NOOP,
		fireExcept = NOOP
	},
	getInitialReplicas = {
		on = NOOP
	},
	})
	return Returns :: BLINK_EVENTS_SYMBOL
end

if not RunService:IsServer() then
    error("Server network module can only be required from the server.")
end

local Reliable: RemoteEvent = ReplicatedStorage:FindFirstChild(BASE_EVENT_NAME .. "_RELIABLE_REMOTE") :: RemoteEvent
if not Reliable then
    local RemoteEvent = Instance.new("RemoteEvent")
    RemoteEvent.Name = BASE_EVENT_NAME .. "_RELIABLE_REMOTE"
    RemoteEvent.Parent = ReplicatedStorage
    Reliable = RemoteEvent
end

local Unreliable: UnreliableRemoteEvent = ReplicatedStorage:FindFirstChild(BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE") :: UnreliableRemoteEvent
if not Unreliable then
    local UnreliableRemoteEvent = Instance.new("UnreliableRemoteEvent")
    UnreliableRemoteEvent.Name = BASE_EVENT_NAME .. "_UNRELIABLE_REMOTE"
    UnreliableRemoteEvent.Parent = ReplicatedStorage
    Unreliable = UnreliableRemoteEvent
end

local PlayersMap: {[Player]: BufferSave} = {}

Players.PlayerRemoving:Connect(function(Player)
    PlayersMap[Player] = nil
end)

local function StepReplication()
    for Player, Send in PlayersMap do
        if Send.Cursor <= 0 then
            continue
        end

        local Buffer = buffer.create(Send.Cursor)
        buffer.copy(Buffer, 0, Send.Buffer, 0, Send.Cursor)
        Reliable:FireClient(Player, Buffer, Send.Instances)

        Send.Size = 64
        Send.Cursor = 0
        Send.Buffer = buffer.create(64)
        table.clear(Send.Instances)
    end
end
RunService.Heartbeat:Connect(StepReplication)
Reliable.OnServerEvent:Connect(function(Player: Player, Buffer: buffer, Instances: {Instance})
	RecieveCursor = 0
	RecieveBuffer = Buffer
	RecieveInstances = Instances
	RecieveInstanceCursor = 0
	local Size = buffer.len(RecieveBuffer)
	while (RecieveCursor < Size) do
		-- Read BLOCK: 1 bytes
		local BLOCK_START = Read(1)
		local Index = buffer.readu8(RecieveBuffer, BLOCK_START + 0)
		if Index == 2 then
			local Value: { Id: string, Args: {[number]: any} } = ReadEVENT_fireServerEvent()
			if Events.Reliable[2] ~= nil then
				Events.Reliable[2](Player, Value)
			else
				if #Queue.Reliable[2] > 256 then
					warn("[Blink]: Event queue of \"fireServerEvent\" exceeded 256, did you forget to implement a listener?")
				end
				table.insert(Queue.Reliable[2], {Player, Value} :: {any})
			end
		elseif Index == 7 then
			-- Read BLOCK: 1 bytes
			local BLOCK_START = Read(1)
			local InvocationIdentifier = buffer.readu8(RecieveBuffer, BLOCK_START + 0)
			local Value: nil = ReadFUNCTION_DATA_getInitialReplicas()
			if Events.Reliable[7] ~= nil then
				Events.Reliable[7](Player, Value, InvocationIdentifier)
			else
				if #Queue.Reliable[7] > 256 then
					warn("[Blink]: Event queue of \"getInitialReplicas\" exceeded 256, did you forget to implement a listener?")
				end
				table.insert(Queue.Reliable[7], {Player, Value, InvocationIdentifier} :: {any})
			end
		end
	end
end)
Unreliable.OnServerEvent:Connect(function(Player: Player, Buffer: buffer, Instances: {Instance})
	RecieveCursor = 0
	RecieveBuffer = Buffer
	RecieveInstances = Instances
	RecieveInstanceCursor = 0
	local Size = buffer.len(RecieveBuffer)
	while (RecieveCursor < Size) do
		-- Read BLOCK: 1 bytes
		local BLOCK_START = Read(1)
		local Index = buffer.readu8(RecieveBuffer, BLOCK_START + 0)
	end
end)


local Returns = table.freeze({
	stepReplication = StepReplication,

	createReplica = {
		fire = function(Player: Player, Value: { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? }): ()
			Load(PlayersMap[Player])
			WriteEVENT_createReplica(Value)
			PlayersMap[Player] = Save()
		end,
		fireAll = function(Value: { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? }): ()
			Load()
			WriteEVENT_createReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireList = function(List: {Player}, Value: { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? }): ()
			Load()
			WriteEVENT_createReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in List do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireExcept = function(Except: Player, Value: { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? }): ()
			Load()
			WriteEVENT_createReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				if Player == Except then
					continue
				end
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
	},
	updateReplica = {
		fire = function(Player: Player, Value: { Id: string, Changes: {[number]: { Time: number, Path: {[number]: any}, Value: any? }} }): ()
			Load(PlayersMap[Player])
			WriteEVENT_updateReplica(Value)
			PlayersMap[Player] = Save()
		end,
		fireAll = function(Value: { Id: string, Changes: {[number]: { Time: number, Path: {[number]: any}, Value: any? }} }): ()
			Load()
			WriteEVENT_updateReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireList = function(List: {Player}, Value: { Id: string, Changes: {[number]: { Time: number, Path: {[number]: any}, Value: any? }} }): ()
			Load()
			WriteEVENT_updateReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in List do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireExcept = function(Except: Player, Value: { Id: string, Changes: {[number]: { Time: number, Path: {[number]: any}, Value: any? }} }): ()
			Load()
			WriteEVENT_updateReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				if Player == Except then
					continue
				end
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
	},
	fireServerEvent = {
		on = function(Listener: (Player: Player, Value: { Id: string, Args: {[number]: any} }) -> ()): () -> ()
			Events.Reliable[2] = Listener
			for Index, Arguments in Queue.Reliable[2] do
				Listener(table.unpack(Arguments))
			end
			Queue.Reliable[2] = {}
			return function (): ()
				Events.Reliable[2] = nil
			end
		end
	},
	fireClientEvent = {
		fire = function(Player: Player, Value: { Id: string, Args: {[number]: any} }): ()
			Load(PlayersMap[Player])
			WriteEVENT_fireClientEvent(Value)
			PlayersMap[Player] = Save()
		end,
		fireAll = function(Value: { Id: string, Args: {[number]: any} }): ()
			Load()
			WriteEVENT_fireClientEvent(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireList = function(List: {Player}, Value: { Id: string, Args: {[number]: any} }): ()
			Load()
			WriteEVENT_fireClientEvent(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in List do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireExcept = function(Except: Player, Value: { Id: string, Args: {[number]: any} }): ()
			Load()
			WriteEVENT_fireClientEvent(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				if Player == Except then
					continue
				end
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
	},
	changeParent = {
		fire = function(Player: Player, Value: { Id: string, Parent: string? }): ()
			Load(PlayersMap[Player])
			WriteEVENT_changeParent(Value)
			PlayersMap[Player] = Save()
		end,
		fireAll = function(Value: { Id: string, Parent: string? }): ()
			Load()
			WriteEVENT_changeParent(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireList = function(List: {Player}, Value: { Id: string, Parent: string? }): ()
			Load()
			WriteEVENT_changeParent(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in List do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireExcept = function(Except: Player, Value: { Id: string, Parent: string? }): ()
			Load()
			WriteEVENT_changeParent(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				if Player == Except then
					continue
				end
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
	},
	destroyReplica = {
		fire = function(Player: Player, Value: string): ()
			Load(PlayersMap[Player])
			WriteEVENT_destroyReplica(Value)
			PlayersMap[Player] = Save()
		end,
		fireAll = function(Value: string): ()
			Load()
			WriteEVENT_destroyReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireList = function(List: {Player}, Value: string): ()
			Load()
			WriteEVENT_destroyReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in List do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireExcept = function(Except: Player, Value: string): ()
			Load()
			WriteEVENT_destroyReplica(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				if Player == Except then
					continue
				end
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
	},
	replicaWrite = {
		fire = function(Player: Player, Value: { Id: string, Method: string, Args: {[number]: any}? }): ()
			Load(PlayersMap[Player])
			WriteEVENT_replicaWrite(Value)
			PlayersMap[Player] = Save()
		end,
		fireAll = function(Value: { Id: string, Method: string, Args: {[number]: any}? }): ()
			Load()
			WriteEVENT_replicaWrite(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireList = function(List: {Player}, Value: { Id: string, Method: string, Args: {[number]: any}? }): ()
			Load()
			WriteEVENT_replicaWrite(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in List do
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
		fireExcept = function(Except: Player, Value: { Id: string, Method: string, Args: {[number]: any}? }): ()
			Load()
			WriteEVENT_replicaWrite(Value)
			local Buffer, Size, Instances = SendBuffer, SendCursor, SendInstances
			for _, Player in Players:GetPlayers() do
				if Player == Except then
					continue
				end
				Load(PlayersMap[Player])
				local Position = Allocate(Size)
				buffer.copy(SendBuffer, Position, Buffer, 0, Size)
				table.move(Instances, 1, #Instances, #SendInstances + 1, SendInstances)
				PlayersMap[Player] = Save()
			end
		end,
	},
	getInitialReplicas = {
		on = function(Listener: (Player, nil) -> ({ { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? } })): ()
			Events.Reliable[7] = function(Player: Player, Value: nil, InvocationIdentifier: number): ()
				local ReturnValue: { { Id: string, Name: string, Tags: any?, Data: any?, Parent: string?, WriteLib: Instance?, IsParent: boolean? } };
				local Success, Error = pcall(function ()
					ReturnValue = Listener(Player, Value)
				end)
				Load(PlayersMap[Player])
				if Success ~= true then
					local Position = Allocate(3)
					buffer.writeu8(SendBuffer, Position, 7)
					buffer.writeu8(SendBuffer, Position + 1, InvocationIdentifier)
					buffer.writeu8(SendBuffer, Position + 2, 0)
					warn(`"getInitialReplicas" encountered an error, {Error}`)
				else
					WriteFUNCTION_RETURN_getInitialReplicas(ReturnValue, InvocationIdentifier)
				end
				PlayersMap[Player] = Save()
			end
			task.spawn(function (): ()
				local EventQueue = Queue.Reliable[7] or {}
				Queue.Reliable[7] = nil
				for Index, Arguments in EventQueue do
					Events.Reliable[7](table.unpack(Arguments))
				end
			end)
		end
	},
})
type BLINK_EVENTS_SYMBOL = typeof(Returns)
return Returns :: BLINK_EVENTS_SYMBOL