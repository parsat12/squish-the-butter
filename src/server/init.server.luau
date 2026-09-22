local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local Debris = game:GetService("Debris")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DATA_STORE_NAME = "SquishTheButter_PlayerData_v1"
local AUTOSAVE_SECONDS = 60
local COIN_TICK_SECONDS = 1
local PRIZE_DESPAWN_SECONDS = 20
local MAX_BEEBOHS = 20
local MAX_EQUIPPED_BEEBOHS = 3
local ADMIN_USER_IDS = {
	-- Add your Roblox UserId here if game.CreatorId does not match in Studio.
	-- Example: [123456789] = true,
	[96528615] = true,
}

local dataStore = DataStoreService:GetDataStore(DATA_STORE_NAME)
local playerData = {}

local remotesFolder = ReplicatedStorage:FindFirstChild("ButterRemotes")
if not remotesFolder then
	remotesFolder = Instance.new("Folder")
	remotesFolder.Name = "ButterRemotes"
	remotesFolder.Parent = ReplicatedStorage
end

local function getOrCreateRemote(name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteFunction")
		remote.Name = name
		remote.Parent = remotesFolder
	end

	return remote
end

local function getOrCreateRemoteEvent(name)
	local remote = remotesFolder:FindFirstChild(name)
	if not remote then
		remote = Instance.new("RemoteEvent")
		remote.Name = name
		remote.Parent = remotesFolder
	end

	return remote
end

local GetState = getOrCreateRemote("GetState")
local BuyButter = getOrCreateRemote("BuyButter")
local CrackButter = getOrCreateRemote("CrackButter")
local DeleteBeeboh = getOrCreateRemote("DeleteBeeboh")
local RenameBeeboh = getOrCreateRemote("RenameBeeboh")
local ToggleEquipBeeboh = getOrCreateRemote("ToggleEquipBeeboh")
local PrizeRevealed = getOrCreateRemoteEvent("PrizeRevealed")
local PickupButter = getOrCreateRemote("PickupButter")
local GroceryCombatState = getOrCreateRemoteEvent("GroceryCombatState")
local ToggleKitchenBeeboh = getOrCreateRemote("ToggleKitchenBeeboh")
local OpenKitchenCrack = getOrCreateRemoteEvent("OpenKitchenCrack")
local CrackKitchenButter = getOrCreateRemote("CrackKitchenButter")
local tableCrackTimes = {}
local kitchens
local kitchenRequestTimes = {}
local groceryCombat
local groceryEntries = {}
local groceryRequestTimes = {}

local stationDebounces = {}
local followerModels = {}
local updateLeaderstats
local rebuildFollowerModels

local function makeDefaultData()
	return {
		Coins = 0,
		Butter = {
			Plain = 1,
		},
		Beebohs = {},
		EquippedBeebohs = {},
		Collection = {},
		GroceryClaims = {},
		KitchenBeebohs = {},
	}
end

local function copyArray(array)
	local result = {}

	for index, value in ipairs(array or {}) do
		result[index] = if typeof(value) == "table" then table.clone(value) else value
	end

	return result
end

local function cleanBeebohName(name, fallback)
	local cleaned = tostring(name or fallback or "Beeboh")
	cleaned = string.gsub(cleaned, "^%s+", "")
	cleaned = string.gsub(cleaned, "%s+$", "")
	cleaned = string.sub(cleaned, 1, 24)

	if cleaned == "" then
		return fallback or "Beeboh"
	end

	return cleaned
end

local function filterBeebohNameForPlayer(player, name, fallback)
	local cleaned = cleanBeebohName(name, fallback)
	local success, result = pcall(function()
		local filterResult = TextService:FilterStringAsync(cleaned, player.UserId)
		return filterResult:GetNonChatStringForBroadcastAsync()
	end)

	if success then
		return cleanBeebohName(result, fallback)
	end

	return cleaned
end

local function getBeebohId(entry)
	if typeof(entry) == "table" then
		return entry.Id
	end

	return entry
end

local function makeBeebohEntry(beebohId, customName)
	local beeboh = GameConfig.Beebohs[beebohId]
	if not beeboh then
		return nil
	end

	return {
		Id = beebohId,
		Name = cleanBeebohName(customName, beeboh.Name),
	}
end

local function isAdminPlayer(player)
	if ADMIN_USER_IDS[player.UserId] then
		return true
	end

	return game.CreatorType == Enum.CreatorType.User and player.UserId == game.CreatorId
end

local function normalizeCommandText(text)
	return string.lower(string.gsub(tostring(text or ""), "%s+", ""))
end

local function findBeebohIdFromCommand(text)
	local normalized = normalizeCommandText(text)

	for beebohId, beeboh in pairs(GameConfig.Beebohs) do
		if normalizeCommandText(beebohId) == normalized or normalizeCommandText(beeboh.Name) == normalized then
			return beebohId
		end
	end

	return nil
end

local function giveBeebohForTesting(player, beebohId, amount)
	local data = playerData[player]
	local beeboh = GameConfig.Beebohs[beebohId]

	if not data or not beeboh then
		return false
	end

	local added = 0
	local count = math.clamp(math.floor(tonumber(amount) or 1), 1, MAX_BEEBOHS)

	for _ = 1, count do
		if #data.Beebohs >= MAX_BEEBOHS then
			break
		end

		table.insert(data.Beebohs, makeBeebohEntry(beebohId))
		data.Collection[beebohId] = true
		added += 1
	end

	if added > 0 then
		updateLeaderstats(player)
		rebuildFollowerModels(player)
		print(`Admin gave {player.Name} {added}x {beeboh.Name}.`)
	end

	return added > 0
end

local function giveButterForTesting(player, butterId, amount)
	local data = playerData[player]
	local butter = GameConfig.Butter[butterId]

	if not data or not butter then
		return false
	end

	local count = math.max(1, math.floor(tonumber(amount) or 1))

	data.Butter[butterId] = (data.Butter[butterId] or 0) + count

	updateLeaderstats(player)

	print(`Admin gave {player.Name} {count}x {butter.Name}.`)

	return true
end

local function findButterIdFromCommand(text)
	local normalized = normalizeCommandText(text)

	for butterId, butter in pairs(GameConfig.Butter) do
		if normalizeCommandText(butterId) == normalized
			or normalizeCommandText(butter.Name) == normalized then
			return butterId
		end
	end

	return nil
end

local function handleAdminCommand(player, message)
	if not isAdminPlayer(player) then
		return
	end

	local parts = string.split(message, " ")
	local command = string.lower(parts[1] or "")

	-- Give Beeboh
	if command == "!givebeeboh"
		or command == "/givebeeboh"
		or command == "!beeboh" then

		local requestedId = parts[2]

		if not requestedId then
			warn("Use: !givebeeboh BeebohId amount")
			return
		end

		local beebohId = findBeebohIdFromCommand(requestedId)

		if not beebohId then
			warn(`Unknown Beeboh id "{requestedId}".`)
			return
		end

		giveBeebohForTesting(player, beebohId, parts[3])
		return
	end

	-- Give Butter
	if command == "!givebutter"
		or command == "/givebutter"
		or command == "!butter" then

		local requestedId = parts[2]

		if not requestedId then
			warn("Use: !givebutter ButterId amount")
			return
		end

		local butterId = findButterIdFromCommand(requestedId)

		if not butterId then
			warn(`Unknown Butter id "{requestedId}".`)
			return
		end

		giveButterForTesting(player, butterId, parts[3])
	end
end

local function isEquipped(data, index)
	for _, equippedIndex in ipairs(data.EquippedBeebohs) do
		if equippedIndex == index then
			return true
		end
	end

	return false
end

local function sanitizeEquippedBeebohs(data)
	local clean = {}
	local seen = {}

	for _, rawIndex in ipairs(data.EquippedBeebohs or {}) do
		local index = math.floor(tonumber(rawIndex) or 0)
		if index >= 1 and index <= #data.Beebohs and not seen[index] and #clean < MAX_EQUIPPED_BEEBOHS then
			table.insert(clean, index)
			seen[index] = true
		end
	end

	data.EquippedBeebohs = clean
end

local function sanitizeData(data)
	local clean = makeDefaultData()

	if typeof(data) ~= "table" then
		return clean
	end

	clean.Coins = math.max(0, math.floor(tonumber(data.Coins) or 0))
	if typeof(data.GroceryClaims) == "table" then
		for id, claimed in pairs(data.GroceryClaims) do
			if typeof(id) == "string" and #id < 80 and id:match("^GroceryV1_%a+_%d+$") and claimed == true then
				clean.GroceryClaims[id] = true
			end
		end
	end

	if typeof(data.Butter) == "table" then
		for butterId in pairs(GameConfig.Butter) do
			local amount = math.max(0, math.floor(tonumber(data.Butter[butterId]) or 0))
			if amount > 0 then
				clean.Butter[butterId] = amount
			end
		end
	end

	local savedBeebohs = data.Beebohs
	if typeof(savedBeebohs) == "table" then
		for _, entry in ipairs(savedBeebohs) do
			local beebohId = getBeebohId(entry)
			if GameConfig.Beebohs[beebohId] then
				local customName = if typeof(entry) == "table" then entry.Name else nil
				table.insert(clean.Beebohs, makeBeebohEntry(beebohId, customName))
				clean.Collection[beebohId] = true
			end
		end
	end

	if typeof(data.EquippedBeebohs) == "table" then
		for _, index in ipairs(data.EquippedBeebohs) do
			table.insert(clean.EquippedBeebohs, index)
		end
	end

	sanitizeEquippedBeebohs(clean)
	if typeof(data.KitchenBeebohs) == "table" then
		for _, index in ipairs(data.KitchenBeebohs) do
			if typeof(index) == "number" and index == math.floor(index) and index >= 1 and index <= #clean.Beebohs
				and not table.find(clean.KitchenBeebohs, index) and not table.find(clean.EquippedBeebohs, index) then
				table.insert(clean.KitchenBeebohs, index)
			end
		end
	end

	if typeof(data.Collection) == "table" then
		for beebohId, owned in pairs(data.Collection) do
			if owned and GameConfig.Beebohs[beebohId] then
				clean.Collection[beebohId] = true
			end
		end
	end

	return clean
end

local function getCoinRate(data)
	local rate = 0

	for _, entry in ipairs(data.Beebohs) do
		local beebohId = getBeebohId(entry)
		local beeboh = GameConfig.Beebohs[beebohId]
		if beeboh then
			rate += beeboh.CoinsPerSecond
		end
	end

	return rate
end

local function makePublicState(player)
	local data = playerData[player]
	if not data then
		return nil
	end

	return {
		Coins = data.Coins,
		CoinRate = getCoinRate(data),
		Butter = table.clone(data.Butter),
		Beebohs = copyArray(data.Beebohs),
		EquippedBeebohs = copyArray(data.EquippedBeebohs),
		Collection = table.clone(data.Collection),
		GroceryClaims = table.clone(data.GroceryClaims),
		KitchenBeebohs = table.clone(data.KitchenBeebohs),
		KitchenPlot = kitchens and kitchens.Assignments[player] and kitchens.Assignments[player].Name or nil,
		GroceryEncounter = groceryCombat and groceryCombat:Snapshot(player) or nil,
		ButterConfig = GameConfig.Butter,
		BeebohConfig = GameConfig.Beebohs,
		RarityConfig = GameConfig.Rarities,
		MaxBeebohs = MAX_BEEBOHS,
		MaxEquippedBeebohs = MAX_EQUIPPED_BEEBOHS,
	}
end

updateLeaderstats = function(player)
	local data = playerData[player]
	if not data then
		return
	end

	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then
		return
	end

	local coins = leaderstats:FindFirstChild("Coins")
	local rate = leaderstats:FindFirstChild("CoinsPerSecond")

	if coins then
		coins.Value = data.Coins
	end

	if rate then
		rate.Value = getCoinRate(data)
	end
end

local function savePlayer(player)
	local data = playerData[player]
	if not data then
		return
	end

	local key = `Player_{player.UserId}`
	local success, err = pcall(function()
		dataStore:SetAsync(key, data)
	end)

	if not success then
		warn(`Failed to save data for {player.Name}: {err}`)
	end
end

local function loadPlayer(player)
	local key = `Player_{player.UserId}`
	local loadedData = nil

	local success, err = pcall(function()
		loadedData = dataStore:GetAsync(key)
	end)

	if not success then
		warn(`Failed to load data for {player.Name}: {err}`)
	end

	playerData[player] = sanitizeData(loadedData)
end

local function makeLeaderstats(player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Parent = leaderstats

	local rate = Instance.new("IntValue")
	rate.Name = "CoinsPerSecond"
	rate.Parent = leaderstats

	updateLeaderstats(player)
end

local function pickRarity(butterConfig)
	local totalWeight = 0

	for rarityId, weight in pairs(butterConfig.Odds) do
		if GameConfig.Rarities[rarityId] then
			totalWeight += weight
		end
	end

	local roll = math.random() * totalWeight
	local running = 0

	for rarityId, weight in pairs(butterConfig.Odds) do
		if GameConfig.Rarities[rarityId] then
			running += weight
			if roll <= running then
				return rarityId
			end
		end
	end

	return "Common"
end

local function pickBeeboh(rarityId)
	local candidates = {}

	for beebohId, beeboh in pairs(GameConfig.Beebohs) do
		if beeboh.Rarity == rarityId then
			table.insert(candidates, beebohId)
		end
	end

	if #candidates == 0 then
		return "BlueBlob"
	end

	return candidates[math.random(1, #candidates)]
end

local function getStationPart(station)
	if station:IsA("BasePart") then
		return station
	end

	if station:IsA("Model") then
		if station.PrimaryPart then
			return station.PrimaryPart
		end

		return station:FindFirstChildWhichIsA("BasePart", true)
	end

	return nil
end

local function getStationCFrame(station)
	if station:IsA("Model") then
		return station:GetPivot()
	end

	if station:IsA("BasePart") then
		return station.CFrame
	end

	return CFrame.new()
end

local function findBeebohModel(prize)
	local beebohModels = ReplicatedStorage:FindFirstChild("BeebohModels")
	if not beebohModels then
		return nil
	end

	local sourceModel = beebohModels:FindFirstChild(prize.Id) or beebohModels:FindFirstChild(prize.Name)
	if sourceModel and (sourceModel:IsA("Model") or sourceModel:IsA("BasePart")) then
		return sourceModel
	end

	return nil
end

local function preparePrizeModel(sourceModel, spawnCFrame)
	local clone = sourceModel:Clone()
	clone.Name = "PrizeModel"

	local model
	if clone:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = "PrizeModel"
		clone.Parent = model
		model.PrimaryPart = clone
	else
		model = clone
		if not model.PrimaryPart then
			model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
		end
	end

	if not model.PrimaryPart then
		model:Destroy()
		return nil
	end

	model.Parent = Workspace
	model:PivotTo(spawnCFrame)

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = false
			descendant.CanCollide = true
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end

	return model
end

local function prepareFollowerModel(sourceModel, parent, fallbackColor)
	local model = nil

	if sourceModel then
		local clone = sourceModel:Clone()
		clone.Name = "FollowerBeeboh"

		if clone:IsA("BasePart") then
			model = Instance.new("Model")
			model.Name = "FollowerBeeboh"
			clone.Parent = model
			model.PrimaryPart = clone
		else
			model = clone
			if not model.PrimaryPart then
				model.PrimaryPart = model:FindFirstChildWhichIsA("BasePart", true)
			end
		end
	end

	if not model then
		local ball = Instance.new("Part")
		ball.Name = "FollowerBeeboh"
		ball.Anchored = true
		ball.Shape = Enum.PartType.Ball
		ball.Material = Enum.Material.SmoothPlastic
		ball.Color = fallbackColor or Color3.fromRGB(126, 220, 255)
		ball.Size = Vector3.new(1.8, 1.8, 1.8)

		model = Instance.new("Model")
		model.Name = "FollowerBeeboh"
		ball.Parent = model
		model.PrimaryPart = ball
	end

	if not model.PrimaryPart then
		model:Destroy()
		return nil
	end

	model.Parent = parent

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			descendant.CanTouch = false
			descendant.CanQuery = false
		elseif descendant:IsA("Script") or descendant:IsA("LocalScript") or descendant:IsA("ProximityPrompt") then
			descendant:Destroy()
		end
	end

	return model
end

local function clearFollowerModels(player)
	local models = followerModels[player]
	if models then
		for _, model in ipairs(models) do
			model:Destroy()
		end
	end

	followerModels[player] = {}

	local character = player.Character
	local oldFolder = character and character:FindFirstChild("EquippedBeebohFollowers")
	if oldFolder then
		oldFolder:Destroy()
	end
end

rebuildFollowerModels = function(player)
	local data = playerData[player]
	if not data then
		return
	end

	sanitizeEquippedBeebohs(data)
	clearFollowerModels(player)

	local character = player.Character
	if not character then
		return
	end

	local folder = Instance.new("Folder")
	folder.Name = "EquippedBeebohFollowers"
	folder.Parent = character

	local models = {}
	for slot, beebohIndex in ipairs(data.EquippedBeebohs) do
		local entry = data.Beebohs[beebohIndex]
		local beebohId = getBeebohId(entry)
		local beeboh = GameConfig.Beebohs[beebohId]

		if beeboh then
			local sourceModel = findBeebohModel({
				Id = beebohId,
				Name = beeboh.Name,
			})
			local model = prepareFollowerModel(sourceModel, folder, beeboh.Color)

			if model then
				model:SetAttribute("FollowerSlot", slot)
				model:SetAttribute("BeebohIndex", beebohIndex)
				table.insert(models, model)
			end
		end
	end

	followerModels[player] = models
end

local function createPrizeDrop(player, station, prize)
	local rarity = GameConfig.Rarities[prize.Rarity]
	local spawnCFrame = getStationCFrame(station) * CFrame.new(0, 3, -4)
	local sourceModel = findBeebohModel(prize)
	local prizeModel = if sourceModel then preparePrizeModel(sourceModel, spawnCFrame) else nil
	local labelPart = nil

	if prizeModel then
		prizeModel.Name = `{player.Name}_{prize.Id}_Prize`
		labelPart = prizeModel.PrimaryPart
	else
		local ball = Instance.new("Part")
		ball.Name = `{player.Name}_{prize.Id}_Prize`
		ball.Shape = Enum.PartType.Ball
		ball.Size = Vector3.new(2.2, 2.2, 2.2)
		ball.Material = Enum.Material.SmoothPlastic
		ball.Color = if rarity then rarity.Color else Color3.fromRGB(255, 255, 255)
		ball.CFrame = spawnCFrame
		ball.Anchored = false
		ball.CanCollide = true
		ball.Parent = Workspace
		labelPart = ball
	end

	local attachment = Instance.new("Attachment")
	attachment.Position = Vector3.new(0, 1.6, 0)
	attachment.Parent = labelPart

	local label = Instance.new("BillboardGui")
	label.Name = "PrizeLabel"
	label.AlwaysOnTop = true
	label.Size = UDim2.fromOffset(180, 56)
	label.StudsOffset = Vector3.new(0, 1.5, 0)
	label.Parent = attachment

	local text = Instance.new("TextLabel")
	text.BackgroundTransparency = 1
	text.Font = Enum.Font.GothamBlack
	text.Text = `{prize.Name}\n+{prize.CoinsPerSecond}/sec`
	text.TextColor3 = if rarity then rarity.Color else Color3.fromRGB(255, 255, 255)
	text.TextSize = 14
	text.TextStrokeTransparency = 0.25
	text.TextWrapped = true
	text.Size = UDim2.fromScale(1, 1)
	text.Parent = label

	local impulse = Vector3.new(math.random(-18, 18), math.random(32, 42), math.random(-18, 18))
	labelPart:ApplyImpulse(impulse * labelPart.AssemblyMass)

	Debris:AddItem(if prizeModel then prizeModel else labelPart, PRIZE_DESPAWN_SECONDS)
end

local function crackButterForPlayer(player, butterId, station)
	local data = playerData[player]
	local butterConfig = GameConfig.Butter[butterId]

	if not data or not butterConfig then
		return {
			Ok = false,
			Message = "That butter stick does not exist.",
			State = makePublicState(player),
		}
	end

	if (data.Butter[butterId] or 0) <= 0 then
		return {
			Ok = false,
			Message = "You do not own that butter stick.",
			State = makePublicState(player),
		}
	end

	if #data.Beebohs >= MAX_BEEBOHS then
		return {
			Ok = false,
			Message = `Your Beeboh inventory is full ({MAX_BEEBOHS}/{MAX_BEEBOHS}). Delete one before cracking more butter.`,
			State = makePublicState(player),
		}
	end

	data.Butter[butterId] -= 1

	local rarityId = pickRarity(butterConfig)
	local beebohId = pickBeeboh(rarityId)
	local beeboh = GameConfig.Beebohs[beebohId]

	table.insert(data.Beebohs, makeBeebohEntry(beebohId))
	data.Collection[beebohId] = true

	updateLeaderstats(player)
	rebuildFollowerModels(player)

	local prize = {
		Id = beebohId,
		Name = beeboh.Name,
		Rarity = beeboh.Rarity,
		CoinsPerSecond = beeboh.CoinsPerSecond,
	}

	local result = {
		Ok = true,
		Message = `Cracked {butterConfig.Name} and found {beeboh.Name}!`,
		Prize = prize,
		State = makePublicState(player),
	}

	if station then
		createPrizeDrop(player, station, prize)
		PrizeRevealed:FireClient(player, result)
	end

	return result
end

local function setupButterStation(station)
	if station:FindFirstAncestor("PickupDisplays") then return end
	if station:GetAttribute("ButterStationReady") then
		return
	end

	if station.Name ~= "ButterStick" and station.Name ~= "ButterStation" and not station:GetAttribute("ButterId") then
		return
	end

	local stationPart = getStationPart(station)
	if not stationPart then
		warn(`Butter station {station:GetFullName()} needs at least one BasePart.`)
		return
	end

	station:SetAttribute("ButterStationReady", true)

	local butterId = station:GetAttribute("ButterId") or "Plain"
	if not GameConfig.Butter[butterId] then
		warn(`Butter station {station:GetFullName()} has invalid ButterId "{butterId}". Falling back to Plain.`)
		butterId = "Plain"
	end

	local prompt = stationPart:FindFirstChild("CrackButterPrompt")
	if not prompt then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "CrackButterPrompt"
		prompt.Parent = stationPart
	end

	prompt.ActionText = "Crack"
	prompt.ObjectText = GameConfig.Butter[butterId].Name
	prompt.HoldDuration = 0.5
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false

	prompt.Triggered:Connect(function(player)
		local key = `{player.UserId}:{station:GetFullName()}`
		if stationDebounces[key] then
			return
		end

		stationDebounces[key] = true
		local result = crackButterForPlayer(player, butterId, station)

		if not result.Ok then
			warn(`{player.Name}: {result.Message}`)
		end

		task.delay(1, function()
			stationDebounces[key] = nil
		end)
	end)
end

local function setupExistingButterStations()
	for _, descendant in ipairs(Workspace:GetDescendants()) do
		setupButterStation(descendant)
	end
end

Players.PlayerAdded:Connect(function(player)
	loadPlayer(player)
	makeLeaderstats(player)
	if kitchens and player.Parent == Players then kitchens:Assign(player) end

	player.Chatted:Connect(function(message)
		handleAdminCommand(player, message)
	end)

	player.CharacterAdded:Connect(function()
		task.defer(rebuildFollowerModels, player)
	end)

	if player.Character then
		task.defer(rebuildFollowerModels, player)
	end
end)

Players.PlayerRemoving:Connect(function(player)
	if kitchens then kitchens:Release(player) end
	clearFollowerModels(player)
	savePlayer(player)
	playerData[player] = nil
	groceryRequestTimes[player] = nil
	kitchenRequestTimes[player] = nil
	tableCrackTimes[player] = nil
	followerModels[player] = nil
end)

GetState.OnServerInvoke = function(player)
	return {
		Ok = true,
		State = makePublicState(player),
	}
end

PickupButter.OnServerInvoke = function(player, pickupId)
	local now = os.clock()
	if now - (groceryRequestTimes[player] or -math.huge) < 0.2 then return {Ok = false} end
	groceryRequestTimes[player] = now
	local data = playerData[player]
	local entry = typeof(pickupId) == "string" and groceryEntries[pickupId]
	if not data or not entry or not entry.Model:IsDescendantOf(Workspace) then return {Ok = false} end
	if data.GroceryClaims[pickupId] then
		return {Ok = false, State = makePublicState(player)}
	end
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not root or not humanoid or humanoid.Health <= 0 or (root.Position - entry.Anchor.Position).Magnitude > 14 then
		return {Ok = false, Message = "Move closer to pick up the butter."}
	end
	if not groceryCombat then return {Ok = false, Message = "The officers are not ready yet."} end
	local started, reason = groceryCombat:Start(player, pickupId, entry)
	return {Ok = started, Message = reason or "Defeat the officers to escape with your butter!", State = makePublicState(player)}
end

BuyButter.OnServerInvoke = function(player, butterId)
	local data = playerData[player]
	local butterConfig = GameConfig.Butter[butterId]

	if not data or not butterConfig then
		return {
			Ok = false,
			Message = "That butter stick does not exist.",
			State = makePublicState(player),
		}
	end

	if data.Coins < butterConfig.Cost then
		return {
			Ok = false,
			Message = "Not enough coins.",
			State = makePublicState(player),
		}
	end

	data.Coins -= butterConfig.Cost
	data.Butter[butterId] = (data.Butter[butterId] or 0) + 1

	updateLeaderstats(player)

	return {
		Ok = true,
		Message = `Bought {butterConfig.Name}.`,
		State = makePublicState(player),
	}
end

CrackButter.OnServerInvoke = function(player, butterId)
	return crackButterForPlayer(player, butterId, nil)
end

CrackKitchenButter.OnServerInvoke = function(player, butterId)
	local plot = kitchens and kitchens.Assignments[player]
	local kitchen = plot and plot:FindFirstChild("StarterKitchen")
	local tablePart = kitchen and kitchen:FindFirstChild("CrackingTable")
	local character = player.Character
	local root = character and character:FindFirstChild("HumanoidRootPart")
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if typeof(butterId) ~= "string" or not tablePart or not root or not humanoid or humanoid.Health <= 0
		or (root.Position - tablePart.Position).Magnitude > 12 or (groceryCombat and groceryCombat.Active[player]) then
		return {Ok = false, Message = "Use your own kitchen table while nearby and out of combat."}
	end
	local now = os.clock()
	if now - (tableCrackTimes[player] or -math.huge) < 1 then return {Ok = false} end
	tableCrackTimes[player] = now
	return crackButterForPlayer(player, butterId, nil)
end

DeleteBeeboh.OnServerInvoke = function(player, beebohIndex)
	local data = playerData[player]
	local index = math.floor(tonumber(beebohIndex) or 0)

	if not data then
		return {
			Ok = false,
			Message = "Your data is not loaded yet.",
			State = makePublicState(player),
		}
	end

	if index < 1 or index > #data.Beebohs then
		return {
			Ok = false,
			Message = "That Beeboh is no longer in your inventory.",
			State = makePublicState(player),
		}
	end

	local removedEntry = table.remove(data.Beebohs, index)
	local removedId = getBeebohId(removedEntry)
	local removed = GameConfig.Beebohs[removedId]
	local nextEquipped = {}

	for _, equippedIndex in ipairs(data.EquippedBeebohs) do
		if equippedIndex < index then
			table.insert(nextEquipped, equippedIndex)
		elseif equippedIndex > index then
			table.insert(nextEquipped, equippedIndex - 1)
		end
	end

	data.EquippedBeebohs = nextEquipped
	local nextKitchen = {}
	for _, placedIndex in ipairs(data.KitchenBeebohs) do
		if placedIndex < index then table.insert(nextKitchen, placedIndex)
		elseif placedIndex > index then table.insert(nextKitchen, placedIndex - 1) end
	end
	data.KitchenBeebohs = nextKitchen
	if kitchens then kitchens:Rebuild(player) end

	updateLeaderstats(player)
	rebuildFollowerModels(player)

	return {
		Ok = true,
		Message = if removed then `Deleted {removed.Name}.` else "Deleted Beeboh.",
		State = makePublicState(player),
	}
end

ToggleEquipBeeboh.OnServerInvoke = function(player, beebohIndex)
	local data = playerData[player]
	local index = math.floor(tonumber(beebohIndex) or 0)

	if not data then
		return {
			Ok = false,
			Message = "Your data is not loaded yet.",
			State = makePublicState(player),
		}
	end

	if index < 1 or index > #data.Beebohs then
		return {
			Ok = false,
			Message = "That Beeboh is no longer in your inventory.",
			State = makePublicState(player),
		}
	end

	sanitizeEquippedBeebohs(data)

	for equippedSlot, equippedIndex in ipairs(data.EquippedBeebohs) do
		if equippedIndex == index then
			table.remove(data.EquippedBeebohs, equippedSlot)
			rebuildFollowerModels(player)
			return {
				Ok = true,
				Message = "Unequipped Beeboh.",
				State = makePublicState(player),
			}
		end
	end

	if #data.EquippedBeebohs >= MAX_EQUIPPED_BEEBOHS then
		return {
			Ok = false,
			Message = `You can only equip {MAX_EQUIPPED_BEEBOHS} Beebohs at a time.`,
			State = makePublicState(player),
		}
	end

	table.insert(data.EquippedBeebohs, index)
	local kitchenSlot = table.find(data.KitchenBeebohs, index)
	if kitchenSlot then
		table.remove(data.KitchenBeebohs, kitchenSlot)
		if kitchens then kitchens:Rebuild(player) end
	end
	rebuildFollowerModels(player)

	return {
		Ok = true,
		Message = "Equipped Beeboh.",
		State = makePublicState(player),
	}
end

ToggleKitchenBeeboh.OnServerInvoke = function(player, index)
	local now = os.clock()
	if now - (kitchenRequestTimes[player] or -math.huge) < 0.25 then return {Ok = false} end
	kitchenRequestTimes[player] = now
	local data = playerData[player]
	if not data or typeof(index) ~= "number" or index ~= math.floor(index) or index < 1 or index > #data.Beebohs then
		return {Ok = false, Message = "That Beeboh is no longer available.", State = makePublicState(player)}
	end
	local slot = table.find(data.KitchenBeebohs, index)
	if slot then
		table.remove(data.KitchenBeebohs, slot)
	else
		if not kitchens or not kitchens:Assign(player) then
			return {Ok = false, Message = "All eight kitchens are occupied. A plot will be assigned when one is free.", State = makePublicState(player)}
		end
		table.insert(data.KitchenBeebohs, index)
		local equipped = table.find(data.EquippedBeebohs, index)
		if equipped then table.remove(data.EquippedBeebohs, equipped) end
	end
	if kitchens then kitchens:Rebuild(player) end
	rebuildFollowerModels(player)
	return {Ok = true, Message = slot and "Returned Beeboh to inventory." or "Beeboh placed in your kitchen.", State = makePublicState(player)}
end

RenameBeeboh.OnServerInvoke = function(player, beebohIndex, newName)
	local data = playerData[player]
	local index = math.floor(tonumber(beebohIndex) or 0)

	if not data then
		return {
			Ok = false,
			Message = "Your data is not loaded yet.",
			State = makePublicState(player),
		}
	end

	if index < 1 or index > #data.Beebohs then
		return {
			Ok = false,
			Message = "That Beeboh is no longer in your inventory.",
			State = makePublicState(player),
		}
	end

	local entry = data.Beebohs[index]
	local beebohId = getBeebohId(entry)
	local beeboh = GameConfig.Beebohs[beebohId]

	if not beeboh then
		return {
			Ok = false,
			Message = "That Beeboh type does not exist.",
			State = makePublicState(player),
		}
	end

	if typeof(entry) ~= "table" then
		entry = makeBeebohEntry(beebohId)
		data.Beebohs[index] = entry
	end

	entry.Name = filterBeebohNameForPlayer(player, newName, beeboh.Name)
	if kitchens then kitchens:Rebuild(player) end

	return {
		Ok = true,
		Message = `Renamed Beeboh to {entry.Name}.`,
		State = makePublicState(player),
	}
end

do
	groceryCombat = require(script.GroceryCombat).new(GroceryCombatState, function(player, pickupId, butterId, won, reason)
		local data = playerData[player]
		if not data then return end
		if won and not data.GroceryClaims[pickupId] then
			data.GroceryClaims[pickupId] = true
			data.Butter[butterId] = (data.Butter[butterId] or 0) + 1
		end
		PrizeRevealed:FireClient(player, {Ok = won, State = makePublicState(player),
			Message = won and "Officers defeated! Butter secured. You can return to your base."
				or "Encounter ended (" .. reason .. "). The butter is available to retry."})
	end)
	local map = Workspace:FindFirstChild("SquishTheButterMap")
	kitchens = require(script.Kitchens).new(map, playerData, function(entry, parent)
		local id = getBeebohId(entry)
		local config = GameConfig.Beebohs[id]
		if not config then return nil end
		local model = prepareFollowerModel(findBeebohModel({Id = id, Name = config.Name}), parent,
			GameConfig.Rarities[config.Rarity].Color)
		if model then model.Name = typeof(entry) == "table" and entry.Name or config.Name end
		return model
	end, OpenKitchenCrack)
	local store = map and map:FindFirstChild("GroceryStore")
	if store then
		groceryEntries = require(script.GroceryPickups).Build(store)
	end
end
setupExistingButterStations()

Workspace.DescendantAdded:Connect(function(descendant)
	task.defer(setupButterStation, descendant)
end)

RunService.Heartbeat:Connect(function()
	for player, models in pairs(followerModels) do
		local character = player.Character
		local rootPart = character and character:FindFirstChild("HumanoidRootPart")

		if rootPart then
			for slot, model in ipairs(models) do
				if model.Parent and model.PrimaryPart then
					local sideOffset = (slot - 2) * 2.1
					local bob = math.sin(os.clock() * 2.4 + slot) * 0.22
					local target = rootPart.CFrame * CFrame.new(sideOffset, 4.1 + bob, 4.2)
					model:PivotTo(target)
				end
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(COIN_TICK_SECONDS)

		for player, data in pairs(playerData) do
			local coinRate = getCoinRate(data)
			if coinRate > 0 then
				data.Coins += coinRate * COIN_TICK_SECONDS
				updateLeaderstats(player)
			end
		end
	end
end)

task.spawn(function()
	while true do
		task.wait(AUTOSAVE_SECONDS)

		for player in pairs(playerData) do
			savePlayer(player)
		end
	end
end)

game:BindToClose(function()
	for player in pairs(playerData) do
		savePlayer(player)
	end
end)
