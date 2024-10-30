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

local Data = Replica.Data

Replica:ListenToNewKey("TestArray", function(Index, Value)
    print(Index, Value)
end)

Data.TestArray:Insert(5)
Data.TestArray:Insert(10)
Data.TestArray:Insert(15)

task.wait(4)

for Index, _, Set in Data.TestArray:Get() do
    -- Replica:ListenToChange({"TestArray", Index }, function(Value)
    --     print("Updating", Index, Value)
    -- end)

    if Index == 2 then
        Set({
            1,
            2,
            3
        })
    end
end

for Index, Value in Data.TestArray:GetValues() do
    print(Index, Value)
end

print("Before Removal")

Replica.Data.TestArray:Remove(1)

print("After Removal")

for Index, Value in Replica.Data.TestArray:GetValues() do
    print(Index, Value)
end