local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Workspace = game:GetService("Workspace")
local Config = require(game.ReplicatedStorage.Shared.GroceryCombatConfig)

local Combat = {}
Combat.__index = Combat

function Combat.new(remote, onFinish)
    local self = setmetatable({Active = {}, Remote = remote, OnFinish = onFinish}, Combat)
    local accumulated = 0
    RunService.Heartbeat:Connect(function(dt)
        accumulated += dt
        if accumulated < 0.1 then return end
        local elapsed = math.min(accumulated, 0.2)
        accumulated = 0
        for player, encounter in pairs(self.Active) do self:Step(player, encounter, elapsed) end
    end)
    Players.PlayerRemoving:Connect(function(player) self:Finish(player, false, "Left") end)
    return self
end

function Combat:Snapshot(player)
    local encounter = self.Active[player]
    if not encounter then return nil end
    local officers = {}
    for i, officer in ipairs(encounter.Officers) do
        officers[i] = {Position = officer.Position, Health = officer.Health, MaxHealth = encounter.Stats.Health,
            Attack = officer.Attack or 0}
    end
    return {Id = encounter.Id, Time = os.clock(), PickupId = encounter.PickupId, Tier = encounter.Tier,
        Floor = encounter.Floor.CFrame, Size = encounter.Floor.Size, Officers = officers,
        CeilingHeight = encounter.CeilingHeight,
        PlayerAttack = encounter.PlayerAttack or 0, PlayerHealth = encounter.Humanoid.Health,
        PlayerMaxHealth = encounter.Humanoid.MaxHealth}
end

function Combat:Finish(player, won, reason)
    local encounter = self.Active[player]
    if not encounter then return end
    self.Active[player] = nil
    if encounter.Death then encounter.Death:Disconnect() end
    if player.Parent == Players then
        self.Remote:FireClient(player, false)
        self.OnFinish(player, encounter.PickupId, encounter.ButterId, won, reason)
    end
end

function Combat:Start(player, pickupId, entry)
    if self.Active[player] then return false, "Defeat the officers before grabbing more butter." end
    local character = player.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    local floor = entry.Floor
    local stats = Config.Tiers[entry.ButterId]
    if not root or not humanoid or humanoid.Health <= 0 or not floor or not floor.Parent or not stats then
        return false, "This section is not ready for combat."
    end
    local localPosition = floor.CFrame:PointToObjectSpace(root.Position)
    if math.abs(localPosition.X) > floor.Size.X / 2 or math.abs(localPosition.Z) > floor.Size.Z / 2 then
        return false, "Enter the section before picking up its butter."
    end
    local now = os.clock()
    local ceiling = floor.Parent:FindFirstChild("Ceiling")
    local ceilingHeight = ceiling and (ceiling.Position.Y - floor.Position.Y - ceiling.Size.Y / 2) or 24
    local encounter = {Id = game:GetService("HttpService"):GenerateGUID(false), PickupId = pickupId,
        ButterId = entry.ButterId, Tier = entry.ButterId, Floor = floor, Stats = stats,
        Character = character, Humanoid = humanoid, Root = root, Started = now,
        NextPlayerAttack = now + 0.5, Officers = {}, CeilingHeight = ceilingHeight}
    for i = 1, stats.Count do
        local offset = Vector3.new((i - (stats.Count + 1) / 2) * 7, floor.Size.Y / 2 + 3,
            math.clamp(localPosition.Z - 18, -floor.Size.Z / 2 + 12, floor.Size.Z / 2 - 12))
        encounter.Officers[i] = {Position = floor.CFrame:PointToWorldSpace(offset), Health = stats.Health,
            NextAttack = now + 1 + i * 0.25, NextPath = 0, Path = {}, Waypoint = 1}
    end
    self.Active[player] = encounter
    encounter.Death = humanoid.Died:Connect(function() self:Finish(player, false, "Defeated") end)
    self.Remote:FireClient(player, self:Snapshot(player))
    return true
end

local function visible(encounter, from, to)
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    local characters = {}
    for _, player in ipairs(Players:GetPlayers()) do
        if player.Character then table.insert(characters, player.Character) end
    end
    params.FilterDescendantsInstances = characters
    return Workspace:Raycast(from, to - from, params) == nil
end

