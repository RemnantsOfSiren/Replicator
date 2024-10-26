local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Server

local Replica = Replicator.NewReplica({
    Id = "Test",
    Name = "Test",
    Tags = { "Test" },
    Data = {
        ["Friends"] = {}
    },
    To = "All",
})

task.delay(5, function()
    Replica:Set("Friends+", "Siren")
end)