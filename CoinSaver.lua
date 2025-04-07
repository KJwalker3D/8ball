-- module script in server script service 

local DataStoreService = game:GetService("DataStoreService")
local coinStore = DataStoreService:GetDataStore("PlayerCoinsV1")

local CoinSaver = {}

function CoinSaver.saveCoins(player)
	local success, err
	for i = 1, 3 do -- Retry up to 3 times
		success, err = pcall(function()
			local coins = player:WaitForChild("Coins").Value
			coinStore:SetAsync(player.UserId, coins)
		end)
		if success then break end
		warn("Failed to save coins for " .. player.Name .. " (Attempt " .. i .. "): " .. tostring(err))
		wait(2) -- Wait before retry
	end
	if not success then
		warn("Final save failure for " .. player.Name .. ": " .. tostring(err))
	end
end

return CoinSaver