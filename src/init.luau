local RunService = game:GetService("RunService")

--[=[
    @class Replica
]=]

--[=[
    @class Replicator
]=]
return if RunService:IsServer() then require(script.Server) else require(script.Client)
