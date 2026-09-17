local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local remotes = ReplicatedStorage:WaitForChild("ButterRemotes")
local butterModels = ReplicatedStorage:FindFirstChild("ButterModels")
local beebohModels = ReplicatedStorage:FindFirstChild("BeebohModels")

local GetState = remotes:WaitForChild("GetState")
local BuyButter = remotes:WaitForChild("BuyButter")
local CrackButter = remotes:WaitForChild("CrackButter")
local DeleteBeeboh = remotes:WaitForChild("DeleteBeeboh")
local RenameBeeboh = remotes:WaitForChild("RenameBeeboh")
local ToggleEquipBeeboh = remotes:WaitForChild("ToggleEquipBeeboh")
local PrizeRevealed = remotes:WaitForChild("PrizeRevealed")

local state = nil
local selectedButterId = nil
local selectedShopButterId = nil
local previewModel = nil
local previewRotation = 0

local gui = Instance.new("ScreenGui")
gui.Name = "SquishTheButterGui"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local root = Instance.new("Frame")
root.AnchorPoint = Vector2.new(0, 0.5)
root.BackgroundTransparency = 1
root.BorderSizePixel = 0
root.Size = UDim2.fromOffset(64, 132)
root.Position = UDim2.new(0, 18, 0.5, 0)
root.Parent = gui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 8)
corner.Parent = root

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(116, 86, 36)
stroke.Thickness = 0
stroke.Parent = root

local padding = Instance.new("UIPadding")
padding.PaddingTop = UDim.new(0, 0)
padding.PaddingRight = UDim.new(0, 0)
padding.PaddingBottom = UDim.new(0, 0)
padding.PaddingLeft = UDim.new(0, 0)
padding.Parent = root

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout:Destroy()

local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Font = Enum.Font.GothamBlack
title.Text = "Squish the Butter"
title.TextColor3 = Color3.fromRGB(83, 55, 21)
title.TextSize = 26
title.TextXAlignment = Enum.TextXAlignment.Left
title.Size = UDim2.new(1, 0, 0, 32)
title.LayoutOrder = 1
title.Visible = false
title.Size = UDim2.fromOffset(0, 0)
title.Parent = root

local stats = Instance.new("TextLabel")
stats.BackgroundTransparency = 1
stats.Font = Enum.Font.GothamBold
stats.TextColor3 = Color3.fromRGB(83, 55, 21)
stats.TextSize = 18
stats.TextXAlignment = Enum.TextXAlignment.Left
stats.Size = UDim2.new(1, 0, 0, 52)
stats.LayoutOrder = 2
stats.Visible = false
stats.Size = UDim2.fromOffset(0, 0)
stats.Parent = root

local message = Instance.new("TextLabel")
message.BackgroundColor3 = Color3.fromRGB(255, 232, 111)
message.Font = Enum.Font.GothamBold
message.Text = "Open the shop to buy butter. Owned butter shows at the bottom."
message.TextColor3 = Color3.fromRGB(83, 55, 21)
message.TextSize = 15
message.TextWrapped = true
message.Size = UDim2.new(1, 0, 0, 52)
message.LayoutOrder = 3
message.Visible = false
message.Size = UDim2.fromOffset(0, 0)
message.Parent = root

local messageCorner = Instance.new("UICorner")
messageCorner.CornerRadius = UDim.new(0, 8)
messageCorner.Parent = message

local shopButton = Instance.new("TextButton")
shopButton.BackgroundColor3 = Color3.fromRGB(91, 181, 112)
shopButton.Font = Enum.Font.GothamBlack
shopButton.Text = "🛒"
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextSize = 30
shopButton.Position = UDim2.fromOffset(3, 0)
shopButton.Size = UDim2.fromOffset(58, 58)
shopButton.LayoutOrder = 4
shopButton.Parent = root

local shopButtonCorner = Instance.new("UICorner")
shopButtonCorner.CornerRadius = UDim.new(0, 8)
shopButtonCorner.Parent = shopButton

local beebohInventoryButton = Instance.new("TextButton")
beebohInventoryButton.BackgroundColor3 = Color3.fromRGB(76, 166, 255)
beebohInventoryButton.Font = Enum.Font.GothamBlack
beebohInventoryButton.Text = "🎒"
beebohInventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
beebohInventoryButton.TextSize = 30
beebohInventoryButton.Position = UDim2.fromOffset(3, 70)
beebohInventoryButton.Size = UDim2.fromOffset(58, 58)
beebohInventoryButton.LayoutOrder = 5
beebohInventoryButton.Parent = root

local beebohInventoryCorner = Instance.new("UICorner")
beebohInventoryCorner.CornerRadius = UDim.new(0, 8)
beebohInventoryCorner.Parent = beebohInventoryButton

local collection = Instance.new("TextLabel")
collection.BackgroundTransparency = 1
collection.Font = Enum.Font.Gotham
collection.TextColor3 = Color3.fromRGB(83, 55, 21)
collection.TextSize = 14
collection.TextWrapped = true
collection.TextXAlignment = Enum.TextXAlignment.Left
collection.TextYAlignment = Enum.TextYAlignment.Top
collection.Size = UDim2.new(1, -250, 0, 70)
collection.LayoutOrder = 6
collection.Parent = gui

local shopPanel = Instance.new("Frame")
shopPanel.AnchorPoint = Vector2.new(0.5, 0.5)
shopPanel.BackgroundColor3 = Color3.fromRGB(255, 246, 196)
shopPanel.BorderSizePixel = 0
shopPanel.Position = UDim2.fromScale(0.5, 0.5)
shopPanel.Size = UDim2.fromOffset(430, 430)
shopPanel.Visible = false
shopPanel.Parent = gui

local shopPanelCorner = Instance.new("UICorner")
shopPanelCorner.CornerRadius = UDim.new(0, 8)
shopPanelCorner.Parent = shopPanel

local shopPanelStroke = Instance.new("UIStroke")
shopPanelStroke.Color = Color3.fromRGB(116, 86, 36)
shopPanelStroke.Thickness = 2
shopPanelStroke.Parent = shopPanel

local shopCloseButton = Instance.new("TextButton")
shopCloseButton.AnchorPoint = Vector2.new(1, 0)
shopCloseButton.BackgroundColor3 = Color3.fromRGB(219, 77, 77)
shopCloseButton.Font = Enum.Font.GothamBlack
shopCloseButton.Position = UDim2.new(1, -10, 0, 10)
shopCloseButton.Size = UDim2.fromOffset(34, 34)
shopCloseButton.Text = "X"
shopCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopCloseButton.TextSize = 18
shopCloseButton.Parent = shopPanel

local shopCloseCorner = Instance.new("UICorner")
shopCloseCorner.CornerRadius = UDim.new(0, 8)
shopCloseCorner.Parent = shopCloseButton

local shopPadding = Instance.new("UIPadding")
shopPadding.PaddingTop = UDim.new(0, 14)
shopPadding.PaddingRight = UDim.new(0, 14)
shopPadding.PaddingBottom = UDim.new(0, 14)
shopPadding.PaddingLeft = UDim.new(0, 14)
shopPadding.Parent = shopPanel

local shopLayout = Instance.new("UIListLayout")
shopLayout.Padding = UDim.new(0, 10)
shopLayout.SortOrder = Enum.SortOrder.LayoutOrder
shopLayout.Parent = shopPanel

local shopTitle = Instance.new("TextLabel")
shopTitle.BackgroundTransparency = 1
shopTitle.Font = Enum.Font.GothamBlack
shopTitle.Text = "Butter Shop"
shopTitle.TextColor3 = Color3.fromRGB(83, 55, 21)
shopTitle.TextSize = 26
shopTitle.TextXAlignment = Enum.TextXAlignment.Left
shopTitle.Size = UDim2.new(1, 0, 0, 32)
shopTitle.LayoutOrder = 1
shopTitle.Parent = shopPanel

