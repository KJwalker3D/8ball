--=== ToyInventory (Revised, Key Toggle Sync) ===--

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local EquipToyEvent = ReplicatedStorage:WaitForChild("EquipToyEvent")

local equippedToy = nil

local function getEquippedToyFromCharacter()
	if not player.Character then return nil end
	return player.Character:GetAttribute("EquippedToy")
end

UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.KeyCode == Enum.KeyCode.One then
		local toysFolder = player:FindFirstChild("Toys")
		if toysFolder and toysFolder:FindFirstChild("HoverToy") then
			local current = getEquippedToyFromCharacter()
			local newEquip = current == "HoverToy" and "None" or "HoverToy"
			EquipToyEvent:FireServer(newEquip)
			equippedToy = newEquip == "None" and nil or "HoverToy"
		end
	end
end)

player.CharacterAdded:Connect(function(char)
	char:GetAttributeChangedSignal("EquippedToy"):Connect(function()
		equippedToy = getEquippedToyFromCharacter()
	end)
	-- Initial sync
	equippedToy = getEquippedToyFromCharacter()
end)

print("[ToyInventory] Revised sync active")
