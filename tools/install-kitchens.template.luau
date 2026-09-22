assert(not game:GetService("RunService"):IsRunning(), "Stop Play before installing kitchens.")
local map = workspace:FindFirstChild("SquishTheButterMap")
local plots = map and map:FindFirstChild("KitchenPlots")
assert(plots, "The map's KitchenPlots folder is missing.")
for i = 1, 8 do
    local plot = plots:FindFirstChild(string.format("Plot%02d", i))
    local area = plot and plot:FindFirstChild("BuildArea")
    assert(area and area:IsA("BasePart"), "Each of the eight plots needs BuildArea.")
    assert(math.abs(area.Size.X / 90 - area.Size.Z / 82) < 0.01, "A plot is stretched unevenly.")
end
local edits = {__SOURCES__}
local editor = game:GetService("ScriptEditorService")
local function resolve(path)
    local current = game
    for _, name in ipairs(string.split(path, ".")) do
        current = current:FindFirstChild(name)
        assert(current, "Missing " .. path)
    end
    return current
end
for _, edit in ipairs(edits) do
    local target = resolve(edit.Parent):FindFirstChild(edit.Name)
    if target then
        assert(target.ClassName == edit.Class, "Unexpected script type for " .. edit.Name)
        assert(not editor:FindScriptDocument(target), "Close the " .. edit.Name .. " script tab, then try again.")
    end
end
local backup = Instance.new("Folder")
backup.Name = "KitchenBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
backup.Parent = game.ServerStorage
for _, edit in ipairs(edits) do
    local parent = resolve(edit.Parent)
    local target = parent:FindFirstChild(edit.Name)
    if target then
        local saved = target:Clone()
        saved.Source = editor:GetEditorSource(target)
        if saved:IsA("BaseScript") then saved.Disabled = true end
        saved:SetAttribute("OriginalPath", target:GetFullName())
        saved.Parent = backup
    else
        target = Instance.new(edit.Class)
        target.Name = edit.Name
        target.Parent = parent
    end
    target.Source = edit.Source
    assert(target.Source == edit.Source, "Source update failed for " .. edit.Name)
    if target:IsA("BaseScript") then target.Disabled = false end
end
local temporary = Instance.new("Folder")
temporary.Name = "KitchenBuildTemporary"
temporary.Parent = backup
game.ReplicatedStorage.Shared.KitchenTemplate:Clone().Parent = temporary
local module = game.ReplicatedStorage.Shared.KitchenLayout:Clone()
module.Parent = temporary
local ok, failure = pcall(function()
    local layout = require(module)
    for i = 1, 8 do
        local plot = plots:FindFirstChild(string.format("Plot%02d", i))
        local old = plot:FindFirstChild("StarterKitchen")
        if old and __REBUILD_KITCHENS__ then
            local saved = old:Clone()
            saved.Name = plot.Name .. "_PreviousKitchen"
            saved.Parent = backup
        end
        if not old or __REBUILD_KITCHENS__ then layout.Build(plot) end
    end
end)
temporary:Destroy()
assert(ok, "Kitchen build failed; backups are in ServerStorage: " .. tostring(failure))
print("KITCHENS READY: 8 identical kitchens at your map scale. Save, then press Play. Select a Beeboh in inventory and choose Place in kitchen.")
