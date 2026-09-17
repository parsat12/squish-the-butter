local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ButterRemotes")

local GetState = remotes:WaitForChild("GetState")
local BuyButter = remotes:WaitForChild("BuyButter")
local CrackButter = remotes:WaitForChild("CrackButter")

local state = nil
local selectedButterId = "Plain"

local gui = Instance.new("ScreenGui")
gui.Name = "SquishTheButterGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0, 0.5)
root.BackgroundColor3 = Color3.fromRGB(255, 246, 196)
root.BorderSizePixel = 0
root.Size = UDim2.fromOffset(360, 470)
root.Position = UDim2.new(0, 20, 0.5, 0)
root.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(116, 86, 36)
stroke.Thickness = 2
stroke.Parent = root

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 14)
padding.PaddingRight = UDim.new(0, 14)
padding.PaddingBottom = UDim.new(0, 14)
padding.PaddingLeft = UDim.new(0, 14)
padding.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = root

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "Squish the Butter"
title.TextColor3 = Color3.fromRGB(83, 55, 21)
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, 0, 0, 32)
title.LayoutOrder = 1
title.Parent = root

local stats = Instance.new("TextLabel")
stats.BackgroundTransparency = 1
stats.Font = Enum.Font.GothamBold
stats.TextColor3 = Color3.fromRGB(83, 55, 21)
stats.TextSize = 18
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.Size = UDim2.new(1, 0, 0, 52)
stats.LayoutOrder = 2
stats.Parent = root

local message = Instance.new("TextLabel")
message.BackgroundColor3 = Color3.fromRGB(255, 232, 111)
message.Font = Enum.Font.GothamBold
message.Text = "Start by cracking your Plain Butter."
message.TextColor3 = Color3.fromRGB(83, 55, 21)
message.TextSize = 15
message.TextWrapped = true
message.Size = UDim2.new(1, 0, 0, 52)
message.LayoutOrder = 3
message.Parent = root

local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 8)
messageCorner.Parent = message

local butterList = Instance.new("ScrollingFrame")
butterList.BackgroundTransparency = 1
butterList.BorderSizePixel = 0
butterList.CanvasSize = UDim2.fromOffset(0, 0)
butterList.AutomaticCanvasSize = Enum.AutomaticSize.Y
butterList.ScrollBarThickness = 6
butterList.Size = UDim2.new(1, 0, 0, 180)
butterList.LayoutOrder = 4
butterList.Parent = root

local butterLayout = Instance.new("UIListLayout")
butterLayout.Padding = UDim.new(0, 8)
butterLayout.SortOrder = Enum.SortOrder.LayoutOrder
butterLayout.Parent = butterList

local crackButton = Instance.new("TextButton")
crackButton.BackgroundColor3 = Color3.fromRGB(255, 199, 52)
crackButton.Font = Enum.Font.GothamBlack
crackButton.Text = "Crack Butter"
crackButton.TextColor3 = Color3.fromRGB(83, 55, 21)
crackButton.TextSize = 20
crackButton.Size = UDim2.new(1, 0, 0, 48)
crackButton.LayoutOrder = 5
crackButton.Parent = root

local crackCorner = Instance.new("UICorner")
crackCorner.CornerRadius = UDim.new(0, 8)
crackCorner.Parent = crackButton

local buyButton = Instance.new("TextButton")
buyButton.BackgroundColor3 = Color3.fromRGB(91, 181, 112)
buyButton.Font = Enum.Font.GothamBlack
buyButton.Text = "Buy Selected Butter"
buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyButton.TextSize = 18
buyButton.Size = UDim2.new(1, 0, 0, 44)
buyButton.LayoutOrder = 6
buyButton.Parent = root

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 8)
buyCorner.Parent = buyButton