local butterList = Instance.new("ScrollingFrame")
butterList.BackgroundTransparency = 1
butterList.BorderSizePixel = 0
butterList.CanvasSize = UDim2.fromOffset(0, 0)
butterList.AutomaticCanvasSize = Enum.AutomaticSize.Y
butterList.ScrollBarThickness = 6
butterList.Size = UDim2.new(1, 0, 0, 270)
butterList.LayoutOrder = 2
butterList.Parent = shopPanel

local butterLayout = Instance.new("UIListLayout")
butterLayout.Padding = UDim.new(0, 8)
butterLayout.SortOrder = Enum.SortOrder.LayoutOrder
butterLayout.Parent = butterList

local buyButton = Instance.new("TextButton")
buyButton.BackgroundColor3 = Color3.fromRGB(91, 181, 112)
buyButton.Font = Enum.Font.GothamBlack
buyButton.Text = "Buy Selected Butter"
buyButton.TextColor3 = Color3.fromRGB(255, 255, 255)
buyButton.TextSize = 18
buyButton.Size = UDim2.new(1, 0, 0, 46)
buyButton.LayoutOrder = 3
buyButton.Parent = shopPanel

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 8)
buyCorner.Parent = buyButton

local butterHotbar = Instance.new("Frame")
butterHotbar.AnchorPoint = Vector2.new(0.5, 1)
butterHotbar.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
butterHotbar.BackgroundTransparency = 0.35
butterHotbar.BorderSizePixel = 0
butterHotbar.Position = UDim2.new(0.5, 0, 1, -18)
butterHotbar.Size = UDim2.fromOffset(560, 92)
butterHotbar.Parent = gui

local butterHotbarCorner = Instance.new("UICorner")
butterHotbarCorner.CornerRadius = UDim.new(0, 8)
butterHotbarCorner.Parent = butterHotbar

local butterHotbarPadding = Instance.new("UIPadding")
butterHotbarPadding.PaddingTop = UDim.new(0, 10)
butterHotbarPadding.PaddingRight = UDim.new(0, 10)
butterHotbarPadding.PaddingBottom = UDim.new(0, 10)
butterHotbarPadding.PaddingLeft = UDim.new(0, 10)
butterHotbarPadding.Parent = butterHotbar

local butterHotbarLayout = Instance.new("UIListLayout")
butterHotbarLayout.FillDirection = Enum.FillDirection.Horizontal
butterHotbarLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
butterHotbarLayout.VerticalAlignment = Enum.VerticalAlignment.Center
butterHotbarLayout.Padding = UDim.new(0, 10)
butterHotbarLayout.SortOrder = Enum.SortOrder.LayoutOrder
butterHotbarLayout.Parent = butterHotbar

local previewPanel = Instance.new("Frame")
previewPanel.AnchorPoint = Vector2.new(0.5, 0.5)
previewPanel.BackgroundColor3 = Color3.fromRGB(255, 248, 214)
previewPanel.BorderSizePixel = 0
previewPanel.Position = UDim2.fromScale(0.5, 0.5)
previewPanel.Size = UDim2.fromOffset(360, 340)
previewPanel.Visible = false
previewPanel.Parent = gui

local previewCorner = Instance.new("UICorner")
previewCorner.CornerRadius = UDim.new(0, 8)
previewCorner.Parent = previewPanel

local previewStroke = Instance.new("UIStroke")
previewStroke.Color = Color3.fromRGB(116, 86, 36)
previewStroke.Thickness = 2
previewStroke.Parent = previewPanel

local previewPadding = Instance.new("UIPadding")
previewPadding.PaddingTop = UDim.new(0, 12)
previewPadding.PaddingRight = UDim.new(0, 12)
previewPadding.PaddingBottom = UDim.new(0, 12)
previewPadding.PaddingLeft = UDim.new(0, 12)
previewPadding.Parent = previewPanel

local previewLayout = Instance.new("UIListLayout")
previewLayout.Padding = UDim.new(0, 10)
previewLayout.SortOrder = Enum.SortOrder.LayoutOrder
previewLayout.Parent = previewPanel

local previewTitle = Instance.new("TextLabel")
previewTitle.BackgroundTransparency = 1
previewTitle.Font = Enum.Font.GothamBlack
previewTitle.TextColor3 = Color3.fromRGB(83, 55, 21)
previewTitle.TextSize = 22
previewTitle.TextXAlignment = Enum.TextXAlignment.Left
previewTitle.Size = UDim2.new(1, 0, 0, 28)
previewTitle.LayoutOrder = 1
previewTitle.Parent = previewPanel

local viewport = Instance.new("ViewportFrame")
viewport.BackgroundColor3 = Color3.fromRGB(255, 238, 158)
viewport.BorderSizePixel = 0
viewport.Size = UDim2.new(1, 0, 0, 190)
viewport.LayoutOrder = 2
viewport.Parent = previewPanel

local viewportCorner = Instance.new("UICorner")
viewportCorner.CornerRadius = UDim.new(0, 8)
viewportCorner.Parent = viewport

local previewCamera = Instance.new("Camera")
previewCamera.CFrame = CFrame.new(0, 1.5, 7) * CFrame.Angles(math.rad(-10), 0, 0)
previewCamera.Parent = viewport
viewport.CurrentCamera = previewCamera

local previewInfo = Instance.new("TextLabel")
previewInfo.BackgroundTransparency = 1
previewInfo.Font = Enum.Font.GothamBold
previewInfo.TextColor3 = Color3.fromRGB(83, 55, 21)
previewInfo.TextSize = 14
previewInfo.TextWrapped = true
previewInfo.TextXAlignment = Enum.TextXAlignment.Left
previewInfo.Size = UDim2.new(1, 0, 0, 42)
previewInfo.LayoutOrder = 3
previewInfo.Parent = previewPanel

local previewCrackButton = Instance.new("TextButton")
previewCrackButton.BackgroundColor3 = Color3.fromRGB(255, 199, 52)
previewCrackButton.Font = Enum.Font.GothamBlack
previewCrackButton.Text = "Crack This Butter"
previewCrackButton.TextColor3 = Color3.fromRGB(83, 55, 21)
previewCrackButton.TextSize = 20
previewCrackButton.Size = UDim2.new(1, 0, 0, 48)
previewCrackButton.LayoutOrder = 4
previewCrackButton.Parent = previewPanel

local previewCrackCorner = Instance.new("UICorner")
previewCrackCorner.CornerRadius = UDim.new(0, 8)
previewCrackCorner.Parent = previewCrackButton

local previewCloseButton = Instance.new("TextButton")
previewCloseButton.AnchorPoint = Vector2.new(1, 0)
previewCloseButton.BackgroundColor3 = Color3.fromRGB(219, 77, 77)
previewCloseButton.Font = Enum.Font.GothamBlack
previewCloseButton.Position = UDim2.new(1, -8, 0, 8)
previewCloseButton.Size = UDim2.fromOffset(34, 34)
previewCloseButton.Text = "X"
previewCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
previewCloseButton.TextSize = 18
previewCloseButton.Parent = previewPanel

local previewCloseCorner = Instance.new("UICorner")
previewCloseCorner.CornerRadius = UDim.new(0, 8)
previewCloseCorner.Parent = previewCloseButton

