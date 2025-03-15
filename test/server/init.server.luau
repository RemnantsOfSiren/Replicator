local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Server

local Parent = Replicator.NewReplica({
    To = "All",
    Name = "Parent",
    IsParent = true,
})

print(Parent)

local Parent2 = Replicator.NewReplica({
    To = {},
    Name = "Parent2",
    IsParent = true,
})

print(Parent2)

local Replicas = {}

for I = 1, 20 do 
    table.insert(Replicas, Replicator.NewReplica({
        Name = `Test_{I}`,
        Tags = { "Test" },
        Data = {
            TestArray = { { 1 }, { 2 }, { 3 } },
        },
        Parent = Parent,
    }))
end

for _, Replica in ipairs(Replicas) do
    Replica:OnServerEvent(function(Player, ...)
        print(Player, ...)
    end)

    task.delay(10, function() 
        Replica:Fire("TestEvent", 1, 2, 3)
        Replica.Data.TestArray:Insert({ 10 })
    end)

    task.delay(15, function()
        Replica:SetParent(Parent2)
        Replica.Data.TestArray:Remove(3)
    end)
end

task.delay(16, function() 
    print(Parent2:GetChildren())
end)

task.delay(25, function() 
    Parent2:ReplicateFor(game.Players:GetPlayers()[1])
end)