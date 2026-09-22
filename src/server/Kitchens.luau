local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Layout = require(game.ReplicatedStorage.Shared.KitchenLayout)
local Kitchens = {}
Kitchens.__index = Kitchens

local function clearOwnerIndicator(plot)
    local indicator = plot:FindFirstChild("PlotOwnerIndicator")
    if indicator then indicator:Destroy() end
end

local function showOwnerIndicator(plot, player)
    clearOwnerIndicator(plot)
    local area = plot.BuildArea
    local height = area.Size.Y / 2 + 14
    local kitchen = plot:FindFirstChild("StarterKitchen")
    if kitchen then
        local box, size = kitchen:GetBoundingBox()
        height = math.max(height, box.Position.Y + size.Y / 2 - area.Position.Y + 5)
    end
    local indicator = Instance.new("BillboardGui")
    indicator.Name = "PlotOwnerIndicator"
    indicator.Adornee = area
    indicator.Size = UDim2.fromScale(6, 6)
    indicator.StudsOffsetWorldSpace = Vector3.new(0, height, 0)
    indicator.AlwaysOnTop = true
    indicator.MaxDistance = 300
    indicator.Active = false
    local head = Instance.new("ImageLabel")
    head.Name = "OwnerHead"
    head.BackgroundTransparency = 1
    head.Size = UDim2.fromScale(1, 1)
    head.ScaleType = Enum.ScaleType.Fit
    head.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=420&h=420", player.UserId)
    head.Parent = indicator
    indicator.Parent = plot
end

function Kitchens.new(map, data, createModel, openCracking)
    local self = setmetatable({Assignments = {}, Roamers = {}, Data = data, CreateModel = createModel, Plots = {}}, Kitchens)
    local plots = map and map:FindFirstChild("KitchenPlots")
    if plots then
        for i = 1, 8 do
            local plot = plots:FindFirstChild(string.format("Plot%02d", i))
            if plot and plot:FindFirstChild("BuildArea") then
                if not plot:FindFirstChild("StarterKitchen") then Layout.Build(plot) end
                if plot.StarterKitchen:GetAttribute("Stage") == nil then
                    plot.StarterKitchen:SetAttribute("Stage", 1)
                end
                local oldBeebohs = plot:FindFirstChild("KitchenBeebohs")
                if oldBeebohs then oldBeebohs:Destroy() end
                clearOwnerIndicator(plot)
                plot:SetAttribute("OwnerUserId", nil)
                table.insert(self.Plots, plot)
                local tablePart = plot.StarterKitchen:FindFirstChild("CrackingTable")
                if tablePart and openCracking then
                    local prompt = tablePart:FindFirstChild("KitchenCrackPrompt") or Instance.new("ProximityPrompt")
                    prompt.Name = "KitchenCrackPrompt"
                    prompt.ActionText = "Crack butter"
                    prompt.ObjectText = "Kitchen table"
                    prompt.MaxActivationDistance = 10
                    prompt.RequiresLineOfSight = false
                    prompt.Parent = tablePart
                    prompt.Triggered:Connect(function(player)
                        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
                        local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
                        if self.Assignments[player] == plot and root and humanoid and humanoid.Health > 0
                            and (root.Position - tablePart.Position).Magnitude <= 12 then
                            openCracking:FireClient(player, tablePart)
                        end
                    end)
                end
            end
        end
    end
    local elapsed, assignmentTimer = 0, 0
    RunService.Heartbeat:Connect(function(dt)
        elapsed += dt
        assignmentTimer += dt
        if assignmentTimer >= 1 then
            assignmentTimer = 0
            for _, player in ipairs(Players:GetPlayers()) do
                if data[player] and not self.Assignments[player] then self:Assign(player) end
            end
        end
        if elapsed < 0.1 then return end
        self:Step(math.min(elapsed, 0.25))
        elapsed = 0
    end)
    return self
end

local function ownerLabel(plot, text)
    local sign = plot:FindFirstChild("PlotNumber")
    local label = sign and sign:FindFirstChildWhichIsA("TextLabel", true)
    if label then label.Text = text end
end

function Kitchens:Assign(player)
    if self.Assignments[player] then return self.Assignments[player] end
    for _, plot in ipairs(self.Plots) do
        if plot.Parent and not plot:GetAttribute("OwnerUserId") then
            self.Assignments[player] = plot
            player:SetAttribute("KitchenPlot", plot.Name)
            player:SetAttribute("KitchenVisited", false)
            local area = plot.BuildArea
            player:SetAttribute("KitchenGuideTarget", area.CFrame:PointToWorldSpace(
                Vector3.new(0, area.Size.Y / 2 + 3, -area.Size.Z / 2 + 4)))
            plot:SetAttribute("OwnerUserId", player.UserId)
            ownerLabel(plot, player.DisplayName)
            showOwnerIndicator(plot, player)
            self:Rebuild(player)
            return plot
        end
    end
    return nil