local beebohPanel = Instance.new("Frame")
beebohPanel.AnchorPoint = Vector2.new(0.5, 0.5)
beebohPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
beebohPanel.BackgroundTransparency = 0.36
beebohPanel.BorderSizePixel = 0
beebohPanel.Position = UDim2.fromScale(0.5, 0.5)
beebohPanel.Size = UDim2.fromOffset(640, 520)
beebohPanel.Visible = false
beebohPanel.Parent = gui

local beebohPanelCorner = Instance.new("UICorner")
beebohPanelCorner.CornerRadius = UDim.new(0, 8)
beebohPanelCorner.Parent = beebohPanel

local beebohPanelStroke = Instance.new("UIStroke")
beebohPanelStroke.Color = Color3.fromRGB(72, 72, 72)
beebohPanelStroke.Thickness = 2
beebohPanelStroke.Parent = beebohPanel

local beebohCloseButton = Instance.new("TextButton")
beebohCloseButton.AnchorPoint = Vector2.new(1, 0)
beebohCloseButton.BackgroundColor3 = Color3.fromRGB(219, 77, 77)
beebohCloseButton.Font = Enum.Font.GothamBlack
beebohCloseButton.Position = UDim2.new(1, -10, 0, 10)
beebohCloseButton.Size = UDim2.fromOffset(34, 34)
beebohCloseButton.Text = "X"
beebohCloseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
beebohCloseButton.TextSize = 18
beebohCloseButton.Parent = beebohPanel

local beebohCloseCorner = Instance.new("UICorner")
beebohCloseCorner.CornerRadius = UDim.new(0, 8)
beebohCloseCorner.Parent = beebohCloseButton

local beebohPanelTitle = Instance.new("TextLabel")
beebohPanelTitle.BackgroundTransparency = 1
beebohPanelTitle.Font = Enum.Font.GothamBlack
beebohPanelTitle.Text = "Beebohs"
beebohPanelTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
beebohPanelTitle.TextSize = 34
beebohPanelTitle.Position = UDim2.fromOffset(0, 14)
beebohPanelTitle.Size = UDim2.new(1, -214, 0, 44)
beebohPanelTitle.Parent = beebohPanel

local beebohCapacity = Instance.new("TextLabel")
beebohCapacity.BackgroundTransparency = 1
beebohCapacity.Font = Enum.Font.GothamBold
beebohCapacity.TextColor3 = Color3.fromRGB(255, 255, 255)
beebohCapacity.TextSize = 24
beebohCapacity.TextXAlignment = Enum.TextXAlignment.Left
beebohCapacity.Position = UDim2.new(0, 28, 1, -70)
beebohCapacity.Size = UDim2.new(1, -250, 0, 34)
beebohCapacity.Parent = beebohPanel

collection.TextColor3 = Color3.fromRGB(255, 255, 255)
collection.TextSize = 15
collection.Position = UDim2.new(0, 28, 1, -126)
collection.Size = UDim2.new(1, -250, 0, 54)
collection.Parent = beebohPanel

local beebohList = Instance.new("ScrollingFrame")
beebohList.BackgroundTransparency = 1
beebohList.BorderSizePixel = 0
beebohList.CanvasSize = UDim2.fromOffset(0, 0)
beebohList.AutomaticCanvasSize = Enum.AutomaticSize.Y
beebohList.ScrollBarThickness = 5
beebohList.Position = UDim2.fromOffset(28, 86)
beebohList.Size = UDim2.new(1, -250, 1, -180)
beebohList.Parent = beebohPanel

local beebohGridLayout = Instance.new("UIGridLayout")
beebohGridLayout.CellPadding = UDim2.fromOffset(18, 16)
beebohGridLayout.CellSize = UDim2.fromOffset(70, 98)
beebohGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
beebohGridLayout.Parent = beebohList

local beebohDetailPanel = Instance.new("Frame")
beebohDetailPanel.AnchorPoint = Vector2.new(1, 0)
beebohDetailPanel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
beebohDetailPanel.BackgroundTransparency = 0.45
beebohDetailPanel.BorderSizePixel = 0
beebohDetailPanel.Position = UDim2.new(1, -2, 0, 34)
beebohDetailPanel.Size = UDim2.new(0, 210, 1, -36)
beebohDetailPanel.Visible = false
beebohDetailPanel.Parent = beebohPanel

local beebohDetailStroke = Instance.new("UIStroke")
beebohDetailStroke.Color = Color3.fromRGB(26, 26, 26)
beebohDetailStroke.Thickness = 2
beebohDetailStroke.Parent = beebohDetailPanel

local beebohDetailName = Instance.new("TextLabel")
beebohDetailName.BackgroundTransparency = 1
beebohDetailName.Font = Enum.Font.GothamBlack
beebohDetailName.TextColor3 = Color3.fromRGB(76, 166, 255)
beebohDetailName.TextSize = 24
beebohDetailName.TextXAlignment = Enum.TextXAlignment.Left
beebohDetailName.TextWrapped = true
beebohDetailName.Position = UDim2.fromOffset(16, 10)
beebohDetailName.Size = UDim2.new(1, -30, 0, 58)
beebohDetailName.Parent = beebohDetailPanel

local beebohRenameBox = Instance.new("TextBox")
beebohRenameBox.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
beebohRenameBox.BackgroundTransparency = 0.18
beebohRenameBox.ClearTextOnFocus = false
beebohRenameBox.Font = Enum.Font.GothamBlack
beebohRenameBox.PlaceholderText = "New name"
beebohRenameBox.Text = ""
beebohRenameBox.TextColor3 = Color3.fromRGB(255, 255, 255)
beebohRenameBox.TextSize = 20
beebohRenameBox.TextXAlignment = Enum.TextXAlignment.Left
beebohRenameBox.Position = UDim2.fromOffset(16, 12)
beebohRenameBox.Size = UDim2.new(1, -30, 0, 42)
beebohRenameBox.Visible = false
beebohRenameBox.Parent = beebohDetailPanel

local beebohRenameBoxCorner = Instance.new("UICorner")
beebohRenameBoxCorner.CornerRadius = UDim.new(0, 8)
beebohRenameBoxCorner.Parent = beebohRenameBox

local beebohDetailViewport = Instance.new("ViewportFrame")
beebohDetailViewport.BackgroundTransparency = 1
beebohDetailViewport.BorderSizePixel = 0
beebohDetailViewport.Position = UDim2.fromOffset(28, 72)
beebohDetailViewport.Size = UDim2.fromOffset(154, 170)
beebohDetailViewport.Parent = beebohDetailPanel

local beebohDetailCamera = Instance.new("Camera")
beebohDetailCamera.Parent = beebohDetailViewport
beebohDetailViewport.CurrentCamera = beebohDetailCamera

local beebohDetailInfo = Instance.new("TextLabel")
beebohDetailInfo.BackgroundTransparency = 1
beebohDetailInfo.Font = Enum.Font.GothamBold
beebohDetailInfo.TextColor3 = Color3.fromRGB(255, 255, 255)
beebohDetailInfo.TextSize = 20
beebohDetailInfo.TextWrapped = true
beebohDetailInfo.TextXAlignment = Enum.TextXAlignment.Left
beebohDetailInfo.TextYAlignment = Enum.TextYAlignment.Top
beebohDetailInfo.Position = UDim2.fromOffset(16, 236)
beebohDetailInfo.Size = UDim2.new(1, -28, 0, 48)
beebohDetailInfo.Parent = beebohDetailPanel

local beebohRenameButton = Instance.new("TextButton")
beebohRenameButton.BackgroundColor3 = Color3.fromRGB(55, 168, 69)
beebohRenameButton.Font = Enum.Font.GothamBlack
beebohRenameButton.Text = "Rename"
beebohRenameButton.TextColor3 = Color3.fromRGB(190, 255, 190)
beebohRenameButton.TextSize = 21
beebohRenameButton.Position = UDim2.new(0, 14, 1, -150)
beebohRenameButton.Size = UDim2.new(1, -28, 0, 44)
beebohRenameButton.Parent = beebohDetailPanel

