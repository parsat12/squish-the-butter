assert(not game:GetService("RunService"):IsRunning(), "Stop Play first")
local folder = game:GetService("ReplicatedStorage"):FindFirstChild("ButterModels")
assert(folder, "Create ReplicatedStorage.ButterModels and import the models first")
for _, name in ipairs({"Plain", "Salted", "Golden", "Rainbow", "Cosmic"}) do
	local matches = {}
	for _, child in ipairs(folder:GetChildren()) do
		if child.Name == name then table.insert(matches, child) end
	end
	if #matches ~= 1 or not matches[1]:IsA("Model") then
		warn("Skipped " .. name .. ": expected exactly one Model of this name")
	else
		local model = matches[1]
		local body = model:FindFirstChild("ButterBody", true)
		if body and body:IsA("BasePart") then model.PrimaryPart = body end
		local size = model:GetExtentsSize()
		local longest = math.max(size.X, size.Y, size.Z)
		if longest > 0 then model:ScaleTo(model:GetScale() * 5 / longest) end
		for _, part in ipairs(model:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part.CanCollide = false
				part.Color = Color3.new(1, 1, 1)
				part.Material = Enum.Material.SmoothPlastic
				part.Transparency = 0
			elseif part:IsA("SurfaceAppearance") then
				part.Color = Color3.new(1, 1, 1)
			end
		end
		print("Ready:", name)
	end
end
