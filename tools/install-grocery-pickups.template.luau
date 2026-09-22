assert(not game:GetService("RunService"):IsRunning(), "Stop Play first!")
local map = workspace:FindFirstChild("SquishTheButterMap")
local store = map and map:FindFirstChild("GroceryStore")
assert(store, "GroceryStore is missing.")
local models = game.ReplicatedStorage:FindFirstChild("ButterModels")
assert(models, "Put your actual butter models in ReplicatedStorage.ButterModels first.")
local editor = game:GetService("ScriptEditorService")
local edits = {__SOURCES__}
local function resolve(path)
    local current = game
    for _, name in ipairs(string.split(path, ".")) do
        current = current:FindFirstChild(name)
        assert(current, "Missing " .. path .. "; connect your existing game first.")
    end
    return current
end
for _, edit in ipairs(edits) do
    local parent = resolve(edit.Parent)
    local existing = parent:FindFirstChild(edit.Name)
    if existing then
        assert(existing.ClassName == edit.Class, "Wrong script type: " .. existing:GetFullName())
        assert(not editor:FindScriptDocument(existing), "Close the " .. edit.Name .. " script tab and try again.")
    end
end
local backup = Instance.new("Folder")
backup.Name = "GroceryPickupBackup_" .. game:GetService("HttpService"):GenerateGUID(false)
backup.Parent = game:GetService("ServerStorage")
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
    assert(target.Source == edit.Source, "Script update failed: " .. edit.Name)
    if target:IsA("BaseScript") then target.Disabled = false end
end
local module = game.ServerScriptService.Server.GroceryPickups:Clone()
module.Parent = backup
local ok, result = pcall(function() return require(module).Build(store) end)
module:Destroy()
assert(ok, "Scripts installed, but display preview failed: " .. tostring(result))
local approach = map:FindFirstChild("GroceryApproach")
local path = approach and approach:FindFirstChild("MainPath")
local scale = path and path.Size.X / 64 or 0.5
for _, fixture in ipairs(store:GetDescendants()) do
    if fixture:IsA("BasePart") and fixture.Name == "CeilingLight" then
        local light = fixture:FindFirstChild("AccentLight") or Instance.new("PointLight")
        light.Name = "AccentLight"
        light.Color = fixture.Color
        light.Brightness = 0.12
        light.Range = 110 * scale
        light.Shadows = false
        light.Enabled = true
        light.Parent = fixture
    end
end
local count = 0
for _ in pairs(result) do count += 1 end
print("GROCERY COMBAT READY: " .. count .. " real butter displays, personal police encounters, automatic combat, soft lights. Save, then press Play!")