local beebohRenameStroke = Instance.new("UIStroke")
beebohRenameStroke.Color = Color3.fromRGB(71, 255, 86)
beebohRenameStroke.Thickness = 2
beebohRenameStroke.Parent = beebohRenameButton

local beebohEquipButton = Instance.new("TextButton")
beebohEquipButton.BackgroundColor3 = Color3.fromRGB(76, 166, 255)
beebohEquipButton.Font = Enum.Font.GothamBlack
beebohEquipButton.Text = "Equip"
beebohEquipButton.TextColor3 = Color3.fromRGB(218, 239, 255)
beebohEquipButton.TextSize = 21
beebohEquipButton.Position = UDim2.new(0, 14, 1, -196)
beebohEquipButton.Size = UDim2.new(1, -28, 0, 44)
beebohEquipButton.Parent = beebohDetailPanel

local beebohEquipStroke = Instance.new("UIStroke")
beebohEquipStroke.Color = Color3.fromRGB(126, 220, 255)
beebohEquipStroke.Thickness = 2
beebohEquipStroke.Parent = beebohEquipButton

local beebohDeleteButton = Instance.new("TextButton")
beebohDeleteButton.BackgroundColor3 = Color3.fromRGB(87, 30, 30)
beebohDeleteButton.Font = Enum.Font.GothamBlack
beebohDeleteButton.Text = "Delete"
beebohDeleteButton.TextColor3 = Color3.fromRGB(255, 75, 75)
beebohDeleteButton.TextSize = 21
beebohDeleteButton.Position = UDim2.new(0, 14, 1, -86)
beebohDeleteButton.Size = UDim2.new(1, -28, 0, 44)
beebohDeleteButton.Parent = beebohDetailPanel

local beebohDeleteStroke = Instance.new("UIStroke")
beebohDeleteStroke.Color = Color3.fromRGB(255, 36, 36)
beebohDeleteStroke.Thickness = 2
beebohDeleteStroke.Parent = beebohDeleteButton

local crackingOverlay = Instance.new("Frame")
crackingOverlay.BackgroundColor3 = Color3.fromRGB(18, 14, 8)
crackingOverlay.BackgroundTransparency = 0.08
crackingOverlay.BorderSizePixel = 0
crackingOverlay.Size = UDim2.fromScale(1, 1)
crackingOverlay.Visible = false
crackingOverlay.ZIndex = 50
crackingOverlay.Parent = gui

local crackingViewport = Instance.new("ViewportFrame")
crackingViewport.AnchorPoint = Vector2.new(0.5, 0.5)
crackingViewport.BackgroundTransparency = 1
crackingViewport.BorderSizePixel = 0
crackingViewport.Position = UDim2.fromScale(0.5, 0.48)
crackingViewport.Size = UDim2.fromScale(1, 0.82)
crackingViewport.ZIndex = 51
crackingViewport.Parent = crackingOverlay

local crackingCamera = Instance.new("Camera")
crackingCamera.Parent = crackingViewport
crackingViewport.CurrentCamera = crackingCamera

local crackingTitle = Instance.new("TextLabel")
crackingTitle.AnchorPoint = Vector2.new(0.5, 0)
crackingTitle.BackgroundTransparency = 1
crackingTitle.Font = Enum.Font.GothamBlack
crackingTitle.Position = UDim2.fromScale(0.5, 0.05)
crackingTitle.Size = UDim2.fromScale(0.86, 0.09)
crackingTitle.Text = "Click the butter"
crackingTitle.TextColor3 = Color3.fromRGB(255, 238, 158)
crackingTitle.TextScaled = true
crackingTitle.TextStrokeTransparency = 0.35
crackingTitle.ZIndex = 55
crackingTitle.Parent = crackingOverlay

local crackingHint = Instance.new("TextLabel")
crackingHint.AnchorPoint = Vector2.new(0.5, 1)
crackingHint.BackgroundTransparency = 1
crackingHint.Font = Enum.Font.GothamBold
crackingHint.Position = UDim2.fromScale(0.5, 0.95)
crackingHint.Size = UDim2.fromScale(0.86, 0.06)
crackingHint.Text = "3 hits to crack"
crackingHint.TextColor3 = Color3.fromRGB(255, 255, 245)
crackingHint.TextScaled = true
crackingHint.TextStrokeTransparency = 0.45
crackingHint.ZIndex = 55
crackingHint.Parent = crackingOverlay

local overlayClickButton = Instance.new("TextButton")
overlayClickButton.BackgroundTransparency = 1
overlayClickButton.BorderSizePixel = 0
overlayClickButton.Size = UDim2.fromScale(1, 1)
overlayClickButton.Text = ""
overlayClickButton.ZIndex = 60
overlayClickButton.Parent = crackingOverlay

local crackMarks = {}
local lastClickPosition = nil

local revealLabel = Instance.new("TextLabel")
revealLabel.AnchorPoint = Vector2.new(0.5, 0.5)
revealLabel.BackgroundColor3 = Color3.fromRGB(255, 238, 158)
revealLabel.BackgroundTransparency = 0.08
revealLabel.Font = Enum.Font.GothamBlack
revealLabel.Position = UDim2.fromScale(0.5, 0.78)
revealLabel.Size = UDim2.fromScale(0.46, 0.14)
revealLabel.Text = ""
revealLabel.TextColor3 = Color3.fromRGB(83, 55, 21)
revealLabel.TextScaled = true
revealLabel.TextWrapped = true
revealLabel.Visible = false
revealLabel.ZIndex = 58
revealLabel.Parent = crackingOverlay

local revealCorner = Instance.new("UICorner")
revealCorner.CornerRadius = UDim.new(0, 8)
revealCorner.Parent = revealLabel

local revealCloseButton = Instance.new("TextButton")
revealCloseButton.AnchorPoint = Vector2.new(0.5, 0)
revealCloseButton.BackgroundColor3 = Color3.fromRGB(255, 255, 245)
revealCloseButton.BackgroundTransparency = 0.08
revealCloseButton.Font = Enum.Font.GothamBlack
revealCloseButton.Position = UDim2.fromScale(0.5, 0.9)
revealCloseButton.Size = UDim2.fromOffset(150, 44)
revealCloseButton.Text = "Close"
revealCloseButton.TextColor3 = Color3.fromRGB(83, 55, 21)
revealCloseButton.TextSize = 20
revealCloseButton.Visible = false
revealCloseButton.ZIndex = 75
revealCloseButton.Parent = crackingOverlay

local revealCloseCorner = Instance.new("UICorner")
revealCloseCorner.CornerRadius = UDim.new(0, 8)
revealCloseCorner.Parent = revealCloseButton

local shopButterButtons = {}
local butterHotbarButtons = {}
local beebohRows = {}
local selectedBeebohIndex = nil
local refresh
local applyResponse
local showButterPreview
local crackingModel = nil
local crackingButterId = nil
local crackingStage = 0
local crackingBusy = false
local revealModel = nil
local CRACKING_BUTTER_CFRAME = CFrame.Angles(0, math.rad(180), 0)

