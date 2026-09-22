local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Config = require(script.Parent.GroceryCombatConfig)
local Client = {}

local function part(parent, name, size, color, offset)
    local p = Instance.new("Part")
    p.Name = name
    p.Size = size
    p.Color = color
    p.Anchored = true
    p.CanCollide = false
    p.CanTouch = false
    p.CanQuery = false
    p.Material = Enum.Material.Plastic
    for _, face in ipairs({"Top", "Bottom", "Left", "Right", "Front", "Back"}) do
        p[face .. "Surface"] = Enum.SurfaceType.Studs
    end
    p.Parent = parent
    return {Part = p, Offset = offset or CFrame.identity}
end

local function officer(parent)
    local model = Instance.new("Model")
    model.Name = "PoliceOfficer"
    local blue, dark, skin = Color3.fromRGB(48, 102, 191), Color3.fromRGB(33, 38, 53), Color3.fromRGB(237, 191, 142)
    local pieces = {}
    local function add(name, size, color, x, y, z)
        local piece = part(model, name, size, color, CFrame.new(x, y, z))
        table.insert(pieces, piece)
        return piece.Part
    end
    add("Uniform", Vector3.new(2, 2, 1), blue, 0, 0, 0)
    local head = add("Head", Vector3.new(1.65, 1.65, 1.3), skin, 0, 1.8, 0)
    add("Cap", Vector3.new(1.9, 0.45, 1.6), blue, 0, 2.65, 0)
    add("CapBrim", Vector3.new(2, 0.15, 1), dark, 0, 2.4, -0.65)
    add("Badge", Vector3.new(0.35, 0.5, 0.12), Color3.fromRGB(255, 214, 65), -0.45, 0.45, -0.56)
    add("Belt", Vector3.new(2.1, 0.3, 1.1), dark, 0, -0.75, 0)
    add("LeftArm", Vector3.new(0.7, 1.9, 0.8), blue, -1.4, 0, 0)
    add("RightArm", Vector3.new(0.7, 1.9, 0.8), blue, 1.4, 0, 0)
    add("LeftLeg", Vector3.new(0.85, 1.8, 0.9), dark, -0.52, -1.8, 0)
    add("RightLeg", Vector3.new(0.85, 1.8, 0.9), dark, 0.52, -1.8, 0)
    for _, x in ipairs({-0.32, 0.32}) do
        add("Eye", Vector3.new(0.15, 0.18, 0.08), dark, x, 1.9, -0.68)
    end
    local gui = Instance.new("BillboardGui")
    gui.Size = UDim2.fromOffset(70, 8)
    gui.StudsOffset = Vector3.new(0, 1.7, 0)
    gui.AlwaysOnTop = false
    gui.Parent = head
    local bg = Instance.new("Frame")
    bg.Size = UDim2.fromScale(1, 1)
    bg.BackgroundColor3 = dark
    bg.BorderSizePixel = 0
    bg.Parent = gui
    local health = bg:Clone()
    health.BackgroundColor3 = Color3.fromRGB(91, 218, 142)
    health.Parent = bg
    model.Parent = parent
    return {Model = model, Pieces = pieces, Health = health, Punch = 0, LastAttack = 0}
end

local function pose(rig, cf, phase, walking)
    for _, piece in ipairs(rig.Pieces) do
        local offset = piece.Offset
        if piece.Part.Name == "RightArm" then
            offset *= CFrame.Angles(-math.sin(rig.Punch * math.pi) * 1.7, 0, 0)
        elseif walking and piece.Part.Name:find("Leg") then
            offset *= CFrame.Angles(math.sin(phase) * (piece.Part.Name == "LeftLeg" and 0.35 or -0.35), 0, 0)
        end
        piece.Part.CFrame = cf * offset
    end
end

