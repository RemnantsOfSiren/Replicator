local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator)

local Parent = Replicator.NewReplica({
    Name = "Parent",
    To = "All",
})

local Parent2 = Replicator.NewReplica({
    Name = "Parent2",
    To = {},
})

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
    task.delay(10, function() 
        print("Test 1")
        Replica:Fire("TestEvent", 1, 2, 3)
        Replica.Data.TestArray:Insert({ 10 })
    end)

    task.delay(15, function()
        print("Test 2")
        Replica:SetParent(Parent2)
        Replica.Data.TestArray:Remove(3)
    end)
end