local function findButterModel(butter)
	if butterModels then
		local storedModel = butterModels:FindFirstChild(butter.Id) or butterModels:FindFirstChild(butter.Name)
		if storedModel and (storedModel:IsA("Model") or storedModel:IsA("BasePart")) then
			return storedModel
		end
	end

	for _, descendant in ipairs(Workspace:GetDescendants()) do
		if descendant:IsA("Model") or descendant:IsA("BasePart") then
			local butterId = descendant:GetAttribute("ButterId")
			if butterId == butter.Id then
				return descendant
			end

			if butter.Id == "Plain" and (descendant.Name == "ButterStick" or descendant.Name == "ButterStation") then
				return descendant
			end
		end
	end

	return nil
end

local function findBeebohModel(prize)
	if not beebohModels then
		return nil
	end

	local sourceModel = beebohModels:FindFirstChild(prize.Id) or beebohModels:FindFirstChild(prize.Name)
	if sourceModel and (sourceModel:IsA("Model") or sourceModel:IsA("BasePart")) then
		return sourceModel
	end

	return nil
end

local function preparePreviewModel(source, targetViewport)
	local clone = source:Clone()
	clone.Name = "PreviewButterStick"

	local model
	if clone:IsA("BasePart") then
		model = Instance.new("Model")
		model.Name = "PreviewButterStickModel"
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

	model.Parent = targetViewport

	for _, descendant in ipairs(model:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Anchored = true
			descendant.CanCollide = false
			if string.find(string.lower(descendant.Name), "wrapper") then
				descendant.Material = Enum.Material.Glass
				descendant.Transparency = math.max(descendant.Transparency, 0.35)
			end
		elseif descendant:IsA("ProximityPrompt") or descendant:IsA("Script") or descendant:IsA("LocalScript") then
			descendant:Destroy()
		end
	end

	model:PivotTo(CFrame.new())
	return model
end

local function frameModel(model, camera, distanceScale, fieldOfView)
	if not model or not model.PrimaryPart then
		return
	end

	local _, size = model:GetBoundingBox()
	local maxSize = math.max(size.X, size.Y, size.Z, 1)
	local distance = math.clamp(maxSize * distanceScale, 1.6, 8)
	local height = math.clamp(size.Y * 0.25, 0.25, 1.5)

	camera.FieldOfView = fieldOfView
	camera.CFrame = CFrame.new(Vector3.new(0, height, distance), Vector3.new(0, height * 0.25, 0))
end

local function framePreviewModel()
	frameModel(previewModel, previewCamera, 1.25, 38)
end

local function clearPreview()
	for _, child in ipairs(viewport:GetChildren()) do
		if child ~= previewCamera and child ~= viewportCorner then
			child:Destroy()
		end
	end

	previewModel = nil
end

local function createButterPreviewModel(butter)
	clearPreview()

	local sourceModel = findButterModel(butter)
	if sourceModel then
		previewModel = preparePreviewModel(sourceModel, viewport)
		if previewModel then
			previewRotation = 0
			framePreviewModel()
			return
		end
	end

	local model = Instance.new("Model")
	model.Name = "PreviewButterStick"
	model.Parent = viewport

	local stick = Instance.new("Part")
	stick.Name = "Butter"
	stick.Anchored = true
	stick.Color = butter.Color or Color3.fromRGB(255, 236, 128)
	stick.Material = Enum.Material.SmoothPlastic
	stick.Size = Vector3.new(4.4, 1.1, 1.1)
	stick.CFrame = CFrame.new(0, 0, 0)
	stick.Parent = model

	local wrapper = Instance.new("Part")
	wrapper.Name = "Wrapper"
	wrapper.Anchored = true
	wrapper.Color = Color3.fromRGB(255, 255, 245)
	wrapper.Material = Enum.Material.Glass
	wrapper.Transparency = 0.35
	wrapper.Size = Vector3.new(1.25, 1.18, 1.18)
	wrapper.CFrame = CFrame.new(0, 0, 0)
	wrapper.Parent = model

	local leftLine = Instance.new("Part")
	leftLine.Name = "WrapperLineLeft"
	leftLine.Anchored = true
	leftLine.Color = Color3.fromRGB(83, 55, 21)
	leftLine.Material = Enum.Material.SmoothPlastic
	leftLine.Size = Vector3.new(0.08, 1.22, 1.22)
	leftLine.CFrame = CFrame.new(-0.7, 0, 0)
	leftLine.Parent = model

	local rightLine = leftLine:Clone()
	rightLine.Name = "WrapperLineRight"
	rightLine.CFrame = CFrame.new(0.7, 0, 0)
	rightLine.Parent = model

	model.PrimaryPart = stick
	previewModel = model
	previewRotation = 0
	framePreviewModel()
end

local function clearCrackingViewport()
	for _, child in ipairs(crackingViewport:GetChildren()) do
		if child ~= crackingCamera then
			child:Destroy()
		end
	end

	crackingModel = nil
	revealModel = nil
end

local function clearCrackMarks()
	for _, mark in ipairs(crackMarks) do
		mark:Destroy()
	end

	table.clear(crackMarks)
end

local function addCrackSegment(center, length, thickness, rotation)
	local segment = Instance.new("Frame")
	segment.AnchorPoint = Vector2.new(0.5, 0.5)
	segment.BackgroundColor3 = Color3.fromRGB(69, 43, 18)
	segment.BorderSizePixel = 0
	segment.Position = UDim2.fromOffset(center.X, center.Y)
	segment.Rotation = rotation
	segment.Size = UDim2.fromOffset(thickness, length)
	segment.ZIndex = 56
	segment.Parent = crackingOverlay

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = segment

	table.insert(crackMarks, segment)
	return segment
end

local function addClickCrack(screenPosition, stage)
	local overlayPosition = crackingOverlay.AbsolutePosition
	local overlaySize = crackingOverlay.AbsoluteSize
	local x = math.clamp(screenPosition.X - overlayPosition.X, overlaySize.X * 0.18, overlaySize.X * 0.82)
	local y = math.clamp(screenPosition.Y - overlayPosition.Y, overlaySize.Y * 0.22, overlaySize.Y * 0.72)
	local center = Vector2.new(x, y)
	local baseLength = 54 + stage * 22
	local baseRotation = math.random(-55, 55)

	addCrackSegment(center, baseLength, 4 + stage, baseRotation)
	addCrackSegment(center + Vector2.new(math.random(-18, 18), math.random(-14, 14)), baseLength * 0.58, 3, baseRotation + math.random(36, 66))
	addCrackSegment(center + Vector2.new(math.random(-18, 18), math.random(-14, 14)), baseLength * 0.48, 3, baseRotation - math.random(36, 66))

	if stage >= 3 then
		addCrackSegment(center + Vector2.new(math.random(-24, 24), math.random(-18, 18)), baseLength * 0.7, 3, baseRotation + math.random(82, 112))
	end
end

local function createFallbackButterModel(butter, targetViewport)
	local model = Instance.new("Model")
	model.Name = "PreviewButterStick"
	model.Parent = targetViewport

	local stick = Instance.new("Part")
	stick.Name = "Butter"
	stick.Anchored = true
	stick.Color = butter.Color or Color3.fromRGB(255, 236, 128)
	stick.Material = Enum.Material.SmoothPlastic
	stick.Size = Vector3.new(4.4, 1.1, 1.1)
	stick.CFrame = CFrame.new()
	stick.Parent = model

	local wrapper = Instance.new("Part")
	wrapper.Name = "Wrapper"
	wrapper.Anchored = true
	wrapper.Color = Color3.fromRGB(255, 255, 245)
	wrapper.Material = Enum.Material.Glass
	wrapper.Transparency = 0.35
	wrapper.Size = Vector3.new(1.25, 1.18, 1.18)
	wrapper.CFrame = CFrame.new()
	wrapper.Parent = model

	local leftLine = Instance.new("Part")
	leftLine.Name = "WrapperLineLeft"
	leftLine.Anchored = true
	leftLine.Color = Color3.fromRGB(83, 55, 21)
	leftLine.Material = Enum.Material.SmoothPlastic
	leftLine.Size = Vector3.new(0.08, 1.22, 1.22)
	leftLine.CFrame = CFrame.new(-0.7, 0, 0)
	leftLine.Parent = model

	local rightLine = leftLine:Clone()
	rightLine.Name = "WrapperLineRight"
	rightLine.CFrame = CFrame.new(0.7, 0, 0)
	rightLine.Parent = model

	model.PrimaryPart = stick
	return model
end

local function createButterViewportModel(butterId, targetViewport)
	local butter = state.ButterConfig[butterId]
	if not butter then
		return nil
	end

	butter.Id = butterId

	local sourceModel = findButterModel(butter)
	if sourceModel then
		local model = preparePreviewModel(sourceModel, targetViewport)
		if model then
			return model
		end
	end

	return createFallbackButterModel(butter, targetViewport)
end

local function loadCrackingButterModel(butterId)
	local butter = state.ButterConfig[butterId]
	if not butter then
		return
	end

	butter.Id = butterId
	clearCrackingViewport()

	local sourceModel = findButterModel(butter)
	if sourceModel then
		crackingModel = preparePreviewModel(sourceModel, crackingViewport)
	end

	if not crackingModel then
		crackingModel = createFallbackButterModel(butter, crackingViewport)
	end

	crackingModel:PivotTo(CRACKING_BUTTER_CFRAME)
	frameModel(crackingModel, crackingCamera, 1.35, 38)
end

local function spawnOverlaySparkles(amount)
	for _ = 1, amount do
		local sparkle = Instance.new("Frame")
		sparkle.AnchorPoint = Vector2.new(0.5, 0.5)
		sparkle.BackgroundColor3 = Color3.fromRGB(255, 248, 154)
		sparkle.BorderSizePixel = 0
		sparkle.Position = UDim2.fromScale(math.random(24, 76) / 100, math.random(22, 72) / 100)
		sparkle.Rotation = math.random(0, 180)
		sparkle.Size = UDim2.fromOffset(math.random(8, 18), math.random(8, 18))
		sparkle.ZIndex = 70
		sparkle.Parent = crackingOverlay

		local sparkleCorner = Instance.new("UICorner")
		sparkleCorner.CornerRadius = UDim.new(1, 0)
		sparkleCorner.Parent = sparkle

		local endPosition = sparkle.Position + UDim2.fromOffset(math.random(-80, 80), math.random(-90, 50))
		local tween = TweenService:Create(
			sparkle,
			TweenInfo.new(0.65, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
			{
				BackgroundTransparency = 1,
				Position = endPosition,
				Rotation = sparkle.Rotation + math.random(80, 220),
				Size = UDim2.fromOffset(2, 2),
			}
		)

		tween:Play()
		tween.Completed:Connect(function()
			sparkle:Destroy()
		end)
	end
end

local function createBeebohReveal(prize)
	clearCrackingViewport()
	clearCrackMarks()

	local rarity = state.RarityConfig[prize.Rarity]
	local sourceModel = findBeebohModel(prize)

	if sourceModel then
		revealModel = preparePreviewModel(sourceModel, crackingViewport)
	end

	if not revealModel then
		local ball = Instance.new("Part")
		ball.Name = "RevealedBeeboh"
		ball.Anchored = true
		ball.Shape = Enum.PartType.Ball
		ball.Material = Enum.Material.SmoothPlastic
		ball.Color = if rarity then rarity.Color else Color3.fromRGB(255, 255, 255)
		ball.Size = Vector3.new(2.8, 2.8, 2.8)
		ball.CFrame = CFrame.new()

		local model = Instance.new("Model")
		model.Name = "BeebohRevealModel"
		model.Parent = crackingViewport
		ball.Parent = model
		model.PrimaryPart = ball

		revealModel = model
	end

	frameModel(revealModel, crackingCamera, 1.85, 38)

	revealLabel.Text = `{prize.Name}\n+{prize.CoinsPerSecond}/sec`
	revealLabel.TextColor3 = if rarity then rarity.Color else Color3.fromRGB(83, 55, 21)
	revealLabel.Visible = true
	revealCloseButton.Visible = true
	crackingTitle.Text = "You found a Beeboh!"
	crackingHint.Text = "Added to your collection"
	spawnOverlaySparkles(34)
end

local function closeCrackingOverlay()
	crackingOverlay.Visible = false
	crackingBusy = false
	crackingStage = 0
	crackingButterId = nil
	lastClickPosition = nil
	revealLabel.Visible = false
	revealCloseButton.Visible = false
	clearCrackMarks()
	clearCrackingViewport()
end

local function beginCrackingOverlay()
	if not selectedButterId then
		message.Text = "Pick a butter stick from your inventory first."
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
		return
	end

	if state and (state.Butter[selectedButterId] or 0) <= 0 then
		message.Text = "You need to own that butter before you can crack it."
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
		previewPanel.Visible = false
		clearPreview()
		refresh()
		return
	end

	if state and #state.Beebohs >= (state.MaxBeebohs or 20) then
		message.Text = "Your Beeboh inventory is full. Delete a Beeboh before cracking more butter."
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
		beebohPanel.Visible = true
		refresh()
		return
	end

	crackingButterId = selectedButterId
	crackingStage = 0
	crackingBusy = false
	revealLabel.Visible = false
	revealCloseButton.Visible = false
	crackingTitle.Text = `Crack {state.ButterConfig[selectedButterId].Name}`
	crackingHint.Text = "Click the butter 3 times"
	lastClickPosition = nil
	clearCrackMarks()
	loadCrackingButterModel(selectedButterId)
	crackingOverlay.Visible = true
end

local function hitCrackingButter()
	if crackingBusy or not crackingOverlay.Visible or not crackingButterId then
		return
	end

	crackingBusy = true
	crackingStage += 1
	addClickCrack(lastClickPosition or UserInputService:GetMouseLocation(), crackingStage)
	spawnOverlaySparkles(5 + crackingStage * 2)

	if crackingModel then
		local offset = CRACKING_BUTTER_CFRAME * CFrame.Angles(0, 0, math.rad(math.random(-5, 5))) * CFrame.new(math.random(-12, 12) / 100, math.random(-7, 7) / 100, 0)
		crackingModel:PivotTo(offset)
		task.delay(0.08, function()
			if crackingModel then
				crackingModel:PivotTo(CRACKING_BUTTER_CFRAME)
			end
		end)
	end

	if crackingStage < 3 then
		crackingHint.Text = `{3 - crackingStage} hits left`
		task.delay(0.2, function()
			crackingBusy = false
		end)
		return
	end

	crackingHint.Text = "Cracking..."
	task.delay(0.25, function()
		local response = CrackButter:InvokeServer(crackingButterId)

		if not response or not response.Ok then
			applyResponse(response)
			closeCrackingOverlay()
			return
		end

		if response.State then
			state = response.State
		end

		if response.Message then
			message.Text = response.Message
		end

		createBeebohReveal(response.Prize)
		refresh()

		task.delay(2.6, function()
			closeCrackingOverlay()
		end)
	end)
end

showButterPreview = function(butterId)
	local butter = state.ButterConfig[butterId]
	if not butter then
		return
	end

	butter.Id = butterId
	selectedButterId = butterId
	previewPanel.Visible = true
	previewTitle.Text = butter.Name
	previewInfo.Text = `Owned: {state.Butter[butterId] or 0}  |  Cost: {butter.Cost} coins`
	previewCrackButton.Text = `Crack {butter.Name}`
	createButterPreviewModel(butter)
	refresh()
end

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
		if not state then
			return
		end

		selectedShopButterId = butterId
		message.Text = `Selected {state.ButterConfig[butterId].Name} in the shop.`
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
		refresh()
	end)

	shopButterButtons[butterId] = button
end

local function clearButterHotbar()
	for _, button in ipairs(butterHotbarButtons) do
		button:Destroy()
	end

	table.clear(butterHotbarButtons)
end

local function makeButterHotbarButton(butterId)
	local butter = state.ButterConfig[butterId]
	if not butter then
		return
	end

	local owned = state.Butter[butterId] or 0
	if owned <= 0 then
		return
	end

	local button = Instance.new("TextButton")
	button.AutoButtonColor = true
	button.BackgroundColor3 = if butterId == selectedButterId then Color3.fromRGB(255, 216, 78) else Color3.fromRGB(255, 248, 214)
	button.BorderSizePixel = 0
	button.LayoutOrder = butter.Order
	button.Size = UDim2.fromOffset(72, 72)
	button.Text = ""
	button.Parent = butterHotbar

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 8)
	buttonCorner.Parent = button

	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Color = Color3.fromRGB(116, 86, 36)
	buttonStroke.Thickness = 2
	buttonStroke.Parent = button

	local icon = Instance.new("ViewportFrame")
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Position = UDim2.fromOffset(7, 4)
	icon.Size = UDim2.fromOffset(58, 46)
	icon.Parent = button

	local iconCamera = Instance.new("Camera")
	iconCamera.Parent = icon
	icon.CurrentCamera = iconCamera

	local iconModel = createButterViewportModel(butterId, icon)
	if iconModel then
		iconModel:PivotTo(CFrame.Angles(0, math.rad(180), 0))
		frameModel(iconModel, iconCamera, 1.45, 40)
	end

	local count = Instance.new("TextLabel")
	count.BackgroundTransparency = 1
	count.Font = Enum.Font.GothamBlack
	count.Text = `x{owned}`
	count.TextColor3 = Color3.fromRGB(83, 55, 21)
	count.TextSize = 13
	count.Position = UDim2.new(0, 0, 1, -20)
	count.Size = UDim2.new(1, 0, 0, 18)
	count.Parent = button

	button.Activated:Connect(function()
		message.Text = `Equipped {butter.Name}.`
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
		showButterPreview(butterId)
	end)

	table.insert(butterHotbarButtons, button)
