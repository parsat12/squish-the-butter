local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")
local Interaction = require(script.Parent.ButterInteraction)
local TableButter = {}
local active

local function place(source, tablePart, name, sizeLimit)
    local clone = source:Clone()
    local model = clone
    if clone:IsA("BasePart") then
        model = Instance.new("Model")
        clone.Parent = model
    end
    model.Name = name
    for _, item in ipairs(model:GetDescendants()) do
        if item:IsA("LuaSourceContainer") or item:IsA("ProximityPrompt") then item:Destroy()
        elseif item:IsA("BasePart") then
            item.Anchored = true
            item.CanCollide, item.CanTouch, item.CanQuery = false, false, true
        end
    end
    local size = model:GetExtentsSize()
    model:ScaleTo(model:GetScale() * sizeLimit / math.max(size.X, size.Y, size.Z, 0.01))
    model:PivotTo(tablePart.CFrame.Rotation * model:GetPivot().Rotation)
    local box, bounds = model:GetBoundingBox()
    local top = tablePart.CFrame:PointToWorldSpace(Vector3.new(0, tablePart.Size.Y / 2 + bounds.Y / 2 + 0.18, 0))
    model:PivotTo(CFrame.new(top - box.Position) * model:GetPivot())
    model.Parent = workspace
    return model
end

function TableButter.Start(tablePart, butterId, config, remote, applyResponse)
    if active then return false, "Finish your current butter first." end
    local sources = ReplicatedStorage:FindFirstChild("ButterModels")
    local source = sources and (sources:FindFirstChild(butterId) or sources:FindFirstChild(config.Name))
    if not source then return false, "That butter model is missing from ButterModels." end
    local model = place(source, tablePart, "LocalTableButter", math.min(4, tablePart.Size.X * 0.7))
    local effect = Interaction.new(model, workspace, nil, workspace.CurrentCamera)
    local session = {Model = model, Connections = {}, Effect = effect}
    active = session
    local originalPrompt = tablePart:FindFirstChild("KitchenCrackPrompt")
    if originalPrompt then originalPrompt.Enabled = false end
    local function close()
        if active ~= session then return end
        active = nil
        for _, connection in ipairs(session.Connections) do connection:Disconnect() end
        if session.Effect then session.Effect:Destroy() end
        if session.Model then session.Model:Destroy() end
        if originalPrompt and originalPrompt.Parent then originalPrompt.Enabled = true end
    end
    local stage, busy = 0, false
    local function hit(result)
        if busy or active ~= session then return end
        busy = true
        stage += 1
        effect:Hit(result, stage)
        if stage < 3 then task.delay(0.3, function() busy = false end) return end
        task.delay(0.6, function()
            if active ~= session then return end
            local ok, response = pcall(function() return remote:InvokeServer(butterId) end)
            if ok then applyResponse(response) else applyResponse({Message = "Unable to crack butter. Try again."}) end
            if active ~= session then return end
            if not ok or not response or not response.Ok then close() return end
            effect:Destroy()
            session.Effect = nil
            model:Destroy()
            local folder = ReplicatedStorage:FindFirstChild("BeebohModels")
            local prize = response.Prize
            local sourcePrize = folder and (folder:FindFirstChild(prize.Id) or folder:FindFirstChild(prize.Name))
            local fallback
            if not sourcePrize then
                fallback = Instance.new("Part")
                fallback.Shape = Enum.PartType.Ball
                fallback.Color = Color3.fromRGB(106, 199, 239)
                sourcePrize = fallback
            end
            session.Model = place(sourcePrize, tablePart, "LocalTablePrize", 1.8)
            if fallback then fallback:Destroy() end
            local sparkles = Instance.new("Sparkles")
            sparkles.SparkleColor = Color3.fromRGB(255, 221, 102)
            sparkles.Parent = session.Model:FindFirstChildWhichIsA("BasePart", true)
            task.delay(3, close)
        end)
    end
    table.insert(session.Connections, UserInputService.InputBegan:Connect(function(input, processed)
        if processed or busy then return end
        if input.KeyCode == Enum.KeyCode.E or input.KeyCode == Enum.KeyCode.ButtonX then
            local p = model:FindFirstChildWhichIsA("BasePart", true)
            if p then hit({Instance = p, Position = p.Position, Normal = Vector3.yAxis}) end
            return
        end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local inset = GuiService:GetGuiInset()
        local ray = workspace.CurrentCamera:ViewportPointToRay(input.Position.X - inset.X, input.Position.Y - inset.Y)
        local params = RaycastParams.new()
        params.FilterType = Enum.RaycastFilterType.Include
        params.FilterDescendantsInstances = {model}
        local result = workspace:Raycast(ray.Origin, ray.Direction * 100, params)
        if result then hit(result) end
    end))
    table.insert(session.Connections, RunService.Heartbeat:Connect(function()
        local character = Players.LocalPlayer.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if not tablePart.Parent or not root or not humanoid or humanoid.Health <= 0
            or (root.Position - tablePart.Position).Magnitude > 14 then close() end
    end))
    return true
end

return TableButter
