local RunService = game:GetService("RunService")

return if RunService:IsServer() then require(script.Server) else require(script.Client)
