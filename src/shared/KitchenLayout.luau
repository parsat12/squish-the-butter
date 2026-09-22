local Layout = {}

function Layout.Build(plot)
    local area = plot:FindFirstChild("BuildArea")
    assert(area and area:IsA("BasePart"), "Kitchen plot is missing BuildArea")
    local old = plot:FindFirstChild("StarterKitchen")
    if old then old:Destroy() end
    local kitchen = Instance.new("Model")
    kitchen.Name = "StarterKitchen"
    kitchen:SetAttribute("Stage", 1)
    local scale = area.Size.X / 90
    local frame = area.CFrame * CFrame.new(0, area.Size.Y / 2, 0)
    for _, info in ipairs(require(script.Parent.KitchenTemplate)) do
        local p = Instance.new("Part")
        p.Name = info.name
        p.Anchored = true
        p.Material = Enum.Material.Plastic
        p.Color = Color3.fromRGB(table.unpack(info.color))
        p.CanCollide = not info.invisible
        p.CanQuery = not info.invisible
        p.CanTouch = false
        p.Transparency = info.invisible and 1 or 0
        local size = Vector3.new(table.unpack(info.size)) * scale
        local cf = frame * CFrame.new(Vector3.new(table.unpack(info.position)) * scale)
        if info.shape == "Cylinder" then
            p.Shape = Enum.PartType.Cylinder
            p.Size = Vector3.new(size.Y, size.X, size.Z)
            p.CFrame = cf * CFrame.Angles(0, 0, math.pi / 2)
        else
            p.Size, p.CFrame = size, cf
        end
        for _, face in ipairs({"Top", "Bottom", "Left", "Right", "Front", "Back"}) do
            p[face .. "Surface"] = Enum.SurfaceType.Studs
        end
        p.Parent = kitchen
    end
    kitchen.Parent = plot
    for _, p in ipairs(plot:GetChildren()) do
        if p:IsA("BasePart") and (p.Name:find("Curb") or p.Name == "PlotNumber") then
            p.Color = Color3.fromRGB(63, 166, 156)
        end
    end
    return kitchen
end

return Layout