end

local function clearBeebohRows()
	for _, row in ipairs(beebohRows) do
		row:Destroy()
	end

	table.clear(beebohRows)
end

local function clearBeebohDetail()
	for _, child in ipairs(beebohDetailViewport:GetChildren()) do
		if child ~= beebohDetailCamera then
			child:Destroy()
		end
	end

	beebohDetailPanel.Visible = false
end

local function createBeebohViewportModel(beebohId, beeboh, targetViewport)
	local rarity = state.RarityConfig[beeboh.Rarity]
	local beebohColor = beeboh.Color or (rarity and rarity.Color) or Color3.fromRGB(255, 255, 255)
	local sourceModel = findBeebohModel({
		Id = beebohId,
		Name = beeboh.Name,
	})

	if sourceModel then
		return preparePreviewModel(sourceModel, targetViewport), beebohColor
	end

	local ball = Instance.new("Part")
	ball.Name = "BeebohIcon"
	ball.Anchored = true
	ball.Shape = Enum.PartType.Ball
	ball.Material = Enum.Material.SmoothPlastic
	ball.Color = beebohColor
	ball.Size = Vector3.new(2.4, 2.4, 2.4)

	local model = Instance.new("Model")
	model.Name = "BeebohIconModel"
	model.Parent = targetViewport
	ball.Parent = model
	model.PrimaryPart = ball

	return model, beebohColor
