export type Level = "Info" | "Warn" | "Error"

return function(Execution: Level, ...: any)
    if Execution == "Info" then
        print("[[Replicator-Log]]: ", ...)
    elseif Execution == "Warn" then
        warn("[[Replicator-Log]]: ", ..., debug.traceback("", 10))
    elseif Execution == "Error" then
        local Args = { ... }
        local Str = ""

        for I = 1, #Args do
            if type(Args[I]) ~= "string" then
                warn(`[[Replicator-Log]]: Invalid argument type at index; Expected number, got {type(Args[I])}.`)
                return
            else
                Str = Str .. "\t" .. Args[I]
            end
        end
        
        error("[[Replicator-Log]]: " .. Str .. debug.traceback("", 10))
    end
end