end

function Kitchens:ClearModels(player)
    for _, item in ipairs(self.Roamers[player] or {}) do item.Model:Destroy() end
    self.Roamers[player] = nil
    local plot = self.Assignments[player]
    local old = plot and plot:FindFirstChild("KitchenBeebohs")
    if old then old:Destroy() end
end

function Kitchens:Release(player)
    self:ClearModels(player)
    local plot = self.Assignments[player]
    if plot and plot.Parent then
        clearOwnerIndicator(plot)
        plot:SetAttribute("OwnerUserId", nil)
        ownerLabel(plot, "Available")
    end
    self.Assignments[player] = nil
    player:SetAttribute("KitchenPlot", nil)
    player:SetAttribute("KitchenGuideTarget", nil)
    player:SetAttribute("KitchenVisited", nil)
end

function Kitchens:Rebuild(player)
    self:ClearModels(player)
    local plot = self.Assignments[player]
    local data = self.Data[player]
    local kitchen = plot and plot:FindFirstChild("StarterKitchen")
    local area = kitchen and kitchen:FindFirstChild("RoamArea")
    if not data or not area then return end
    local folder = Instance.new("Folder")
    folder.Name = "KitchenBeebohs"
    folder.Parent = plot
    local roamers = {}
    for _, index in ipairs(data.KitchenBeebohs) do
        local entry = data.Beebohs[index]
        if entry then
            local model = self.CreateModel(entry, folder)
            if model then
                local extent = model:GetExtentsSize()
                model:ScaleTo(model:GetScale() * 2 / math.max(extent.X, extent.Y, extent.Z, 0.01))
                local box, size = model:GetBoundingBox()
                local radius = math.sqrt(size.X * size.X + size.Z * size.Z) / 2
                local halfX = math.max(0, area.Size.X / 2 - radius - 0.15)
                local halfZ = math.max(0, area.Size.Z / 2 - radius - 0.15)
                local random = Random.new(player.UserId % 100000 + index * 139)
                local position = Vector3.new(random:NextNumber(-halfX, halfX), 0, random:NextNumber(-halfZ, halfZ))
                table.insert(roamers, {Model = model, Area = area, Position = position, Target = position,
                    HalfX = halfX, HalfZ = halfZ, Height = size.Y / 2 + 0.05,
                    Offset = box:ToObjectSpace(model:GetPivot()), Random = random, Pause = 0, Yaw = 0})
            end
        end
    end
    self.Roamers[player] = roamers
    self:Step(0)
end

function Kitchens:Step(dt)
    for player, plot in pairs(self.Assignments) do
        if not player:GetAttribute("KitchenVisited") then
            local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
            local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
            local area = plot:FindFirstChild("BuildArea")
            if root and humanoid and humanoid.Health > 0 and area then
                local point = area.CFrame:PointToObjectSpace(root.Position)
                if math.abs(point.X) <= area.Size.X / 2 and math.abs(point.Z) <= area.Size.Z / 2
                    and point.Y >= 0 and point.Y <= 12 then
                    player:SetAttribute("KitchenVisited", true)
                end
            end
        end
    end
    for _, roamers in pairs(self.Roamers) do
        for _, item in ipairs(roamers) do
            if item.Model.Parent and item.Area.Parent then
                local delta = item.Target - item.Position
                if delta.Magnitude < 0.15 then
                    item.Pause -= dt
                    if item.Pause <= 0 then
                        item.Target = Vector3.new(item.Random:NextNumber(-item.HalfX, item.HalfX), 0,
                            item.Random:NextNumber(-item.HalfZ, item.HalfZ))
                        item.Pause = item.Random:NextNumber(0.5, 2)
                    end
                else
                    item.Position += delta.Unit * math.min(delta.Magnitude, dt * 2.2)
                    item.Yaw = math.atan2(-delta.X, -delta.Z)
                end
                local cf = item.Area.CFrame * CFrame.new(item.Position.X, item.Height, item.Position.Z)
                    * CFrame.Angles(0, item.Yaw, 0)
                item.Model:PivotTo(cf * item.Offset)
            end
        end
    end
end

return Kitchens
