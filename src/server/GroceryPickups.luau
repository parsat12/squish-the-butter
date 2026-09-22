local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local GroceryPickups = {}
local TIERS = {"Plain", "Salted", "Golden", "Rainbow", "Cosmic"}

function GroceryPickups.Build(store)
    local sources = ReplicatedStorage:FindFirstChild("ButterModels")
    if not sources then
        warn("Grocery pickups need ReplicatedStorage.ButterModels")
        return {}
    end
    local folder = store:FindFirstChild("PickupDisplays")
    if folder then folder:Destroy() end
    folder = Instance.new("Folder")
    folder.Name = "PickupDisplays"
    folder.Parent = store
    local entries = {}
    local markers = {}
    for _, object in ipairs(store:GetDescendants()) do
        if object:IsA("BasePart") and object.Name == "OversizedButter" then
            object.Transparency = 0
            table.insert(markers, object)
        end
    end
    local filter = {folder}
    for _, marker in ipairs(markers) do table.insert(filter, marker) end
    local rayParams = RaycastParams.new()
    rayParams.FilterType = Enum.RaycastFilterType.Exclude
    rayParams.FilterDescendantsInstances = filter
    for index, tier in ipairs(TIERS) do
        local section = store:FindFirstChild(string.format("Section%02d_%s", index, tier))
        local source = sources:FindFirstChild(tier) or sources:FindFirstChild(tier .. " Butter")
        if not section or not source or not (source:IsA("Model") or source:IsA("BasePart")) then
            warn("Missing grocery section or ButterModels model: " .. tier)
            continue
        end
        local tierMarkers = {}
        for _, marker in ipairs(markers) do
            if marker:IsDescendantOf(section) then table.insert(tierMarkers, marker) end
        end
        local floor = section:FindFirstChild("OpenFloor")
        if not floor or not floor:IsA("BasePart") then
            warn("Grocery section needs OpenFloor: " .. tier)
            continue
        end
        table.sort(tierMarkers, function(a, b)
            local pa = floor.CFrame:PointToObjectSpace(a.Position)
            local pb = floor.CFrame:PointToObjectSpace(b.Position)
            if math.abs(pa.Z - pb.Z) > 0.01 then return pa.Z > pb.Z end
            return pa.X < pb.X
        end)
        for slot, marker in ipairs(tierMarkers) do
            local id = string.format("GroceryV1_%s_%02d", tier, slot)
            local model
            if source:IsA("Model") then
                model = source:Clone()
            else
                model = Instance.new("Model")
                source:Clone().Parent = model
            end
            model.Name = id
            -- Display copies must not carry scripts, crack prompts, or physics.
            for _, object in ipairs(model:GetDescendants()) do
                if object:IsA("LuaSourceContainer") or object:IsA("ProximityPrompt") or object:IsA("Light") then
                    object:Destroy()
                elseif object:IsA("BasePart") then
                    object.Anchored = true
                    object.CanCollide = false
                    object.CanTouch = false
                    object.CanQuery = false
                    object:SetAttribute("ButterId", nil)
                    object:SetAttribute("ButterStationReady", nil)
                end
            end
            model:SetAttribute("ButterId", nil)
            local bounds = model:GetExtentsSize()
            local longest = math.max(bounds.X, bounds.Y, bounds.Z)
            if longest <= 0 then model:Destroy() continue end
            local target = math.clamp(marker.Size.X * 0.55, 2, 7)
            model:ScaleTo(model:GetScale() * target / longest)
            model:PivotTo(marker.CFrame.Rotation * model:GetPivot().Rotation)
            local box, size = model:GetBoundingBox()
            local hit = Workspace:Raycast(marker.Position, Vector3.new(0, -300, 0), rayParams)
            local bottom = hit and hit.Position.Y or (floor.Position.Y + floor.Size.Y / 2)
            local center = Vector3.new(marker.Position.X, bottom + size.Y / 2 + 0.15, marker.Position.Z)
            model:PivotTo(CFrame.new(center - box.Position) * model:GetPivot())
            local anchor = Instance.new("Part")
            anchor.Name = "PickupAnchor"
            anchor.Size = Vector3.new(0.2, 0.2, 0.2)
            anchor.Transparency = 1
            anchor.Anchored = true
            anchor.CanCollide = false
            anchor.CanTouch = false
            anchor.CanQuery = false
            anchor.CFrame = CFrame.new(center)
            anchor.Parent = model
            local prompt = Instance.new("ProximityPrompt")
            prompt.Name = "GroceryPickupPrompt"
            prompt.ActionText = "Pick up"
            prompt.ObjectText = tier .. " Butter"
            prompt.HoldDuration = 0.25
            prompt.MaxActivationDistance = 12
            prompt.RequiresLineOfSight = false
            prompt.Parent = anchor
            model:SetAttribute("GroceryPickupId", id)
            model:SetAttribute("GroceryButterType", tier)
            model.Parent = folder
            marker.Transparency = 1
            marker.CanCollide = false
            marker.CanTouch = false
            marker.CanQuery = false
            entries[id] = {Model = model, Anchor = anchor, ButterId = tier, Floor = floor}
        end
    end
    return entries
end

return GroceryPickups
