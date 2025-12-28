local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Client

for i = 1, 20 do
    task.spawn(function()
        Replicator.ListenToNewReplica(`Test_{i}`, function(Replica)
            Replica:ObserveChange("TestArray", function(Value, OldValue)
                print("NewValue:", Value, "OldValue:", OldValue)
            end)
            Replica:ObserveChange("TestString", function(Key, Value)
                print("New String:", Key, "Value:", Value)
            end)
        end)
    end)
end