local collection = Instance.new("TextLabel")
collection.BackgroundTransparency = 1
collection.Font = Enum.Font.Gotham
collection.TextColor3 = Color3.fromRGB(83, 55, 21)
collection.TextSize = 14
collection.TextWrapped = true
collection.TextXAlignment = Enum.TextXAlignment.Left
collection.TextYAlignment = Enum.TextYAlignment.Top
collection.Size = UDim2.new(1, 0, 0, 70)
collection.LayoutOrder = 7
collection.Parent = root

local butterButtons = {}
local refresh

local function rarityColor(rarity)
	local config = state and state.RarityConfig and state.RarityConfig[rarity]
	if config then
		return config.Color
	end

	return Color3.fromRGB(255, 255, 255)
end

local function getSortedButterIds()
	local ids = {}

	for butterId in pairs(state.ButterConfig) do
		table.insert(ids, butterId)
	end

	table.sort(ids, function(left, right)
		return state.ButterConfig[left].Order < state.ButterConfig[right].Order
	end)

	return ids
end

local function makeButterButton(butterId)
	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.Font = Enum.Font.GothamBold
	button.TextColor3 = Color3.fromRGB(83, 55, 21)
	button.TextSize = 14
	button.TextWrapped = true
	button.Size = UDim2.new(1, -8, 0, 44)
	button.Parent = butterList

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	button.Activated:Connect(function()
		selectedButterId = butterId
		refresh()
	end)

	butterButtons[butterId] = button
end

refresh = function()
	if not state then
		return
	end

	stats.Text = `Coins: {state.Coins}\nEarning: {state.CoinRate} coins/sec`

	for _, butterId in ipairs(getSortedButterIds()) do
		if not butterButtons[butterId] then
			makeButterButton(butterId)
		end

		local butter = state.ButterConfig[butterId]
		local owned = state.Butter[butterId] or 0
		local button = butterButtons[butterId]

		button.LayoutOrder = butter.Order
		button.BackgroundColor3 = if butterId == selectedButterId then Color3.fromRGB(255, 216, 78) else Color3.fromRGB(255, 238, 158)
		button.Text = `{butter.Name}  |  Own: {owned}  |  Cost: {butter.Cost}`
	end

	local selectedButter = state.ButterConfig[selectedButterId]
	crackButton.Text = `Crack {selectedButter.Name}`
	buyButton.Text = `Buy {selectedButter.Name} ({selectedButter.Cost} coins)`

	local countsByRarity = {}
	for _, needohId in ipairs(state.Needohs) do
		local needoh = state.NeedohConfig[needohId]
		if needoh then
			countsByRarity[needoh.Rarity] = (countsByRarity[needoh.Rarity] or 0) + 1
		end
	end

	local parts = {}
	for rarityId, rarity in pairs(state.RarityConfig) do
		table.insert(parts, {
			Order = rarity.Order,
			Text = `{rarity.Name}: {countsByRarity[rarityId] or 0}`,
		})
	end

	table.sort(parts, function(left, right)
		return left.Order < right.Order
	end)

	local collectionText = {}
	for _, part in ipairs(parts) do
		table.insert(collectionText, part.Text)
	end

	collection.Text = `Needohs owned: {#state.Needohs}\n{table.concat(collectionText, "  |  ")}`
end

local function applyResponse(response)
	if not response then
		message.Text = "Something went wrong."
		return
	end

	if response.State then
		state = response.State
	end

	if response.Message then
		message.Text = response.Message
	end

	if response.Prize then
		local color = rarityColor(response.Prize.Rarity)
		message.TextColor3 = color
	else
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
	end

	refresh()
end

crackButton.Activated:Connect(function()
	applyResponse(CrackButter:InvokeServer(selectedButterId))
end)

buyButton.Activated:Connect(function()
	applyResponse(BuyButter:InvokeServer(selectedButterId))
end)

applyResponse(GetState:InvokeServer())

task.spawn(function()
	while true do
		task.wait(1)
		applyResponse(GetState:InvokeServer())
	end
end)
