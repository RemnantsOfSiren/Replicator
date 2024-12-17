local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

local Parent = Replicator.NewReplica({
    Name = "Parent",
    To = "All",
})

local Parent2 = Replicator.NewReplica({
    Name = "Parent2",
    To = nil,
})

local Replicas = {}

for I = 1, 20 do 
    table.insert(Replicas, Replicator.NewReplica({
        Name = `Test_{I}`,
        Tags = { "Test" },
        Data = {
            TestArray = {1, 2, 3},
        },
        Parent = Parent,
    }))
end

print(`Parent {Parent.Name} has Children: `, Parent:GetChildren())

for _, Replica in ipairs(Replicas) do
    task.delay(10, function() 
        Replica:Fire("TestEvent", 1, 2, 3)
        Replica.Data.TestArray:Insert(10)
    end)

    task.delay(15, function()
        Replica:SetParent(Parent2)
        Replica.Data.TestArray = {}
    end)
end

task.delay(20, function()
    print(`Parent {Parent.Name} has Children: `, Parent:GetChildren())
    print(`Parent {Parent2.Name} has Children: `, Parent2:GetChildren())
end)