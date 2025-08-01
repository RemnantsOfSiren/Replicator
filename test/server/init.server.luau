local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator).Server

local Parent = Replicator.NewReplica({
    To = "All",
    Name = "Parent",
    IsParent = true,
})

local Parent2 = Replicator.NewReplica({
    To = {},
    Name = "Parent2",
    IsParent = true,
})

local Replicas = {}

for I = 1, 20 do 
    table.insert(Replicas, Replicator.NewReplica({
        Name = `Test_{I}`,
        Tags = { "Test" },
        Data = {
            TestString = `Test String {I}`,
            TestArray = { { 1 }, { 2 }, { 3 } },
        },
        Parent = Parent,
    }))
end

for _, Replica in ipairs(Replicas) do
    Replica.Data.TestArray:Insert({ 10 })

    task.delay(2, function()
        --Replica:SetParent(Parent2)
        Replica.Data.TestArray:Remove(3)
    end)

    -- Replica:AddCleanupMethod(task.spawn(function()
    --     while true do
    --         Replica.Data.TestString = `Test String {math.random(1, 1000)}`
    --         task.wait()
    --     end
    -- end), true)
end

-- task.delay(16, function() 
--     print(Parent2:GetChildren())
-- end)

-- task.delay(25, function() 
--     Parent2:ReplicateFor(game.Players:GetPlayers()[1])
-- end)