local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ButterInteraction = {}
ButterInteraction.__index = ButterInteraction
local DENT_DURATION = 0.9

function ButterInteraction.new(model, world, viewport, camera)
	local self = setmetatable({
		model = model, world = world, viewport = viewport, camera = camera,
		chips = {}, bones = {}, pulses = {}, broken = {}, groups = {},
	}, ButterInteraction)
	local _, size = model:GetBoundingBox()
	self.radius = math.max(size.X, size.Y, size.Z) * 0.19
	self.depth = math.min(size.X, size.Y, size.Z) * 0.24
	for _, item in ipairs(model:GetDescendants()) do
		if item:IsA("BasePart") then
			item.CanQuery = true
			if string.match(item.Name, "^WaxChip_") then
				table.insert(self.chips, item)
				local group = string.match(item.Name, "^(WaxChip_%d+)")
				if group and (not self.groups[group] or string.find(item.Name, "wrapper")) then
					self.groups[group] = item.CFrame
				end
			end
		elseif item:IsA("Bone") and string.match(item.Name, "^Dent_") then
			table.insert(self.bones, item)
		end
	end
	if #self.bones == 0 then
		warn("[ButterInteraction] No Dent_ bones found. Import the prepared FBX with Rig Type set to Custom; wrapper pieces alone cannot deform the butter.")
	else
		print(string.format("[ButterInteraction] Ready: %d dent bones, %d wrapper pieces", #self.bones, #self.chips))
	end
	self.connection = RunService.RenderStepped:Connect(function()
		local now = os.clock()
		for index = #self.pulses, 1, -1 do
			if now - self.pulses[index].time > DENT_DURATION then
				table.remove(self.pulses, index)
			end
		end
		for _, bone in ipairs(self.bones) do
			local displacement = Vector3.zero
			for _, pulse in ipairs(self.pulses) do
				local weight = pulse.weights[bone] or 0
				local age = now - pulse.time
				-- Hold the dent while the opaque wrapper pieces move away.
				local attack = math.sin(math.pi * math.clamp(age / 0.12, 0, 1) / 2)
				local release = 1 - math.clamp((age - 0.42) / (DENT_DURATION - 0.42), 0, 1)
				displacement -= pulse.normal * self.depth * weight * attack * release * release
			end
			if displacement.Magnitude > self.depth then
				displacement = displacement.Unit * self.depth
			end
			bone.Transform = CFrame.new(bone.WorldCFrame:VectorToObjectSpace(displacement))
		end
	end)
	return self
end

function ButterInteraction:Raycast(screenPosition)
	local size = self.viewport.AbsoluteSize
	local point = screenPosition - self.viewport.AbsolutePosition
	if size.X <= 0 or size.Y <= 0 or point.X < 0 or point.Y < 0 or point.X > size.X or point.Y > size.Y then
		return nil
	end
	-- ViewportFrame cameras don't use the main window's viewport dimensions.
	local tangent = math.tan(math.rad(self.camera.FieldOfView) / 2)
	local direction = Vector3.new((2 * point.X / size.X - 1) * size.X / size.Y * tangent,
		(1 - 2 * point.Y / size.Y) * tangent, -1).Unit
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { self.model }
	return self.world:Raycast(self.camera.CFrame.Position,
		self.camera.CFrame:VectorToWorldSpace(direction) * 1000, params)
end

function ButterInteraction:Hit(result, stage)
	local weights = {}
	local nearestSquared = math.huge
	for _, bone in ipairs(self.bones) do
		local offset = bone.WorldCFrame.Position - result.Position
		local distanceSquared = offset:Dot(offset)
		weights[bone] = distanceSquared
		nearestSquared = math.min(nearestSquared, distanceSquared)
	end
	-- A sparse imported rig should still move at the nearest control point.
	for bone, distanceSquared in pairs(weights) do
		weights[bone] = math.exp(-3 * (distanceSquared - nearestSquared) / self.radius ^ 2)
	end
	table.insert(self.pulses, { weights = weights, normal = result.Normal, time = os.clock() })
	local nearestGroup = string.match(result.Instance.Name, "^(WaxChip_%d+)")
	for _, chip in ipairs(self.chips) do
		local group = string.match(chip.Name, "^(WaxChip_%d+)")
		local origin = self.groups[group] or chip.CFrame
		local distance = (origin.Position - result.Position).Magnitude
		local sameGroup = nearestGroup and group == nearestGroup
		if not self.broken[chip] and (stage == 3 or sameGroup or distance < self.radius * 0.85) then
			self.broken[chip] = true
			chip.CanQuery = false
			local outward = origin.Position - result.Position
			if outward.Magnitude > 0.001 then
				outward = outward.Unit
			else
				outward = result.Normal
			end
			local target = origin + (result.Normal * 0.7 + outward * 0.5) * self.radius
			target *= CFrame.Angles(math.rad(25), math.rad(-18), math.rad(30))
			target *= origin:ToObjectSpace(chip.CFrame)
			TweenService:Create(chip, TweenInfo.new(0.55, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
				CFrame = target, Transparency = 1,
			}):Play()
		end
	end
end

function ButterInteraction:Destroy()
	self.connection:Disconnect()
	for _, bone in ipairs(self.bones) do
		bone.Transform = CFrame.identity
	end
end

return ButterInteraction
