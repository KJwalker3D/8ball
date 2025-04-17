local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

-- Create events
local BuyAndEquipModelEvent = Instance.new("RemoteEvent")
BuyAndEquipModelEvent.Name = "BuyAndEquipModelEvent"
BuyAndEquipModelEvent.Parent = ReplicatedStorage

local NotifyEvent = Instance.new("RemoteEvent")
NotifyEvent.Name = "NotifyEvent"
NotifyEvent.Parent = ReplicatedStorage

local EquipToyEvent = Instance.new("RemoteEvent")
EquipToyEvent.Name = "EquipToyEvent"
EquipToyEvent.Parent = ReplicatedStorage

-- Load module
local BuyAndEquipModelServer
local success, result = pcall(function()
	return require(ServerScriptService.BuyAndEquipModelServer)
end)
if not success then
	warn("[SetupEvents] Failed to load BuyAndEquipModelServer: " .. tostring(result))
	return
end
BuyAndEquipModelServer = result

local CoinSaver = require(ServerScriptService.CoinSaver)

-- Handle equip/unequip from inventory
EquipToyEvent.OnServerEvent:Connect(function(player, toyName)
	if not player then
		warn("[SetupEvents] No player for equip request")
		return
	end
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[SetupEvents] No valid character for " .. player.Name)
		return
	end
	local data = CoinSaver.loadData(player)
	local toys = data.Toys or {}

	if toyName ~= "None" and not toys[toyName] then
		warn("[SetupEvents] " .. player.Name .. " does not own " .. toyName)
		NotifyEvent:FireClient(player, {type = "Error", message = "You don't own " .. toyName .. "!"})
		return
	end

	BuyAndEquipModelServer.equipToy(player, character, toyName)
	NotifyEvent:FireClient(player, {type = "Success", message = toyName == "None" and "Unequipped toy!" or "Equipped " .. toyName .. "!"})
end)

-- Handle purchase
BuyAndEquipModelEvent.OnServerEvent:Connect(BuyAndEquipModelServer.handlePurchase)

-- Handle character reset/death
Players.PlayerAdded:Connect(function(player)
	local data = CoinSaver.loadData(player)
	local toysFolder = player:FindFirstChild("Toys") or Instance.new("Folder")
	toysFolder.Name = "Toys"
	toysFolder.Parent = player
	for toyName, owned in pairs(data.Toys or {}) do
		if owned and not toysFolder:FindFirstChild(toyName) then
			local toyValue = Instance.new("BoolValue")
			toyValue.Name = toyName
			toyValue.Value = true
			toyValue.Parent = toysFolder
		end
	end

	player.CharacterAdded:Connect(function(character)
		task.wait() -- Ensure character is fully loaded
		if not character:FindFirstChild("HumanoidRootPart") then
			warn("[SetupEvents] No HumanoidRootPart for " .. player.Name)
			return
		end
		if data.Toys and data.Toys.HoverToy then
			BuyAndEquipModelServer.equipToy(player, character, "HoverToy")
			warn("[SetupEvents] Auto-equipped HoverToy for " .. player.Name)
		end
	end)
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	CoinSaver.saveData(player)
end)

warn("[SetupEvents] Initialized")