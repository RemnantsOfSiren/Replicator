local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

local Parent = Replicator.NewReplica({
    Name = "Parent",
    To = "All",
})

local Replica = Replicator.NewReplica({
    Name = "Test",
    Tags = { "Test" },
    Data = {
        TestArray = {},
    },
    Parent = Parent,
})

Replica:ListenToNewKey("TestArray", function(Key, Value)
    print("New Key:", Key, "Value:", Value)
end)

local Data = Replica.Data

Data.TestArray:Insert(5)