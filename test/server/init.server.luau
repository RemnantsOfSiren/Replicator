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

Data.TestArray:Insert(5)
Data.TestArray:Insert(10)
Data.TestArray:Insert(15)

task.wait(4)

for Index, _, Set in Data.TestArray:Get() do
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