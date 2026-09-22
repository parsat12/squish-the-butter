-- Run as a server Script in an isolated Studio test session after installing combat.
local Combat = require(game.ServerScriptService.Server.GroceryCombat)
local Config = require(game.ReplicatedStorage.Shared.GroceryCombatConfig)
local Players = game:GetService("Players")
local fixtures = Instance.new("Folder")
fixtures.Name = "GroceryCombatTests"
fixtures.Parent = workspace
local function run()
    local floor = Instance.new("Part")
    floor.Size = Vector3.new(64, 1, 80)
    floor.CFrame = CFrame.new(10000, 0, 10000)
    floor.Anchored = true
    floor.Parent = fixtures
    local function player()
        local character = Instance.new("Model")
        local root = Instance.new("Part")
        root.Name = "HumanoidRootPart"
        root.Size = Vector3.new(2, 2, 1)
        root.Anchored, root.CanQuery, root.CanCollide = true, false, false
        root.CFrame = floor.CFrame * CFrame.new(0, 3.5, 15)
        root.Parent = character
        local humanoid = Instance.new("Humanoid")
        humanoid.RequiresNeck = false
        humanoid.Parent = character
        character.Parent = fixtures
        return {Parent = Players, Character = character}, root, humanoid
    end
    local events, finishes = {}, {}
    local combat = setmetatable({Active = {}, Remote = {FireClient = function(_, p, data)
        table.insert(events, {Player = p, Data = data})
    end}, OnFinish = function(p, id, tier, won)
        table.insert(finishes, {Player = p, Id = id, Won = won})
    end}, Combat)
    local a, rootA, healthA = player()
    local b = player()
    local entry = {Floor = floor, ButterId = "Plain"}
    assert(combat:Start(a, "same-display", entry))
    assert(combat:Start(b, "same-display", entry), "Players must have independent encounters")
    assert(not combat:Start(a, "another-display", entry), "Cannot stack encounters")
    local encounter = combat.Active[a]
    for _, guard in ipairs(encounter.Officers) do
        guard.Position = rootA.Position + Vector3.new(0, 0, -4)
        guard.Health = 100
        guard.NextAttack = math.huge
    end
    encounter.NextPlayerAttack = 0
    combat:Step(a, encounter, 0)
    local total = 0
    for _, guard in ipairs(encounter.Officers) do total += guard.Health end
    assert(total == 200 - Config.PlayerDamage, "Auto-attack must hit only one nearby officer")
    combat:Step(a, encounter, 0)
    local unchanged = 0
    for _, guard in ipairs(encounter.Officers) do unchanged += guard.Health end
    assert(unchanged == total, "Player attack cooldown must prevent repeat damage")
    encounter.NextPlayerAttack = math.huge
    encounter.Officers[1].NextAttack = 0
    local before = healthA.Health
    combat:Step(a, encounter, 0)
    assert(healthA.Health == before - Config.Tiers.Plain.Damage, "Police must retaliate")
    before = healthA.Health
    combat:Step(a, encounter, 0)
    assert(healthA.Health == before, "Police attack cooldown must hold")
    rootA.CFrame = floor.CFrame * CFrame.new(0, 3.5, 100)
    combat:Step(a, encounter, 0)
    assert(math.abs(floor.CFrame:PointToObjectSpace(rootA.Position).Z) <= 37, "Section escape must be clamped")
    for _, guard in ipairs(encounter.Officers) do
        guard.Position = rootA.Position + Vector3.new(0, 0, -4)
        guard.Health = 1
    end
    for _ = 1, #encounter.Officers do
        encounter.NextPlayerAttack = 0
        combat:Step(a, encounter, 0)
    end
    assert(not combat.Active[a] and combat.Active[b], "Victory must only unlock its own player")
    assert(#finishes == 1 and finishes[1].Won, "Victory must grant exactly once")
    combat:Finish(a, true, "Duplicate")
    assert(#finishes == 1, "Duplicate completion must not grant again")
    b.Character = nil
    combat:Step(b, combat.Active[b], 0)
    assert(not combat.Active[b] and not finishes[2].Won, "Reset must release without reward")
    assert(combat:Start(a, "retry", entry))
    combat.Active[a].Started = -math.huge
    combat:Step(a, combat.Active[a], 0)
    assert(not combat.Active[a] and not finishes[3].Won, "Timeout must release without reward")
    local previous
    for _, tier in ipairs({"Plain", "Salted", "Golden", "Rainbow", "Cosmic"}) do
        local stats = Config.Tiers[tier]
        if previous then
            assert(stats.Count >= previous.Count and stats.Health > previous.Health
                and stats.Damage >= previous.Damage and stats.Speed > previous.Speed)
        end
        previous = stats
    end
end
local ok, failure = pcall(run)
fixtures:Destroy()
assert(ok, failure)
print("PASS: independent encounters, auto-attack, retaliation, cooldowns, confinement, victory, duplicate completion, reset, timeout, tier scaling")