end

local function getBeebohItemId(item)
	if typeof(item) == "table" then
		return item.Id
	end

	return item
end

local function getBeebohItemName(item, beeboh)
	if typeof(item) == "table" and typeof(item.Name) == "string" and item.Name ~= "" then
		return item.Name
	end

	return if beeboh then beeboh.Name else "Beeboh"
end

local function isBeebohEquipped(index)
	if not state or typeof(state.EquippedBeebohs) ~= "table" then
		return false
	end

	for _, equippedIndex in ipairs(state.EquippedBeebohs) do
		if equippedIndex == index then
			return true
		end
	end

	return false
end

local function showBeebohDetail(beebohItem, index)
	local beebohId = getBeebohItemId(beebohItem)
	local beeboh = state.BeebohConfig[beebohId]
	if not beeboh then
		clearBeebohDetail()
		return
	end

	for _, child in ipairs(beebohDetailViewport:GetChildren()) do
		if child ~= beebohDetailCamera then
			child:Destroy()
		end
	end

	local rarity = state.RarityConfig[beeboh.Rarity]
	local detailModel, beebohColor = createBeebohViewportModel(beebohId, beeboh, beebohDetailViewport)

	if detailModel then
		frameModel(detailModel, beebohDetailCamera, 1.65, 36)
	end

	selectedBeebohIndex = index
	local displayName = getBeebohItemName(beebohItem, beeboh)
	beebohDetailName.Text = displayName
	beebohDetailName.TextColor3 = beebohColor
	beebohRenameBox.Visible = false
	beebohRenameBox.Text = displayName
	beebohRenameButton.Text = "Rename"
	beebohDetailInfo.Text = `Type\n{beeboh.Name}\n{beeboh.Rarity} / +{beeboh.CoinsPerSecond}/sec`
	beebohDetailInfo.TextColor3 = if rarity then rarity.Color else Color3.fromRGB(255, 255, 255)
	beebohEquipButton.Text = if isBeebohEquipped(index) then "Unequip" else "Equip"
	beebohEquipButton.BackgroundColor3 = if isBeebohEquipped(index) then Color3.fromRGB(255, 173, 51) else Color3.fromRGB(76, 166, 255)
	beebohDetailPanel.Visible = true
end

local function makeBeebohGridItem(beebohItem, index)
	local beebohId = getBeebohItemId(beebohItem)
	local beeboh = state.BeebohConfig[beebohId]
	if not beeboh then
		return
	end

	local rarity = state.RarityConfig[beeboh.Rarity]
	local beebohColor = beeboh.Color or (rarity and rarity.Color) or Color3.fromRGB(255, 255, 255)

	local row = Instance.new("TextButton")
	row.AutoButtonColor = true
	row.BackgroundTransparency = 1
	row.BorderSizePixel = 0
	row.LayoutOrder = index
	row.Text = ""
	row.Parent = beebohList

	local icon = Instance.new("ViewportFrame")
	icon.BackgroundTransparency = 1
	icon.BorderSizePixel = 0
	icon.Position = UDim2.fromOffset(5, 0)
	icon.Size = UDim2.fromOffset(60, 60)
	icon.Parent = row

	local iconCamera = Instance.new("Camera")
	iconCamera.Parent = icon
	icon.CurrentCamera = iconCamera

	local iconModel = createBeebohViewportModel(beebohId, beeboh, icon)

	if iconModel then
		frameModel(iconModel, iconCamera, 1.65, 38)
	end

	local name = Instance.new("TextLabel")
	name.BackgroundTransparency = 1
	name.Font = Enum.Font.GothamBlack
	name.Text = getBeebohItemName(beebohItem, beeboh)
	name.TextColor3 = beebohColor
	name.TextSize = 12
	name.TextWrapped = true
	name.Position = UDim2.fromOffset(0, 62)
	name.Size = UDim2.new(1, 0, 0, 34)
	name.Parent = row

	local function selectThisBeeboh()
		showBeebohDetail(beebohItem, index)
	end

	local hitbox = Instance.new("TextButton")
	hitbox.BackgroundTransparency = 1
	hitbox.BorderSizePixel = 0
	hitbox.Text = ""
	hitbox.Size = UDim2.fromScale(1, 1)
	hitbox.Parent = row

	row.Activated:Connect(function()
		selectThisBeeboh()
	end)

	hitbox.Activated:Connect(function()
		selectThisBeeboh()
	end)

	table.insert(beebohRows, row)
