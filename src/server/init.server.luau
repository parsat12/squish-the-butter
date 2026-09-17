local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local DataStoreService = game:GetService("DataStoreService")

local GameConfig = require(ReplicatedStorage.Shared.GameConfig)

local DATA_STORE_NAME = "SquishTheButter_PlayerData_v1"
local AUTOSAVE_SECONDS = 60
local COIN_TICK_SECONDS = 1

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

local GetState = getOrCreateRemote("GetState")
local BuyButter = getOrCreateRemote("BuyButter")
local CrackButter = getOrCreateRemote("CrackButter")

local function makeDefaultData()
	return {
		Coins = 0,
		Butter = {
			Plain = 1,
		},
		Needohs = {},
		Collection = {},
	}
end

local function copyArray(array)
	local result = {}

	for index, value in ipairs(array or {}) do
		result[index] = value
	end

	return result
end

local function sanitizeData(data)
	local clean = makeDefaultData()

	if typeof(data) ~= "table" then
		return clean
	end

	clean.Coins = math.max(0, math.floor(tonumber(data.Coins) or 0))

	if typeof(data.Butter) == "table" then
		for butterId in pairs(GameConfig.Butter) do
			local amount = math.max(0, math.floor(tonumber(data.Butter[butterId]) or 0))
			if amount > 0 then
				clean.Butter[butterId] = amount
			end
		end
	end

	if typeof(data.Needohs) == "table" then
		for _, needohId in ipairs(data.Needohs) do
			if GameConfig.Needohs[needohId] then
				table.insert(clean.Needohs, needohId)
				clean.Collection[needohId] = true
			end
		end
	end

	if typeof(data.Collection) == "table" then
		for needohId, owned in pairs(data.Collection) do
			if owned and GameConfig.Needohs[needohId] then
				clean.Collection[needohId] = true
			end
		end
	end

	return clean
end

local function getCoinRate(data)
	local rate = 0

	for _, needohId in ipairs(data.Needohs) do
		local needoh = GameConfig.Needohs[needohId]
		if needoh then
			rate += needoh.CoinsPerSecond
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
		Needohs = copyArray(data.Needohs),
		Collection = table.clone(data.Collection),
		ButterConfig = GameConfig.Butter,
		NeedohConfig = GameConfig.Needohs,
		RarityConfig = GameConfig.Rarities,
	}
end

local function updateLeaderstats(player)
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

local function pickNeedoh(rarityId)
	local candidates = {}

	for needohId, needoh in pairs(GameConfig.Needohs) do
		if needoh.Rarity == rarityId then
			table.insert(candidates, needohId)
		end
	end

	if #candidates == 0 then
		return "BlueBlob"
	end

	return candidates[math.random(1, #candidates)]
end

Players.PlayerAdded:Connect(function(player)
	loadPlayer(player)
	makeLeaderstats(player)
end)

Players.PlayerRemoving:Connect(function(player)
	savePlayer(player)
	playerData[player] = nil
end)

GetState.OnServerInvoke = function(player)
	return {
		Ok = true,
		State = makePublicState(player),
	}
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

	data.Butter[butterId] -= 1

	local rarityId = pickRarity(butterConfig)
	local needohId = pickNeedoh(rarityId)
	local needoh = GameConfig.Needohs[needohId]

	table.insert(data.Needohs, needohId)
	data.Collection[needohId] = true

	updateLeaderstats(player)

	return {
		Ok = true,
		Message = `Cracked {butterConfig.Name} and found {needoh.Name}!`,
		Prize = {
			Id = needohId,
			Name = needoh.Name,
			Rarity = needoh.Rarity,
			CoinsPerSecond = needoh.CoinsPerSecond,
		},
		State = makePublicState(player),
	}
end

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
