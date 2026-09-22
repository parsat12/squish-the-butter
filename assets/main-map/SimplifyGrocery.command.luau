assert(not game:GetService("RunService"):IsRunning(), "Stop Play first!")
local map = workspace:FindFirstChild("SquishTheButterMap")
local store = map and map:FindFirstChild("GroceryStore")
assert(store, "GroceryStore not found!")
local panels = {FoodAdvertisement = true, ButterLabel = true, PriceSign = true, SaltLabel = true, FinalValue = true}
for _, object in ipairs(store:GetDescendants()) do
    if object:IsA("Light") then
        object.Enabled = false
        object.Brightness = 0
    elseif object:IsA("SurfaceGui") or object:IsA("BillboardGui") then
        object:Destroy()
    elseif object:IsA("BasePart") then
        if panels[object.Name] then
            object:Destroy()
        elseif object.Material == Enum.Material.Neon then
            object.Material = Enum.Material.Plastic
        end
    end
end
game:GetService("StarterPlayer").CharacterWalkSpeed = 24
print("Grocery glow and signs removed. Walk speed set to 24 for new spawns. Save, then press Play!")
