local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

Replicator.ListenToNewReplica("Test", function(Replica)
    Replica:ListenToNewKey("TestArray", function(Key, Value)
        print("New Key:", Key, "Value:", Value)
    end)
end)