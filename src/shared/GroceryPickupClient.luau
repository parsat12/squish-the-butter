local Workspace = game:GetService("Workspace")
local ProximityPromptService = game:GetService("ProximityPromptService")

local Client = {}

function Client.Start(remote, applyResponse)
    local claims = {}
    local pending = {}
    local pendingPickup
    local originals = setmetatable({}, {__mode = "k"})
    local updateCombat = require(script.Parent.GroceryCombatClient).Start(remote.Parent:WaitForChild("GroceryCombatState"))
    local function hideIfClaimed(object)
        local model = object
        while model and model ~= Workspace do
            local id = model:GetAttribute("GroceryPickupId")
            if id then
                do
                    local hidden = claims[id] or pendingPickup == id
                    local function hide(child)
                        if child:IsA("BasePart") then child.LocalTransparencyModifier = hidden and 1 or 0
                        elseif child:IsA("Decal") then
                            if originals[child] == nil then originals[child] = child.Transparency end
                            child.Transparency = hidden and 1 or originals[child]
                        elseif child:IsA("ProximityPrompt") then
                            child.Enabled = not hidden and pendingPickup == nil
                        elseif child:IsA("SurfaceGui") or child:IsA("BillboardGui") or child:IsA("ParticleEmitter")
                            or child:IsA("Trail") or child:IsA("Beam") then
                            if originals[child] == nil then originals[child] = child.Enabled end
                            child.Enabled = not hidden and originals[child]
                        end
                    end
                    hide(model)
                    for _, child in ipairs(model:GetDescendants()) do hide(child) end
                end
                return
            end
            model = model.Parent
        end
    end
    Workspace.DescendantAdded:Connect(function(object)
        task.defer(hideIfClaimed, object)
    end)
    ProximityPromptService.PromptTriggered:Connect(function(prompt)
        if prompt.Name ~= "GroceryPickupPrompt" then return end
        local model = prompt:FindFirstAncestorOfClass("Model")
        local id = model and model:GetAttribute("GroceryPickupId")
        if not id or claims[id] or pending[id] or pendingPickup then return end
        pending[id] = true
        local ok, result = pcall(function() return remote:InvokeServer(id) end)
        pending[id] = nil
        if ok and result then
            applyResponse(result)
        end
    end)
    return function(state)
        claims = {}
        pendingPickup = state.GroceryEncounter and state.GroceryEncounter.PickupId or nil
        updateCombat(state.GroceryEncounter)
        for id, claimed in pairs(state.GroceryClaims or {}) do
            if claimed then claims[id] = true end
        end
        local map = Workspace:FindFirstChild("SquishTheButterMap")
        local store = map and map:FindFirstChild("GroceryStore")
        local folder = store and store:FindFirstChild("PickupDisplays")
        if folder then
            for _, model in ipairs(folder:GetChildren()) do hideIfClaimed(model) end
        end
    end
end

return Client
