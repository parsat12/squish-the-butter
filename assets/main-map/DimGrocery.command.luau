assert(not game:GetService("RunService"):IsRunning(), "Stop Play first!")
local map = workspace:FindFirstChild("SquishTheButterMap")
local store = map and map:FindFirstChild("GroceryStore")
assert(store, "GroceryStore not found inside SquishTheButterMap!")
local count = 0
for _, light in ipairs(store:GetDescendants()) do
    if light:IsA("Light") and light.Name == "AccentLight" then
        light.Brightness = light.Parent.Name == "PortalSegment" and 0.2 or 0.55
        count += 1
    end
end
print("Dimmed " .. count .. " grocery lights. Save your place!")
