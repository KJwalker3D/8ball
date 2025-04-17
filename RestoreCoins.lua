local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")
local CoinSaver = require(ServerScriptService.CoinSaver)

local YOUR_USER_ID = 8044913826 -- Replace with your Roblox UserId

Players.PlayerAdded:Connect(function(player)
	if player.UserId == YOUR_USER_ID then
		local data = CoinSaver.loadData(player)
		if not data.Toys.HoverToy then
			data.Coins = 2000
			data.Toys.HoverToy = true
			local coins = player:WaitForChild("Coins")
			coins.Value = 2000
			local toysFolder = player:FindFirstChild("Toys") or Instance.new("Folder")
			toysFolder.Name = "Toys"
			toysFolder.Parent = player
			local toyValue = Instance.new("BoolValue")
			toyValue.Name = "HoverToy"
			toyValue.Value = true
			toyValue.Parent = toysFolder
			CoinSaver.saveData(player, data)
			warn("[RestoreCoins] Restored 2000 coins and HoverToy for " .. player.Name)
		end
	end
end)