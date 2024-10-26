local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Client

Replicator.ListenToNewReplica("Test", function(Replica)
    Replica:ObserveChange("Friends", function(Friends)
        print("Friends:", Friends)
    end)
end)