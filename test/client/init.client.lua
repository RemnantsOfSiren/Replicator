local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Client

Replicator.ListenToNewReplica("Test", function(Replica)
    print(Replica)
    Replica.Changed:Connect(print)
end)