local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

Replicator.ListenToNewReplica("Test", function(Replica)
    Replica:ObserveChange("TestArray", function(Value)
        print("Table Changed:", Value)
    end)
    Replica:ListenToNewKey({"TestArray"}, function(Key, Value)
        print("New Key:", Key, "Value:", Value)
    end)
    Replica:ListenToKeyRemoved({"TestArray"}, function(Key, Value)
        print("Key Removed:", Key, "Value:", Value)
    end)
end)