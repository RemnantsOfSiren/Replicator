local Parser = require(script.Parent.Parser) :: ({ string | number } | string) -> { any }

return {
    ObserveChange = function(Replica, Indicies: { string | number } | string, Callback: (...any) -> nil)
        local _Indicies = Parser(Indicies)

        local _Data = Replica.Data

        for _, Index in pairs(_Indicies) do
            _Data = _Data[Index]
        end

        task.spawn(Callback, _Data)

        return Replica:ListenToChange(Indicies, Callback)
    end,

    ListenToChange = function(Replica, Indicies: { string | number } | string, Callback: (...any) -> nil)
        local _Indicies = Parser(Indicies)

        return Replica.Changed:Connect(function(ChangedIndicies)
            local Match = true
            local _Data = Replica.Data
            local _OldData = Replica._OldData

            for I, Index in pairs(_Indicies) do
                _Data = _Data[Index]
                _OldData = _OldData[Index]

                if Index ~= ChangedIndicies[I] then
                    Match = false
                    break
                end
            end

            if Match then
                task.spawn(Callback, _Data, _OldData)
            end
        end)
    end,

    
	ListenToNewKey = function(Replica, Indicies: { string | number } | string, Callback)
		local _Indicies = Parser(Indicies)

		return Replica.Changed:Connect(function(ChangedIndices, Value, OldValue)
			if not OldValue and ChangedIndices[#ChangedIndices - 1] == _Indicies[#_Indicies] then
				task.spawn(Callback, Value, ChangedIndices[#ChangedIndices])
			end
		end)
	end,

    ListenToKeyRemoved = function(Replica, Indicies: { string | number } | string, Callback)
		local _Indicies = Parser(Indicies)

		return Replica.Changed:Connect(function(ChangedIndices, Value, OldValue)
			if not Value and ChangedIndices[#ChangedIndices - 1] == _Indicies[#_Indicies] then
				task.spawn(Callback, OldValue, ChangedIndices[#ChangedIndices])
			end
		end)
	end,

    ListenToWrite = function(Replica, WriteFunction: string, Callback)
        local Callbacks = Replica._WriteCallbacks[WriteFunction]
        if not Callbacks then
            Callbacks = {}
            Replica._WriteCallbacks[WriteFunction] = Callbacks
        end
        table.insert(Callbacks, Callback)
    end
}