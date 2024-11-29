local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

for i = 1, 20 do
    task.spawn(function()
        Replicator.ListenToNewReplica(`Test_{i}`, function(Replica)
            Replica:ListenToChange("TestArray", function()
                print("Replica has changed!")
            end)
        end)
    end)
end