local DataStoreService = game:GetService("DataStoreService")
local dataStore = DataStoreService:GetDataStore("PlayerDataV1")
local oldCoinStore = DataStoreService:GetDataStore("PlayerCoinsV1") -- For migration

local CoinSaver = {}

function CoinSaver.saveData(player)
	local success, err
	for i = 1, 3 do
		success, err = pcall(function()
			local data = {
				Coins = player:WaitForChild("Coins").Value,
				VIP = player:WaitForChild("VIP").Value
			}
			dataStore:SetAsync(player.UserId, data)
		end)
		if success then break end
		warn("Failed to save data for " .. player.Name .. " (Attempt " .. i .. "): " .. tostring(err))
		wait(2)
	end
	if not success then
		warn("Final save failure for " .. player.Name .. ": " .. tostring(err))
	end
end

function CoinSaver.loadData(player)
	local success, data
	for i = 1, 3 do
		success, data = pcall(function()
			return dataStore:GetAsync(player.UserId)
		end)
		if success then break end
		warn("Failed to load data for " .. player.Name .. " (Attempt " .. i .. "): " .. tostring(data))
		wait(2)
	end
	if success and data ~= nil then
		return data
	else
		-- Check old store for migration
		local oldSuccess, oldData
		for i = 1, 3 do
			oldSuccess, oldData = pcall(function()
				return oldCoinStore:GetAsync(player.UserId)
			end)
			if oldSuccess then break end
			wait(2)
		end
		if oldSuccess and oldData ~= nil then
			local migratedData = {Coins = oldData, VIP = false}
			CoinSaver.saveData(player) -- Save to new store immediately
			return migratedData
		end
		return {Coins = 100, VIP = false} -- Default for new players
	end
end

return CoinSaver