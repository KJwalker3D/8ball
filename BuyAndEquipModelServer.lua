--=== BuyAndEquipModelServer (Revised with connection fix) ===--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ServerScriptService = game:GetService("ServerScriptService")

local module = {}

-- Events
local BuyAndEquipModelEvent = ReplicatedStorage:WaitForChild("BuyAndEquipModelEvent")
local NotifyEvent = ReplicatedStorage:WaitForChild("NotifyEvent")
local EquipToyEvent = ReplicatedStorage:WaitForChild("EquipToyEvent")

-- Config
local MODEL_COST = 100
local TOY_NAME = "HoverToy"

-- Dependencies
local CoinSaver = require(ServerScriptService.CoinSaver)

-- Track equipped toys and hover connections
local equippedToys = {} -- [player] = toyInstance
local hoverConnections = {} -- [player] = RBXScriptConnection

function module.createHoverEffect(toy, character)
	if not toy.PrimaryPart or not character:FindFirstChild("HumanoidRootPart") then return end

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
		if not toy.Parent or not character.Parent then
			connection:Disconnect()
			return
		end
		local t = os.clock() - startTime
		local hoverOffset = math.sin(t * 0.5) * 0.5
		local spinAngle = t * 36
		local targetPos = character.HumanoidRootPart.Position + Vector3.new(2, 5 + hoverOffset, 0)
		alignPos.Position = targetPos
		toy:SetPrimaryPartCFrame(CFrame.new(targetPos) * CFrame.Angles(0, math.rad(spinAngle), 0))
	end)

	return connection
end

function module.equipToy(player, character, toyName)
	if equippedToys[player] then
		if hoverConnections[player] then
			hoverConnections[player]:Disconnect()
			hoverConnections[player] = nil
		end
		equippedToys[player]:Destroy()
		equippedToys[player] = nil
		character:SetAttribute("EquippedToy", "None")
	end

	if toyName == "None" then return end

	local toyModel = ReplicatedStorage:FindFirstChild(toyName)
	if not toyModel or not toyModel.PrimaryPart then return end

	local toy = toyModel:Clone()
	toy.Parent = character
	toy:SetPrimaryPartCFrame(character.HumanoidRootPart.CFrame * CFrame.new(0, 5, 0))
	equippedToys[player] = toy

	local connection = module.createHoverEffect(toy, character)
	if connection then
		hoverConnections[player] = connection
	end

	character:SetAttribute("EquippedToy", toyName)
end

function module.handlePurchase(player)
	local character = player.Character
	if not character then return end

	local coins = player:FindFirstChild("Coins")
	local data = CoinSaver.loadData(player)
	local toys = data.Toys or {}

	if toys[TOY_NAME] then
		module.equipToy(player, character, TOY_NAME)
		NotifyEvent:FireClient(player, {type = "Success", message = "Equipped " .. TOY_NAME .. "!"})
		return
	end

	if not coins or coins.Value < MODEL_COST then
		NotifyEvent:FireClient(player, {type = "Error", message = "Not enough coins!"})
		return
	end

	coins.Value -= MODEL_COST
	toys[TOY_NAME] = true
	data.Coins = coins.Value
	data.Toys = toys
	CoinSaver.saveData(player, data)

	local toysFolder = player:FindFirstChild("Toys") or Instance.new("Folder")
	toysFolder.Name = "Toys"
	toysFolder.Parent = player
	local toyValue = Instance.new("BoolValue")
	toyValue.Name = TOY_NAME
	toyValue.Value = true
	toyValue.Parent = toysFolder

	module.equipToy(player, character, TOY_NAME)
	NotifyEvent:FireClient(player, {type = "Success", message = "Purchased and equipped!"})
end

return module