local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local PathfindingService = game:GetService("PathfindingService")
local Guide = {}

function Guide.Start()
    local player = Players.LocalPlayer
    local folder = Instance.new("Folder")
    folder.Name = "PersonalKitchenArrow"
    folder.Parent = workspace
    local pool, points = {}, {}
    local lastTarget, computing, lastPath, lastDraw = nil, false, 0, 0
    local function hide()
        for _, p in ipairs(pool) do p.Transparency = 1 end
    end
    local function draw(index, cf, size)
        local p = pool[index]
        if not p then
            p = Instance.new("Part")
            p.Name = "Arrow"
            p.Anchored = true
            p.CanCollide, p.CanTouch, p.CanQuery = false, false, false
            p.Material = Enum.Material.Plastic
            p.Color = Color3.fromRGB(255, 205, 48)
            p.CastShadow = false
            p.Parent = folder
            pool[index] = p
        end
        p.Size, p.CFrame, p.Transparency = size, cf, 0
    end
    RunService.Heartbeat:Connect(function()
        local target = player:GetAttribute("KitchenGuideTarget")
        local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
        if not target or player:GetAttribute("KitchenVisited") or not root then hide() return end
        if target ~= lastTarget then points = {} lastTarget = target lastPath = 0 end
        local now = os.clock()
        if not computing and now - lastPath > 1 then
            computing, lastPath = true, now
            local start, requestedTarget, character = root.Position, target, player.Character
            task.spawn(function()
                local path = PathfindingService:CreatePath({AgentRadius = 2, AgentHeight = 5, AgentCanJump = true})
                local ok = pcall(function() path:ComputeAsync(start, requestedTarget) end)
                computing = false
                if player.Character ~= character or player:GetAttribute("KitchenGuideTarget") ~= requestedTarget
                    or player:GetAttribute("KitchenVisited") then return end
                points = {}
                if ok and path.Status == Enum.PathStatus.Success then
                    for _, waypoint in ipairs(path:GetWaypoints()) do table.insert(points, waypoint.Position) end
                else
                    points = {start, requestedTarget}
                end
            end)
        end
        if now - lastDraw < 0.1 then return end
        lastDraw = now
        hide()
        local route = {root.Position}
        local nearest, nearestDistance = 1, math.huge
        for i, point in ipairs(points) do
            local distance = (point - root.Position).Magnitude
            if distance < nearestDistance then nearest, nearestDistance = i, distance end
        end
        for i = nearest + 1, #points do table.insert(route, points[i]) end
        if #route == 1 then table.insert(route, target) end
        local totalLength = 0
        for i = 1, #route - 1 do totalLength += (route[i + 1] - route[i]).Magnitude end
        local spacing = math.max(4, totalLength / 110)
        local count, carry = 0, 1
        for i = 1, #route - 1 do
            local a, b = route[i], route[i + 1]
            local direction = Vector3.new(b.X - a.X, 0, b.Z - a.Z)
            local length = direction.Magnitude
            if length < 0.01 then continue end
            local distance = carry
            while distance <= length and count < 360 do
                local position = a:Lerp(b, distance / length)
                position = Vector3.new(position.X, target.Y - 2.75, position.Z)
                local cf = CFrame.lookAt(position, position + direction.Unit)
                count += 1
                draw(count, cf * CFrame.new(0, 0, 0.6), Vector3.new(0.2, 0.12, 1.4))
                for _, side in ipairs({-1, 1}) do
                    count += 1
                    draw(count, cf * CFrame.new(side * 0.4, 0, 0) * CFrame.Angles(0, side * math.pi / 4, 0),
                        Vector3.new(0.22, 0.12, 1.25))
                end
                distance += spacing
            end
            carry = distance - length
        end
    end)
end

return Guide
