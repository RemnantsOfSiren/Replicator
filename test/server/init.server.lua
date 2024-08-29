local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Server

local Replica = Replicator.NewReplica({
    Id = "Test",
    Name = "Test",
    Tags = { "Test" },
    Data = {
        ["4062748404"] = {
            Players = {},
        }
    },
    To = "All",
})

Replica:Set("4062748404/Players+", "4062748404")
print(Replica.Data)

task.delay(5, function()
    Replica:Set("4062748404/Players/1", nil)
    print(Replica.Data)
end)