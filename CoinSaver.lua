local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local dataStore = DataStoreService:GetDataStore("PlayerDataV1")

local YOUR_USER_ID_HERE = 8044913826

local CONFIG = {
	DATASTORE_NAME = "PlayerDataV1",
	MAX_RETRIES = 5,
	RETRY_DELAY = 3,
	DEFAULT_COINS = 100,
	DEFAULT_VIP = false,
	DEFAULT_TOYS = {},
	ERROR_SAVE = "[CoinSaver] Failed to save data for %s (Attempt %d): %s",
	ERROR_LOAD = "[CoinSaver] Failed to load data for %s (Attempt %d): %s"
}

local CoinSaver = {}

-- Debounce saves
local lastSave = {} -- [player.UserId] = tick()

local function safeExecuteWithRetry(func, errorMessage, playerName)
	local success, result
	for i = 1, CONFIG.MAX_RETRIES do
		success, result = pcall(func)
		if success then
			return success, result
		end
		warn(string.format(errorMessage, playerName, i, tostring(result)))
		task.wait(CONFIG.RETRY_DELAY)
	end
	return success, result
end

local function validateData(data)
	return type(data) == "table"
		and type(data.Coins) == "number"
		and type(data.VIP) == "boolean"
		and type(data.Toys) == "table"
end

local function createDefaultData()
	return {
		Coins = CONFIG.DEFAULT_COINS,
		VIP = CONFIG.DEFAULT_VIP,
		Toys = CONFIG.DEFAULT_TOYS
	}
end

function CoinSaver.saveData(player, overrideData)
	local playerName = player.Name
	local userId = player.UserId
	local now = tick()
	if lastSave[userId] and now - lastSave[userId] < 5 then
		warn("[CoinSaver] Save debounced for " .. playerName)
		return
	end
	lastSave[userId] = now

	local success, err = safeExecuteWithRetry(
		function()
			local toysFolder = player:FindFirstChild("Toys")
			local toysData = {}
			if toysFolder then
				for _, toy in pairs(toysFolder:GetChildren()) do
					if toy:IsA("BoolValue") then
						toysData[toy.Name] = toy.Value
					end
				end
			end
			local data = overrideData or {
				Coins = player:WaitForChild("Coins").Value,
				VIP = player:WaitForChild("VIP").Value,
				Toys = toysData
			}
			if player.UserId == YOUR_USER_ID_HERE then
				data.Coins = math.max(data.Coins, 2000)
				data.Toys.HoverToy = true
			end
			local toysLog = "{}"
			if next(data.Toys) then
				local toyEntries = {}
				for k, v in pairs(data.Toys) do
					table.insert(toyEntries, string.format("[%q]=%s", k, tostring(v)))
				end
				toysLog = "{" .. table.concat(toyEntries, ", ") .. "}"
			end
			warn("[CoinSaver] Saving data for " .. playerName .. ": Coins = " .. data.Coins .. ", Toys = " .. toysLog)
			dataStore:SetAsync(player.UserId, data)
		end,
		CONFIG.ERROR_SAVE,
		playerName
	)

	if not success then
		warn("[CoinSaver] Final save failure for " .. playerName .. ": " .. tostring(err))
	end
end

function CoinSaver.loadData(player)
	local playerName = player.Name
	local success, data = safeExecuteWithRetry(
		function()
			return dataStore:GetAsync(player.UserId)
		end,
		CONFIG.ERROR_LOAD,
		playerName
	)

	if success and data and validateData(data) then
		if player.UserId == YOUR_USER_ID_HERE then
			data.Coins = math.max(data.Coins, 2000)
			data.Toys.HoverToy = true
			CoinSaver.saveData(player, data)
		end
		local toysLog = "{}"
		if next(data.Toys) then
			local toyEntries = {}
			for k, v in pairs(data.Toys) do
				table.insert(toyEntries, string.format("[%q]=%s", k, tostring(v)))
			end
			toysLog = "{" .. table.concat(toyEntries, ", ") .. "}"
		end
		warn("[CoinSaver] Loaded valid data for " .. playerName .. ": Coins = " .. data.Coins .. ", Toys = " .. toysLog)
		return data
	end

	local defaultData = createDefaultData()
	if player.UserId == YOUR_USER_ID_HERE then
		defaultData.Coins = 2000
		defaultData.Toys.HoverToy = true
	end
	warn("[CoinSaver] Using default data for " .. playerName .. ": Coins = " .. defaultData.Coins .. ", Toys = {[\"HoverToy\"]=true}")
	return defaultData
end

-- Cleanup on server shutdown
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		pcall(function()
			CoinSaver.saveData(player)
		end)
	end
end)

return CoinSaver