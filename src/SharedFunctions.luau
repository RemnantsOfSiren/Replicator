--!strict
local Types = require(script.Parent.Types)
local Parser = require(script.Parent.Parser)

type Data = {
	IsNumber: boolean,
	Key: string,
}

type Path = { Data }

--[=[
    @method ListenToWrite
    @within Replica
    @param Method string
    @param Callback (...any) -> nil
    @return RBXScriptConnection

    Connects to the Write event and listens for a specific method to be called. When the method is called, the callback is fired with the arguments passed to the method.
]=]

--[=[
    @method ListenToKeyRemoved
    @within Replica
    @param Path { string | number } | string
    @param Callback (...any) -> nil
    @return RBXScriptConnection

    Connects to the Change event and listens for a specific key to be removed. When the key is removed, the callback is fired with the key and the value of the key before it was removed.
]=]

--[=[
    @method ListenToNewKey
    @within Replica
    @param Path { string | number } | string
    @param Callback (...any) -> nil
    @return RBXScriptConnection

    Connects to the Change event and listens for a new key to be added. When the key is added, the callback is fired with the key and the value of the key.
]=]

--[=[
    @method ListenToChange
    @within Replica
    @param Path { string | number } | string
    @param Callback (...any) -> nil
    @param SuppressOld boolean?
    @return RBXScriptConnection

    Connects to the Change event and listens for a specific key to be changed. When the key is changed, the callback is fired with the new value and the old value.
]=]

--[=[
    @method ListenToRaw
    @within Replica
    @param Callback (...any) -> nil
    @return RBXScriptConnection

    Connects to the Change event and listens for any key to be changed. When a key is changed, the callback is fired with the path, the new value, and the old value.
]=]

--[=[
    @method ObserveChange
    @within Replica
    @param Path { string | number } | string
    @param Callback (...any) -> nil
    @return RBXScriptConnection

    Observes a specific key and fires the callback with the value of the key. The callback is fired immediately and then whenever the key is changed.
]=]

--[=[
    @method AddCleanupTask
    @within Replica
    @param Task () -> nil
    @param CleanupMethod string | boolean?
    @return nil

    Adds a task to be cleaned when the replica is destroyed. If a method is provided it'll use this method to clean, otherwise it'll assume that it is a function or thread (true).
]=]

return {
	ListenToWrite = function(
		self: Types.ServerReplica | Types.ClientReplica,
		Method: string,
		Callback: (...any) -> nil
	)
		return self.__Write:Connect(function(_Method: string, Args: { any })
			if _Method == Method then
				task.spawn(Callback, unpack(Args))
			end
		end)
	end,

	ListenToKeyRemoved = function(
		self: Types.ServerReplica | Types.ClientReplica,
		Path: Types.ValidPath,
		Callback: (...any) -> nil
	)
		local ParsedPath = Parser(Path)

		return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
			if NewValue then
				return
			end

			local Match = true

			for Index = 1, #ParsedPath do
				local Key = ParsedPath[Index]
				if Key then
					OldValue = OldValue[Key]

					if Key ~= ChangedPath[Index] then
						Match = false
						break
					end
				end
			end

			if Match then
				local Key = ChangedPath[#ChangedPath]
				task.spawn(Callback, Key, OldValue[Key])
			end
		end)
	end,

	ListenToNewKey = function(
		self: Types.ServerReplica | Types.ClientReplica,
		Path: Types.ValidPath,
		Callback: (...any) -> nil
	)
		local ParsedPath = Parser(Path)

		return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
			for Index = 1, #ChangedPath do
				local Key = ChangedPath[Index]
				if Key then
					OldValue = OldValue[Key]
				end
			end

			if OldValue then
				return
			end

			local IsMatch = true

			if #ParsedPath ~= 0 then
				for Index, Key in pairs(ParsedPath) do
					local ChangedKey = ChangedPath[Index]
					if ChangedKey then
						if Key ~= ChangedKey then
							IsMatch = false
							break
						end
					end
				end
			end

			if IsMatch then
				task.spawn(Callback, ChangedPath[#ChangedPath], NewValue)
			end
		end)
	end,

	ListenToChange = function(
		self: Types.ServerReplica | Types.ClientReplica,
		Path: Types.ValidPath,
		Callback: (...any) -> nil,
		SuppressOld: boolean?
	)
		local ParsedPath = Parser(Path)

		return self.__Change:Connect(function(ChangedPath: { string | number }, _, OldData)
			local Match = true
			local Data = self.__Data or self.Data
			local OldData = if not SuppressOld then OldData else nil

			for Index = 1, #ParsedPath do
				local Key = ParsedPath[Index]
				if Key then
					Data = Data[Key]
					if not SuppressOld then
						OldData = OldData[Key]
					end

					if Key ~= ChangedPath[Index] then
						Match = false
						break
					end
				end
			end

			if Match then
				task.spawn(Callback, Data, if SuppressOld then nil else OldData)
			end
		end)
	end,

	ListenToRaw = function(self: Types.ServerReplica | Types.ClientReplica, Callback: (...any) -> nil)
		return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
			local LastIndex = ChangedPath[#ChangedPath]

			for Index = 1, #ChangedPath - 1 do
				OldValue = OldValue[ChangedPath[Index]]
			end

			local LastValue = OldValue and OldValue[LastIndex]
			task.spawn(Callback, ChangedPath, NewValue, LastValue)
		end)
	end,

	ObserveChange = function(
		self: Types.ServerReplica | Types.ClientReplica,
		Path: Types.ValidPath,
		Callback: (...any) -> nil
	)
		local ParsedPath = Parser(Path)

		local _Data = self.__Data or self.Data

		for Index = 1, #ParsedPath - 1 do
			local Key = ParsedPath[Index]
			if Key then
				_Data = _Data[Key]
			end
		end

		task.spawn(Callback, _Data[ParsedPath[#ParsedPath]], nil)
		return self:ListenToChange(Path, Callback, false)
	end,

	AddCleanupTask = function(
		self: Types.ServerReplica | Types.ClientReplica,
		Task: () -> nil,
		CleanupMethod: string | boolean?
	)
		self.__Cleaner:Add(Task, if not CleanupMethod then true else CleanupMethod)
	end,
}
