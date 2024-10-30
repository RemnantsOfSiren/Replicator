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
Data.TestArray:Insert(10)
Data.TestArray:Insert(15)

for Index, Value, Set in Data.TestArray:Get() do
    if Index == 2 then
        Set({
            1,
            2,
            3
        })
    end
end

for Index, Value in Data.TestArray:Get() do
    print(Index, Value)
    if type(Value) == "table" and Value.Get then
        for Index, Value in Value:Get() do
            print(Index, Value)
        end
    end
end