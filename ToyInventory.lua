local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local EquipToyEvent = ReplicatedStorage:WaitForChild("EquipToyEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ToyInventoryGui"
screenGui.ResetOnSpawn = false
screenGui.Enabled = false -- Start invisible
screenGui.Parent = playerGui

local toolbarFrame = Instance.new("Frame")
toolbarFrame.Size = UDim2.new(0, 70, 0, 50) -- Default for 1 toy
toolbarFrame.Position = UDim2.new(0.5, -35, 1, -60) -- Centered
toolbarFrame.BackgroundTransparency = 0.5
toolbarFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
toolbarFrame.BorderSizePixel = 0
toolbarFrame.Parent = screenGui

local uIGridLayout = Instance.new("UIGridLayout")
uIGridLayout.CellSize = UDim2.new(0, 50, 0, 50)
uIGridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
uIGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
uIGridLayout.Parent = toolbarFrame

local toyData = {
	HoverToy = {
		Icon = "rbxassetid://0", -- Replace with actual icon
		Key = Enum.KeyCode.One
	}
}

local equippedToy = nil

local function createToyButton(toyName)
	local button = Instance.new("ImageButton")
	button.Size = UDim2.new(0, 50, 0, 50)
	button.BackgroundTransparency = 1
	button.Image = toyData[toyName].Icon
	button.Parent = toolbarFrame

	local keyLabel = Instance.new("TextLabel")
	keyLabel.Size = UDim2.new(0, 20, 0, 20)
	keyLabel.Position = UDim2.new(0, 5, 0, 5)
	keyLabel.BackgroundTransparency = 1
	keyLabel.Text = tostring(toyData[toyName].Key):match("KeyCode%.(%w+)") or "?"
	keyLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	keyLabel.TextScaled = true
	keyLabel.Parent = button

	button.MouseButton1Click:Connect(function()
		if not ReplicatedStorage:FindFirstChild("EquipToyEvent") then
			warn("[ToyInventory] EquipToyEvent not found")
			return
		end
		local newEquipped = equippedToy == toyName and "None" or toyName
		EquipToyEvent:FireServer(newEquipped)
		equippedToy = newEquipped == "None" and nil or toyName
		updateButtonStates()
		print("[ToyInventory] Button clicked: " .. tostring(toyName) .. ", Equipped: " .. tostring(equippedToy))
	end)

	return button
end

local function updateButtonStates()
	for _, button in pairs(toolbarFrame:GetChildren()) do
		if button:IsA("ImageButton") then
			local toyName = button.Name
			button.ImageTransparency = equippedToy == toyName and 0 or 0.5
		end
	end
end

local function updateToolbar()
	for _, child in pairs(toolbarFrame:GetChildren()) do
		if child:IsA("ImageButton") then
			child:Destroy()
		end
	end

	local toysFolder = player:FindFirstChild("Toys")
	if not toysFolder then
		print("[ToyInventory] No Toys folder found")
		screenGui.Enabled = false
		toolbarFrame.Size = UDim2.new(0, 70, 0, 50)
		toolbarFrame.Position = UDim2.new(0.5, -35, 1, -60)
		return
	end

	local toyCount = 0
	for toyName, _ in pairs(toyData) do
		if toysFolder:FindFirstChild(toyName) then
			local button = createToyButton(toyName)
			button.Name = toyName
			print("[ToyInventory] Created button for " .. tostring(toyName))
			toyCount = toyCount + 1
		end
	end

	-- Dynamic width: (cellSize + padding) * toyCount + padding
	local cellSize = 50
	local padding = 10
	local width = toyCount * (cellSize + padding) + padding
	toolbarFrame.Size = UDim2.new(0, width, 0, 50)
	toolbarFrame.Position = UDim2.new(0.5, -width / 2, 1, -60)
	screenGui.Enabled = toyCount > 0
	updateButtonStates()
end

local function waitForToys()
	local toysFolder = player:FindFirstChild("Toys")
	if toysFolder then
		toysFolder.ChildAdded:Connect(updateToolbar)
		toysFolder.ChildRemoved:Connect(updateToolbar)
		updateToolbar()
		print("[ToyInventory] Toys folder found, toolbar updated")
		return
	end
	local connection
	connection = player.ChildAdded:Connect(function(child)
		if child.Name == "Toys" then
			connection:Disconnect()
			child.ChildAdded:Connect(updateToolbar)
			child.ChildRemoved:Connect(updateToolbar)
			updateToolbar()
			print("[ToyInventory] Toys folder added, toolbar updated")
		end
	end)
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	for toyName, data in pairs(toyData) do
		if input.KeyCode == data.Key then
			local toysFolder = player:FindFirstChild("Toys")
			if toysFolder and toysFolder:FindFirstChild(toyName) then
				if not ReplicatedStorage:FindFirstChild("EquipToyEvent") then
					warn("[ToyInventory] EquipToyEvent not found")
					return
				end
				-- Toggle based on server state
				local newEquipped = equippedToy == toyName and "None" or toyName
				EquipToyEvent:FireServer(newEquipped)
				equippedToy = newEquipped == "None" and nil or toyName
				updateButtonStates()
				print("[ToyInventory] Key pressed: " .. tostring(toyName) .. ", Equipped: " .. tostring(equippedToy))
			else
				print("[ToyInventory] Key ignored: No " .. tostring(toyName) .. " in Toys")
			end
		end
	end
end)

-- Sync equipped state on character load
player.CharacterAdded:Connect(function(character)
	local toysFolder = player:FindFirstChild("Toys")
	if toysFolder and toysFolder:FindFirstChild("HoverToy") then
		-- Check if toy is equipped (server auto-equips on join)
		local hasToyEquipped = character:FindFirstChild("HoverToy") ~= nil
		equippedToy = hasToyEquipped and "HoverToy" or nil
		updateButtonStates()
		print("[ToyInventory] Character reset, equipped toy: " .. tostring(equippedToy))
	else
		equippedToy = nil
		updateButtonStates()
		print("[ToyInventory] Character reset, no toys owned")
	end
end)

waitForToys()
print("[ToyInventory] Initialized")