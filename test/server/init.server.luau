local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

local Parent = Replicator.NewReplica({
    Name = "Parent",
    To = "All",
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

for _, Replica in ipairs(Replicas) do
    Replica:ListenToChange("TestArray", function()
        print("Replica has changed!")
    end)

    task.delay(10, function() 
        Replica.Data.TestArray:Insert(10)
    end)

    task.delay(15, function()
        print(Replica.Data.TestArray)
        Replica.Data.TestArray = {}
        print(Replica.Data.TestArray)
    end)
end