end

local function refreshBeebohInventory()
	if not state then
		return
	end

	clearBeebohRows()

	local maxBeebohs = state.MaxBeebohs or 20
	local maxEquipped = state.MaxEquippedBeebohs or 3
	local equippedCount = if typeof(state.EquippedBeebohs) == "table" then #state.EquippedBeebohs else 0
	beebohCapacity.Text = `{#state.Beebohs}/{maxBeebohs} Beebohs  |  Equipped {equippedCount}/{maxEquipped}`
	beebohInventoryButton.Text = "🎒"

	for index, beebohItem in ipairs(state.Beebohs) do
		makeBeebohGridItem(beebohItem, index)
	end

	if selectedBeebohIndex and state.Beebohs[selectedBeebohIndex] and not beebohRenameBox.Visible then
		showBeebohDetail(state.Beebohs[selectedBeebohIndex], selectedBeebohIndex)
	elseif not selectedBeebohIndex or not state.Beebohs[selectedBeebohIndex] then
		selectedBeebohIndex = nil
		clearBeebohDetail()
	end

	if #state.Beebohs == 0 then
		local empty = Instance.new("TextLabel")
		empty.BackgroundTransparency = 1
		empty.Font = Enum.Font.GothamBold
		empty.Text = "No Beebohs yet."
		empty.TextColor3 = Color3.fromRGB(255, 255, 255)
		empty.TextSize = 22
		empty.TextXAlignment = Enum.TextXAlignment.Left
		empty.Size = UDim2.new(1, -8, 0, 60)
		empty.Parent = beebohList
		table.insert(beebohRows, empty)
	end
end

refresh = function()
	if not state then
		return
	end

	stats.Text = `Coins: {state.Coins}\nEarning: {state.CoinRate} coins/sec`

	if not selectedShopButterId or not state.ButterConfig[selectedShopButterId] then
		selectedShopButterId = "Plain"
	end

	clearButterHotbar()

	for _, butterId in ipairs(getSortedButterIds()) do
		if not shopButterButtons[butterId] then
			makeButterButton(butterId)
		end

		local butter = state.ButterConfig[butterId]
		local owned = state.Butter[butterId] or 0
		local button = shopButterButtons[butterId]

		button.LayoutOrder = butter.Order
		button.BackgroundColor3 = if butterId == selectedShopButterId then Color3.fromRGB(255, 216, 78) else Color3.fromRGB(255, 238, 158)
		button.Text = `{butter.Name}  |  Own: {owned}  |  Buy: {butter.Cost}`

		makeButterHotbarButton(butterId)
	end

	if selectedShopButterId and state.ButterConfig[selectedShopButterId] then
		local selectedButter = state.ButterConfig[selectedShopButterId]
		buyButton.Text = `Buy {selectedButter.Name} ({selectedButter.Cost} coins)`
	else
		buyButton.Text = "Select Butter To Buy"
	end

	if selectedButterId and state.ButterConfig[selectedButterId] then
		local selectedButter = state.ButterConfig[selectedButterId]
		local owned = state.Butter[selectedButterId] or 0

		if previewPanel.Visible and owned > 0 then
			previewTitle.Text = selectedButter.Name
			previewInfo.Text = `Owned: {owned}  |  Cost: {selectedButter.Cost} coins`
			previewCrackButton.Text = `Crack {selectedButter.Name}`
		elseif owned <= 0 then
			previewPanel.Visible = false
			clearPreview()
		end
	end

	local countsByRarity = {}
	for _, beebohItem in ipairs(state.Beebohs) do
		local beebohId = getBeebohItemId(beebohItem)
		local beeboh = state.BeebohConfig[beebohId]
		if beeboh then
			countsByRarity[beeboh.Rarity] = (countsByRarity[beeboh.Rarity] or 0) + 1
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

	collection.Text = `Beebohs owned: {#state.Beebohs}\n{table.concat(collectionText, "  |  ")}`
	refreshBeebohInventory()
end

applyResponse = function(response)
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

local function crackSelectedButter()
	beginCrackingOverlay()
end

local function saveSelectedBeebohName()
	if not selectedBeebohIndex then
		return
	end

	local newName = beebohRenameBox.Text
	beebohRenameBox.Visible = false
	beebohRenameButton.Text = "Rename"
	applyResponse(RenameBeeboh:InvokeServer(selectedBeebohIndex, newName))
end

PrizeRevealed.OnClientEvent:Connect(applyResponse)

previewCrackButton.Activated:Connect(function()
	crackSelectedButter()
end)

revealCloseButton.Activated:Connect(function()
	closeCrackingOverlay()
end)

previewCloseButton.Activated:Connect(function()
	previewPanel.Visible = false
	clearPreview()
end)

shopButton.Activated:Connect(function()
	shopPanel.Visible = not shopPanel.Visible
	refresh()
end)

shopCloseButton.Activated:Connect(function()
	shopPanel.Visible = false
end)

beebohInventoryButton.Activated:Connect(function()
	beebohPanel.Visible = not beebohPanel.Visible
	refreshBeebohInventory()
end)

beebohCloseButton.Activated:Connect(function()
	beebohPanel.Visible = false
end)

beebohRenameButton.Activated:Connect(function()
	if not selectedBeebohIndex then
		return
	end

	if beebohRenameBox.Visible then
		saveSelectedBeebohName()
		return
	end

	beebohRenameBox.Visible = true
	beebohRenameButton.Text = "Save"
	beebohRenameBox:CaptureFocus()
end)

beebohRenameBox.FocusLost:Connect(function(enterPressed)
	if enterPressed and beebohRenameBox.Visible then
		saveSelectedBeebohName()
	end
end)

beebohEquipButton.Activated:Connect(function()
	if not selectedBeebohIndex then
		return
	end

	applyResponse(ToggleEquipBeeboh:InvokeServer(selectedBeebohIndex))
end)

beebohDeleteButton.Activated:Connect(function()
	if not selectedBeebohIndex then
		return
	end

	local deleteIndex = selectedBeebohIndex
	selectedBeebohIndex = nil
	clearBeebohDetail()
	applyResponse(DeleteBeeboh:InvokeServer(deleteIndex))
end)

overlayClickButton.InputBegan:Connect(function(input)
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end

	lastClickPosition = Vector2.new(input.Position.X, input.Position.Y)
	hitCrackingButter()
end)

buyButton.Activated:Connect(function()
	if not selectedShopButterId then
		message.Text = "Pick a butter from the shop first."
		message.TextColor3 = Color3.fromRGB(83, 55, 21)
		return
	end

	applyResponse(BuyButter:InvokeServer(selectedShopButterId))
end)

applyResponse(GetState:InvokeServer())

task.spawn(function()
	while true do
		task.wait(1)
		applyResponse(GetState:InvokeServer())
	end
end)

RunService.RenderStepped:Connect(function(deltaTime)
	previewRotation += deltaTime * 0.9

	if previewModel and previewModel.PrimaryPart then
		previewModel:PivotTo(CFrame.Angles(0, previewRotation, 0))
	end

	if crackingOverlay.Visible then
		return
	end
end)