function Combat:Navigate(player, encounter, officer, target, now, dt)
    local delta = target - officer.Position
    delta = Vector3.new(delta.X, 0, delta.Z)
    if delta.Magnitude < 0.8 then return end
    local destination
    if visible(encounter, officer.Position, officer.Position + delta) then
        destination = officer.Position + delta
    else
        if not officer.Computing and now >= officer.NextPath then
            officer.Computing = true
            officer.NextPath = now + 1
            task.spawn(function()
                local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5,
                    AgentCanJump = false, WaypointSpacing = 4})
                local ok = pcall(function() path:ComputeAsync(officer.Position, target) end)
                if self.Active[player] ~= encounter or officer.Health <= 0 then return end
                officer.Computing = false
                if ok and path.Status == Enum.PathStatus.Success then
                    officer.Path = path:GetWaypoints()
                    officer.Waypoint = 2
                end
            end)
        end
        local waypoint = officer.Path[officer.Waypoint]
        if waypoint then
            destination = Vector3.new(waypoint.Position.X, officer.Position.Y, waypoint.Position.Z)
            if (destination - officer.Position).Magnitude < 2 then
                officer.Waypoint += 1
            end
        end
    end
    if destination then
        local direction = destination - officer.Position
        if direction.Magnitude > 0.1 then
            local step = direction.Unit * math.min(direction.Magnitude, encounter.Stats.Speed * dt)
            if visible(encounter, officer.Position, officer.Position + step) then
                officer.Position += step
            end
        end
    end
end

function Combat:Step(player, encounter, dt)
    if player.Character ~= encounter.Character or not encounter.Root.Parent or encounter.Humanoid.Health <= 0
        or not encounter.Floor:IsDescendantOf(Workspace) then
        self:Finish(player, false, "Reset")
        return
    end
    local now = os.clock()
    if now - encounter.Started > Config.MaxDuration then
        self:Finish(player, false, "Timed out")
        return
    end
    -- Server bounds stop jumping over, walking around, or deleting personal gates.
    local floor = encounter.Floor
    local position = floor.CFrame:PointToObjectSpace(encounter.Root.Position)
    local clamped = Vector3.new(math.clamp(position.X, -floor.Size.X / 2 + 2, floor.Size.X / 2 - 2),
        math.clamp(position.Y, floor.Size.Y / 2 + 2, math.max(5, encounter.CeilingHeight - 2)),
        math.clamp(position.Z, -floor.Size.Z / 2 + 3, floor.Size.Z / 2 - 3))
    if (clamped - position).Magnitude > 0.1 then
        encounter.Root.CFrame = CFrame.new(floor.CFrame:PointToWorldSpace(clamped)) * encounter.Root.CFrame.Rotation
        encounter.Root.AssemblyLinearVelocity = Vector3.zero
    end
    local target = encounter.Root.Position
    local nearest, nearestDistance = nil, Config.AttackRange
    for i, officer in ipairs(encounter.Officers) do
        if officer.Health > 0 then
            local angle = (i - 1) * math.pi * 2 / #encounter.Officers
            local pursuit = target + Vector3.new(math.cos(angle) * 3.5, 0, math.sin(angle) * 3.5)
            self:Navigate(player, encounter, officer, pursuit, now, dt)
            local guardPosition = floor.CFrame:PointToObjectSpace(officer.Position)
            officer.Position = floor.CFrame:PointToWorldSpace(Vector3.new(
                math.clamp(guardPosition.X, -floor.Size.X / 2 + 2, floor.Size.X / 2 - 2), guardPosition.Y,
                math.clamp(guardPosition.Z, -floor.Size.Z / 2 + 3, floor.Size.Z / 2 - 3)))
            local distance = (officer.Position - target).Magnitude
            if distance <= nearestDistance and visible(encounter, officer.Position, target) then
                nearest, nearestDistance = officer, distance
            end
        end
    end
    if nearest and now >= encounter.NextPlayerAttack then
        encounter.NextPlayerAttack = now + Config.PlayerAttackInterval
        nearest.Health = math.max(0, nearest.Health - Config.PlayerDamage)
        encounter.PlayerAttack = now
    end
    local remaining = 0
    for _, officer in ipairs(encounter.Officers) do
        if officer.Health > 0 then
            remaining += 1
            if (officer.Position - target).Magnitude <= Config.AttackRange and now >= officer.NextAttack
                and visible(encounter, officer.Position, target) then
                officer.NextAttack = now + encounter.Stats.AttackInterval
                officer.Attack = now
                encounter.Humanoid:TakeDamage(encounter.Stats.Damage)
                if encounter.Humanoid.Health <= 0 then self:Finish(player, false, "Defeated") return end
            end
        end
    end
    if remaining == 0 then self:Finish(player, true, "Escaped") return end
    self.Remote:FireClient(player, self:Snapshot(player))
end

return Combat
