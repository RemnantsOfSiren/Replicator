local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Replicator = require(ReplicatedStorage.Packages.Replicator) :: { any }

local function GetMaterialFromName(Name)
    for _, Material in pairs(Enum.Material:GetEnumItems()) do
        if Material.Name == Name then
            return Material
        end
    end
end

local function CreateInstance(Data)
    local Instance = Instance.new("Part")
    Instance.Size = Vector3.new(1, 1, 1)
    Instance.CFrame = CFrame.new(Data.X, Data.Y, Data.Z)
    Instance.Anchored = true
    Instance.Color = Color3.fromRGB(0, 150, 0)
    pcall(function() 
        Instance.Material = GetMaterialFromName(Data.Type) 
    end)
    Instance.Parent = workspace
    return Instance
end

Replicator.ListenToNewReplica("Test", function(Replica)
    local Object = CreateInstance(Replica.Data)

    Replica:ListenToChange({"X"}, function(X) 
        Object.CFrame = CFrame.new(X, Replica.Data.Y, Replica.Data.Z)
    end)

    Replica:ListenToChange({"Y"}, function(Y)
        Object.CFrame = CFrame.new(Replica.Data.X, Y, Replica.Data.Z)    
    end)

    Replica:ListenToChange({"Z"}, function(Z)
        Object.CFrame = CFrame.new(Replica.Data.X, Replica.Data.Y, Z)
    end)
end)