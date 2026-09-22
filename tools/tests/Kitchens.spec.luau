-- Run as a temporary server Script in an isolated Studio test session.
local Kitchens = require(game.ServerScriptService.Server.Kitchens)
local fixtures = Instance.new("Model")
fixtures.Name = "KitchenTestFixtures"
fixtures.Parent = workspace
local service
local testers = {}
local function run()
    local plots = Instance.new("Folder")
    plots.Name = "KitchenPlots"
    plots.Parent = fixtures
    for i = 1, 8 do
        local plot = Instance.new("Model")
        plot.Name = string.format("Plot%02d", i)
        plot.Parent = plots
        local area = Instance.new("Part")
        area.Name = "BuildArea"
        area.Size = Vector3.new(45, 0.04, 41)
        area.CFrame = CFrame.new(10000 + i * 70, 0, 10000) * CFrame.Angles(0, i * math.pi / 4, 0)
        area.Anchored = true
        area.Parent = plot
    end
    local data = {}
    for i = 1, 9 do
        local player = {UserId = i, DisplayName = "KitchenTest" .. i}
        local attributes = {}
        function player:SetAttribute(name, value) attributes[name] = value end
        function player:GetAttribute(name) return attributes[name] end
        testers[i] = player
        data[player] = {Beebohs = {{Name = "Blue"}}, KitchenBeebohs = {1}}
    end
    service = Kitchens.new(fixtures, data, function(entry, parent)
        local model = Instance.new("Model")
        local p = Instance.new("Part")
        p.Anchored = true
        p.Size = Vector3.new(2, 1, 1)
        p.Parent = model
        model.PrimaryPart = p
        model.Parent = parent
        return model
    end)
    local seen = {}
    for i = 1, 8 do
        local plot = service:Assign(testers[i])
        assert(plot and not seen[plot], "Every player needs a unique plot")
        seen[plot] = true
        assert(plot:GetAttribute("OwnerUserId") == i)
        local indicator = plot:FindFirstChild("PlotOwnerIndicator")
        assert(indicator and indicator:IsA("BillboardGui"), "Claimed plots need a head indicator")
        assert(indicator.Adornee == plot.BuildArea)
        assert(indicator.OwnerHead.Image == string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", i))
        assert(indicator.OwnerHead.BackgroundTransparency == 1, "Only the head should be visible")
        assert(testers[i]:GetAttribute("KitchenPlot") == plot.Name)
        assert(testers[i]:GetAttribute("KitchenVisited") == false)
        assert(typeof(testers[i]:GetAttribute("KitchenGuideTarget")) == "Vector3")
        assert(#service.Roamers[testers[i]] == 1)
        assert(plot.StarterKitchen:GetAttribute("Stage") == 1)
        assert(plot.StarterKitchen:FindFirstChild("TrainingPad"))
        assert(service:Assign(testers[i]) == plot, "Repeated assignment must keep the same plot")
        assert(plot.PlotOwnerIndicator == indicator, "Repeated assignment must keep the same indicator")
    end
    assert(not service:Assign(testers[9]), "A ninth player must not steal a plot")
    local character = Instance.new("Model")
    character.Parent = fixtures
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Anchored = true
    root.Parent = character
    local humanoid = Instance.new("Humanoid")
    humanoid.RequiresNeck = false
    humanoid.Parent = character
    testers[1].Character = character
    local area = service.Assignments[testers[1]].BuildArea
    root.CFrame = area.CFrame * CFrame.new(0, 3, -area.Size.Z / 2 - 3)
    service:Step(0)
    assert(not testers[1]:GetAttribute("KitchenVisited"), "Outside the plot must not count as entry")
    root.CFrame = area.CFrame * CFrame.new(0, 3, 0)
    service:Step(0)
    assert(testers[1]:GetAttribute("KitchenVisited"), "Entering own plot must complete guidance")
    testers[1].Character = nil
    character:Destroy()
    service:Step(0)
    assert(testers[1]:GetAttribute("KitchenVisited"), "Respawn must not reset a completed visit")
    for _ = 1, 200 do service:Step(0.1) end
    for i = 1, 8 do
        local item = service.Roamers[testers[i]][1]
        assert(math.abs(item.Position.X) <= item.HalfX + 0.001)
        assert(math.abs(item.Position.Z) <= item.HalfZ + 0.001)
    end
    local first = service.Assignments[testers[1]]
    service:Release(testers[1])
    assert(not first:GetAttribute("OwnerUserId") and not first:FindFirstChild("KitchenBeebohs"))
    assert(not first:FindFirstChild("PlotOwnerIndicator"), "Released plots must not show the previous owner")
    assert(service:Assign(testers[9]) == first, "Released plots must be reusable")
    assert(first.PlotOwnerIndicator.OwnerHead.Image == "rbxthumb://type=AvatarHeadShot&id=9&w=420&h=420",
        "Reassigned plots must show their new owner")
    data[testers[9]].KitchenBeebohs = {}
    service:Rebuild(testers[9])
    assert(#service.Roamers[testers[9]] == 0, "Returning a Beeboh must remove the roaming model")
end
local ok, failure = pcall(run)
if service then for _, player in ipairs(testers) do service:Release(player) end end
fixtures:Destroy()
assert(ok, failure)
print("PASS: eight unique plots, consistent starter stages, full-server handling, reassignment, roaming bounds, removal")
