local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local module = {}

-- Debug
warn("[BuyAndEquipModelServer] Loading as " .. tostring(script.ClassName))

-- Events
local BuyAndEquipModelEvent = ReplicatedStorage:WaitForChild("BuyAndEquipModelEvent")
local NotifyEvent = ReplicatedStorage:WaitForChild("NotifyEvent")
local EquipToyEvent = ReplicatedStorage:WaitForChild("EquipToyEvent")

-- Config
local MODEL_COST = 100
local TOY_NAME = "HoverToy"

-- Dependencies
local CoinSaver
local success, result = pcall(function()
	CoinSaver = require(ServerScriptService.CoinSaver)
end)
if not success then
	warn("[BuyAndEquipModelServer] Failed to load CoinSaver: " .. tostring(result))
	CoinSaver = { loadData = function() return {Coins = 100, Toys = {}} end, saveData = function() end }
end

-- Track equipped toys
local equippedToys = {} -- [player] = toyInstance

function module.createHoverEffect(toy, character)
	if not toy.PrimaryPart or not character:FindFirstChild("HumanoidRootPart") then
		warn("[BuyAndEquipModelServer] Invalid toy or character for hover effect")
		return
	end

	for _, child in pairs(toy:GetChildren()) do
		if child:IsA("BodyPosition") or child:IsA("AlignPosition") then
			child:Destroy()
		end
	end

	local alignPos = Instance.new("AlignPosition")
	alignPos.MaxForce = 10000
	alignPos.Responsiveness = 20
	alignPos.Position = character.HumanoidRootPart.Position + Vector3.new(0, 5, 0)
	alignPos.Parent = toy

	local attachment0 = Instance.new("Attachment")
	attachment0.Parent = toy.PrimaryPart

	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = character.HumanoidRootPart

	alignPos.Attachment0 = attachment0
	alignPos.Attachment1 = attachment1

	local startTime = os.clock()
	local connection
	connection = RunService.Heartbeat:Connect(function()
		if not toy.Parent or not character.Parent or not character:FindFirstChild("HumanoidRootPart") then
			connection:Disconnect()
			return
		end
		local t = os.clock() - startTime
		local hoverOffset = math.sin(t * 0.5) * 0.5
		local spinAngle = t * 36
		local targetPos = character.HumanoidRootPart.Position + Vector3.new(0, 5 + hoverOffset, 0)
		alignPos.Position = targetPos
		toy:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, math.rad(spinAngle), 0))
	end)

	return connection
end

function module.equipToy(player, character, toyName)
	if not player or not character then
		warn("[BuyAndEquipModelServer] Invalid player or character for equipToy")
		return
	end

	if equippedToys[player] then
		equippedToys[player]:Destroy()
		equippedToys[player] = nil
	end

	if toyName == "None" then
		return -- Unequip
	end

	local toyModel = ReplicatedStorage:FindFirstChild(toyName)
	if not toyModel then
		warn("[BuyAndEquipModelServer] " .. toyName .. " not found in ReplicatedStorage")
		return
	end
	if not toyModel.PrimaryPart then
		warn("[BuyAndEquipModelServer] " .. toyName .. " missing PrimaryPart")
		return
	end

	local toy = toyModel:Clone()
	toy.Parent = character
	toy:SetPrimaryPartCFrame(character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
	equippedToys[player] = toy

	local connection = module.createHoverEffect(toy, character)
	if not connection then
		warn("[BuyAndEquipModelServer] Failed to create hover effect for " .. player.Name)
	end
end

function module.handlePurchase(player)
	if not player then
		warn("[BuyAndEquipModelServer] No player provided")
		return
	end
	local character = player.Character
	if not character or not character:FindFirstChild("HumanoidRootPart") then
		warn("[BuyAndEquipModelServer] No valid character for " .. player.Name)
		return
	end

	local coins = player:FindFirstChild("Coins")
	local data = CoinSaver.loadData(player)
	local toys = data.Toys or {}

	if toys[TOY_NAME] then
		module.equipToy(player, character, TOY_NAME)
		NotifyEvent:FireClient(player, {type = "Success", message = "Equipped " .. TOY_NAME .. "!"})
		warn("[BuyAndEquipModelServer] Equipped " .. TOY_NAME .. " for " .. player.Name)
		return
	end

	if not coins then
		NotifyEvent:FireClient(player, {type = "Error", message = "Coins not found!"})
		warn("[BuyAndEquipModelServer] Coins not found for " .. player.Name)
		return
	end

	if coins.Value < MODEL_COST then
		NotifyEvent:FireClient(player, {type = "Error", message = "Not enough coins! Need " .. MODEL_COST .. "."})
		warn("[BuyAndEquipModelServer] Not enough coins for " .. player.Name .. ": " .. coins.Value)
		return
	end

	coins.Value = coins.Value - MODEL_COST
	toys[TOY_NAME] = true
	data.Coins = coins.Value
	data.Toys = toys
	local toysFolder = player:FindFirstChild("Toys") or Instance.new("Folder")
	toysFolder.Name = "Toys"
	toysFolder.Parent = player
	local toyValue = Instance.new("BoolValue")
	toyValue.Name = TOY_NAME
	toyValue.Value = true
	toyValue.Parent = toysFolder
	CoinSaver.saveData(player, data)

	module.equipToy(player, character, TOY_NAME)
	NotifyEvent:FireClient(player, {type = "Success", message = "Purchased and equipped " .. TOY_NAME .. " for " .. MODEL_COST .. " coins!"})
	warn("[BuyAndEquipModelServer] Purchased " .. TOY_NAME .. " for " .. player.Name .. ", new coins: " .. coins.Value)
end

warn("[BuyAndEquipModelServer] Initialized")

return module