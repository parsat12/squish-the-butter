-- Stop Play, then run this entire file in Studio's Command Bar.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing the grocery store.")
local map = workspace:FindFirstChild("SquishTheButterMap")
assert(map and map:IsA("Model"), "SquishTheButterMap must be in Workspace.")
local approach = map:FindFirstChild("GroceryApproach")
local path = approach and approach:FindFirstChild("MainPath")
assert(path and path:IsA("BasePart"), "The map's GroceryApproach.MainPath is missing.")
-- Measure the actual path so this also works after scaling or moving the map.
local scale = path.Size.X / 64
assert(math.abs(path.Size.Z / 150 - scale) < 0.01, "The path was stretched unevenly; restore its proportions first.")
local data = game:GetService("HttpService"):JSONDecode([==[__GROCERY_JSON__]==])
local store = Instance.new("Model")
store.Name = "GroceryStore"
local ok, problem = pcall(function()
    local groups = {GroceryStore = store}
    for index, info in ipairs(data) do
        local parent = store
        local key = "GroceryStore"
        local sections = string.split(info.group, "/")
        for i = 2, #sections do
            key ..= "/" .. sections[i]
            if not groups[key] then
                local group = Instance.new("Model")
                group.Name = sections[i]
                group.Parent = parent
                groups[key] = group
            end
            parent = groups[key]
        end
        local part = Instance.new("Part")
        part.Name = info.name
        part.Anchored = true
        part.CanCollide = info.collide ~= false
        part.Material = Enum.Material.Plastic
        part.Color = Color3.fromRGB(table.unpack(info.color))
        part.Transparency = info.transparency or 0
        part.Size = Vector3.new(table.unpack(info.size))
        part.CFrame = CFrame.new(table.unpack(info.position))
            * CFrame.Angles(0, info.yaw or 0, 0) * CFrame.Angles(0, 0, info.roll or 0)
        for _, face in ipairs({"Top", "Bottom", "Left", "Right", "Front", "Back"}) do
            part[face .. "Surface"] = Enum.SurfaceType.Studs
        end
        part.Parent = parent
        if info.label then
            local gui = Instance.new("SurfaceGui")
            gui.Name = "Label"
            gui.Face = Enum.NormalId.Back
            gui.CanvasSize = Vector2.new(800, 800 * info.size[2] / info.size[1])
            gui.Parent = part
            local label = Instance.new("TextLabel")
            label.Size = UDim2.fromScale(1, 1)
            label.BackgroundTransparency = 1
            label.Text = info.label
            label.TextScaled = true
            label.Font = Enum.Font.FredokaOne
            label.TextColor3 = Color3.fromRGB(table.unpack(info.text_color or {245, 249, 246}))
            label.TextStrokeColor3 = Color3.fromRGB(45, 49, 65)
            label.TextStrokeTransparency = 0.8
            label.Parent = gui
        end
        if info.light then
            local light = Instance.new("PointLight")
            light.Name = "AccentLight"
            light.Color = Color3.fromRGB(table.unpack(info.light.color))
            light.Brightness = info.light.brightness
            light.Range = info.light.range
            light.Shadows = false
            light.Parent = part
        end
        if index % 150 == 0 then task.wait() end
    end
    store.WorldPivot = CFrame.new(0, 0.18, -335)
    store:ScaleTo(scale)
    store:PivotTo(path.CFrame)
end)
if not ok then
    store:Destroy()
    error("Grocery build failed; your existing store was not changed: " .. tostring(problem))
end
local old = map:FindFirstChild("GroceryStore")
if old then
    local backup = Instance.new("Folder")
    backup.Name = "GroceryBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
    backup.Parent = game:GetService("ServerStorage")
    old.Parent = backup
end
store.Parent = map
game:GetService("Selection"):Set({store})
print(string.format("GROCERY COMPLETE: 5 sections, %d studded parts, scale %.3f. Save your place!", #data, scale))
