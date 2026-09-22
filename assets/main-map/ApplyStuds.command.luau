-- Run in Studio's Command Bar with Play stopped. Only changes the map.
assert(not game:GetService("RunService"):IsRunning(), "Stop Play before applying studs.")
local map = workspace:FindFirstChild("SquishTheButterMap")
assert(map, "Import SquishTheButterMap into Workspace first.")
local count = 0
for _, part in ipairs(map:GetDescendants()) do
    if part:IsA("Part") and part.Transparency < 1 then
        part.Material = Enum.Material.Plastic
        for _, face in ipairs({"Top", "Bottom", "Left", "Right", "Front", "Back"}) do
            part[face .. "Surface"] = Enum.SurfaceType.Studs
        end
        count += 1
    end
end
print("Studded map updated: " .. count .. " parts. Save your place to keep the changes.")
