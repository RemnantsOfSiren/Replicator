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
        X = 0,
        Y = 5,
        Z = 0,
        Type = "Plastic",
        T = {
            A = 1,
            B = 2,
            C = 3,
        }
    },
    Parent = Parent,
})

local Data = Replica.Data

print(Data.T.A)
Replica:Set("T-", {["A"] = 1})
print(Data.T.A)

while true do
    Data.Y += math.random(-10, 10) / 10
    task.wait()
end