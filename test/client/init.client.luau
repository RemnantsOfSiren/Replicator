local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

for i = 1, 20 do
    task.spawn(function()
        Replicator.ListenToNewReplica(`Test_{i}`, function(Replica)
            print("NewReplica:", Replica)
            
            Replica:OnClientEvent(function(...)
                print("ClientEvent:", ...)
            end)       
            Replica:ListenToChange("TestArray", function(Value, OldValue)
                print("NewValue:", Value, "OldValue:", OldValue)
            end)
        end)
    end)
end