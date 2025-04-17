local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local success, ToyPurchaseHandler = pcall(function()
	return require(ServerScriptService.BuyAndEquipModelServer)
end)
if not success then
	warn("[HoverToyScript] Failed to load BuyAndEquipModelServer: " .. tostring(ToyPurchaseHandler))
	return
end

local CoinSaver = require(ServerScriptService.CoinSaver)

local proximityPrompt = script.Parent:FindFirstChild("ProximityPrompt")
if not proximityPrompt then
	warn("[ToyPrompt] ProximityPrompt not found")
	return
end

proximityPrompt.HoldDuration = 0.5
proximityPrompt.KeyboardKeyCode = Enum.KeyCode.E

local function updatePromptText(player)
	local data = CoinSaver.loadData(player)
	proximityPrompt.ActionText = data.Toys and data.Toys.HoverToy and "Equip Hover Toy" or "Buy Hover Toy (100 Coins)"
end

proximityPrompt.Triggered:Connect(function(player)
	if not player then
		warn("[ToyPrompt] No player for prompt trigger")
		return
	end
	warn("[ToyPrompt] Purchase triggered for " .. player.Name)
	ToyPurchaseHandler.handlePurchase(player)
	updatePromptText(player)
end)

Players.PlayerAdded:Connect(function(player)
	updatePromptText(player)
	player.AncestryChanged:Connect(function()
		updatePromptText(player)
	end)
end)

warn("[ToyPrompt] Initialized on " .. script.Parent:GetFullName())