function Client.Start(remote)
    local player = Players.LocalPlayer
    local folder = Instance.new("Folder")
    folder.Name = "LocalGroceryPolice"
    folder.Parent = Workspace
    local active, rigs, gates, idle = nil, {}, nil, {}
    local finished = {}
    local idleStore, lastIdleCheck = nil, 0
    local lastPlayerAttack, punchTime = 0, 0
    local punchingJoint, originalC0
    local gui = Instance.new("ScreenGui")
    gui.Name = "GroceryCombatHUD"
    gui.ResetOnSpawn = false
    gui.Parent = player:WaitForChild("PlayerGui")
    local status = Instance.new("TextLabel")
    status.AnchorPoint = Vector2.new(0.5, 0)
    status.Position = UDim2.new(0.5, 0, 0, 72)
    status.Size = UDim2.new(0.8, 0, 0, 50)
    local constraint = Instance.new("UISizeConstraint")
    constraint.MaxSize = Vector2.new(360, 50)
    constraint.Parent = status
    status.BackgroundColor3 = Color3.fromRGB(31, 35, 43)
    status.BackgroundTransparency = 0.15
    status.TextColor3 = Color3.fromRGB(255, 241, 211)
    status.Font = Enum.Font.GothamBold
    status.TextSize = 17
    status.TextWrapped = true
    status.Visible = false
    status.Parent = gui

    local function clear()
        if punchingJoint and punchingJoint.Parent then punchingJoint.C0 = originalC0 end
        punchingJoint, originalC0, punchTime = nil, nil, 0
        for _, rig in ipairs(rigs) do rig.Model:Destroy() end
        rigs = {}
        if gates then gates:Destroy() gates = nil end
        active = nil
        status.Visible = false
    end
    local function update(snapshot)
        if not snapshot then
            if active then finished[active.Id] = true end
            clear()
            return
        end
        if finished[snapshot.Id] then return end
        if active and active.Id == snapshot.Id and snapshot.Time < active.Time then return end
        if not active or active.Id ~= snapshot.Id then
            clear()
            gates = Instance.new("Folder")
            gates.Name = "PersonalSectionGates"
            gates.Parent = folder
            local height = snapshot.CeilingHeight or 20
            for _, side in ipairs({-1, 1}) do
                local cf = snapshot.Floor * CFrame.new(0, height / 2, side * (snapshot.Size.Z / 2 - 1))
                local wall = part(gates, "Barrier", Vector3.new(snapshot.Size.X, height, 1), Color3.fromRGB(222, 87, 74)).Part
                wall.CFrame = cf
                wall.Transparency = 0.8
                wall.CanCollide = true
                for x = -snapshot.Size.X / 2, snapshot.Size.X / 2, 4 do
                    local bar = part(gates, "SecurityBar", Vector3.new(0.5, height, 0.7), Color3.fromRGB(243, 186, 61)).Part
                    bar.CFrame = cf * CFrame.new(x, 0, 0)
                end
            end
        end
        active = snapshot
        local alive = 0
        for i, data in ipairs(snapshot.Officers) do
            if not rigs[i] then rigs[i] = officer(folder) rigs[i].Position = data.Position end
            local rig = rigs[i]
            rig.Model.Parent = data.Health > 0 and folder or nil
            rig.Health.Size = UDim2.fromScale(math.clamp(data.Health / data.MaxHealth, 0, 1), 1)
            if data.Attack ~= rig.LastAttack then rig.Punch = 1 rig.LastAttack = data.Attack end
            if data.Health > 0 then alive += 1 end
        end
        if snapshot.PlayerAttack ~= lastPlayerAttack then
            lastPlayerAttack = snapshot.PlayerAttack
            punchTime = 0.25
        end
        status.Text = string.format("%s | %d officers\nHealth %d / %d", snapshot.Tier, alive,
            math.ceil(snapshot.PlayerHealth), math.ceil(snapshot.PlayerMaxHealth))
        status.Visible = true
    end
    remote.OnClientEvent:Connect(update)
    RunService.RenderStepped:Connect(function(dt)
        local now = os.clock()
        if now - lastIdleCheck > 1 then
            lastIdleCheck = now
            local map = Workspace:FindFirstChild("SquishTheButterMap")
            local store = map and map:FindFirstChild("GroceryStore")
            if store ~= idleStore then
                for _, entry in ipairs(idle) do entry.Rig.Model:Destroy() end
                idle = {}
                idleStore = store
            end
            if store and #idle == 0 then
                for _, section in ipairs(store:GetChildren()) do
                    local tier = section.Name:match("^Section%d+_(%a+)$")
                    local spec = tier and Config.Tiers[tier]
                    local floor = section:FindFirstChild("OpenFloor")
                    if spec and floor then
                        for i = 1, spec.Count do
                            local rig = officer(folder)
                            table.insert(idle, {Rig = rig, Tier = tier, CFrame = floor.CFrame *
                                CFrame.new((i - (spec.Count + 1) / 2) * 7, floor.Size.Y / 2 + 3, 0)})
                        end
                    end
                end
            end
        end
        for _, entry in ipairs(idle) do
            entry.Rig.Model.Parent = folder
            if active and active.Tier == entry.Tier then entry.Rig.Model.Parent = nil end
            pose(entry.Rig, entry.CFrame, 0, false)
        end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        if active and root then
            for i, rig in ipairs(rigs) do
                local target = active.Officers[i].Position
                local moving = (target - rig.Position).Magnitude > 0.05
                rig.Position = rig.Position:Lerp(target, math.min(1, dt * 15))
                local look = Vector3.new(root.Position.X, rig.Position.Y, root.Position.Z)
                local cf = (look - rig.Position).Magnitude > 0.05 and CFrame.lookAt(rig.Position, look) or CFrame.new(rig.Position)
                rig.Punch = math.max(0, rig.Punch - dt * 4)
                pose(rig, cf, now * 9, moving)
            end
        end
        if punchTime > 0 and character then
            punchTime = math.max(0, punchTime - dt)
            local shoulder = character:FindFirstChild("RightShoulder", true) or character:FindFirstChild("Right Shoulder", true)
            if shoulder and shoulder:IsA("Motor6D") then
                if punchingJoint ~= shoulder then
                    if punchingJoint and punchingJoint.Parent then punchingJoint.C0 = originalC0 end
                    punchingJoint, originalC0 = shoulder, shoulder.C0
                end
                shoulder.C0 = originalC0 * CFrame.Angles(-math.sin(punchTime / 0.25 * math.pi) * 1.3, 0, 0)
            end
        elseif punchingJoint then
            if punchingJoint.Parent then punchingJoint.C0 = originalC0 end
            punchingJoint, originalC0 = nil, nil
        end
    end)
    return update
end

return Client
