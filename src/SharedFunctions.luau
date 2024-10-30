--!strict
local Types = require(script.Parent.Types)
local Parser = require(script.Parent.Parser)

type Data = {
    IsNumber: boolean,
    Key: string
}

type Path = { Data }

return {
    ListenToWrite = function(self: Types.ServerReplica | Types.ClientReplica, Method: string, Callback: (...any) -> nil)
        return self.__Write:Connect(function(_Method: string, Args: { any })
            if _Method == Method then
                task.spawn(Callback, unpack(Args))
            end
        end)
    end,

    ListenToKeyRemoved = function(self: Types.ServerReplica | Types.ClientReplica, Path: Types.ValidPath, Callback: (...any) -> nil)
        local ParsedPath = Parser(Path)
        local Last = ParsedPath[#ParsedPath]

        return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
            if NewValue then
                return
            end

            local LastKey = ChangedPath[#ChangedPath]

            if Last == LastKey then
                task.spawn(Callback, NewValue, OldValue)
            end
        end)
    end,

    ListenToNewKey = function (self: Types.ServerReplica | Types.ClientReplica, Path: Types.ValidPath, Callback: (...any) -> nil)
        local ParsedPath = Parser(Path)

        return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
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

    ListenToChange = function(self: Types.ServerReplica | Types.ClientReplica, Path: Types.ValidPath, Callback: (...any) -> nil)
        local ParsedPath = Parser(Path)

        return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
            --if #ParsedPath == #ChangedPath then
                local Match = true

                for Index, Key in pairs(ParsedPath) do
                    local ChangedKey = ChangedPath[Index]
                    if ChangedKey then
                        if Key ~= ChangedKey then
                            Match = false
                            break
                        end
                    end
                end

                if Match then
                    task.spawn(Callback, NewValue, OldValue)
                end
            --end
        end)
    end,

    ListenToRaw = function(self: Types.ServerReplica | Types.ClientReplica, Callback: (...any) -> nil)
        return self.__Change:Connect(function(ChangedPath: { string | number }, NewValue, OldValue)
            task.spawn(Callback, ChangedPath, NewValue, OldValue)
        end)
    end,

    ObserveChange = function(self: Types.ServerReplica | Types.ClientReplica, Path: Types.ValidPath, Callback: (...any) -> nil)
        local ParsedPath = Parser(Path)

        local _Data = self.__Data or self.Data

        for Index = 1, #ParsedPath do
            local Key = ParsedPath[Index]
            if Key then
                _Data = _Data[Key]
            end
        end

        task.spawn(Callback, _Data[ParsedPath[#ParsedPath]])

        return self:ListenToChange(Path, Callback)
    end,

    AddCleanupTask = function(self: Types.ServerReplica | Types.ClientReplica, Task: () -> nil, CleanupMethod: string | boolean?)
        self.__Cleaner:Add(Task, if not CleanupMethod then true else CleanupMethod)
    end
}