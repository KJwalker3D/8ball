--[[
	CoinSaver Module
	Handles player data persistence and migration
]]

--[[
	Configuration
	All settings and constants in one place
]]
local CONFIG = {
	-- DataStore Settings
	DATASTORE_NAME = "PlayerDataV1",
	OLD_DATASTORE_NAME = "PlayerCoinsV1", -- For migration
	MAX_RETRIES = 3,
	RETRY_DELAY = 2,
	
	-- Default Values
	DEFAULT_COINS = 100,
	DEFAULT_VIP = false,
	
	-- Error Messages
	ERROR_SAVE = "Failed to save data for %s (Attempt %d): %s",
	ERROR_LOAD = "Failed to load data for %s (Attempt %d): %s",
	ERROR_MIGRATION = "Failed to migrate data for %s (Attempt %d): %s"
}

-- Services
local DataStoreService = game:GetService("DataStoreService")
local dataStore = DataStoreService:GetDataStore(CONFIG.DATASTORE_NAME)
local oldCoinStore = DataStoreService:GetDataStore(CONFIG.OLD_DATASTORE_NAME)

-- Module table
local CoinSaver = {}

--[[
	Utility Functions
	Helper functions for common operations
]]

--- Safely executes a function with retry logic
--- @param func function The function to execute
--- @param errorMessage string The error message format
--- @param playerName string The player's name
--- @return boolean, any Whether the function succeeded and its return value
local function safeExecuteWithRetry(func, errorMessage, playerName)
	local success, result
	for i = 1, CONFIG.MAX_RETRIES do
		success, result = pcall(func)
		if success then break end
		warn(string.format(errorMessage, playerName, i, tostring(result)))
		wait(CONFIG.RETRY_DELAY)
	end
	return success, result
end

--- Validates player data structure
--- @param data table The data to validate
--- @return boolean Whether the data is valid
local function validateData(data)
	return type(data) == "table" 
		and type(data.Coins) == "number" 
		and type(data.VIP) == "boolean"
end

--- Creates default player data
--- @return table The default data structure
local function createDefaultData()
	return {
		Coins = CONFIG.DEFAULT_COINS,
		VIP = CONFIG.DEFAULT_VIP
	}
end

--[[
	Core Functions
	Main data operations
]]

--- Saves player data to the DataStore
--- @param player Player The player whose data to save
function CoinSaver.saveData(player)
	local success, err = safeExecuteWithRetry(
		function()
			local data = {
				Coins = player:WaitForChild("Coins").Value,
				VIP = player:WaitForChild("VIP").Value
			}
			dataStore:SetAsync(player.UserId, data)
		end,
		CONFIG.ERROR_SAVE,
		player.Name
	)
	
	if not success then
		warn("Final save failure for " .. player.Name .. ": " .. tostring(err))
	end
end

--- Loads player data from the DataStore with migration support
--- @param player Player The player whose data to load
--- @return table The loaded player data
function CoinSaver.loadData(player)
	-- Try to load from new store
	local success, data = safeExecuteWithRetry(
		function()
			return dataStore:GetAsync(player.UserId)
		end,
		CONFIG.ERROR_LOAD,
		player.Name
	)
	
	-- If data exists and is valid, return it
	if success and data and validateData(data) then
		return data
	end
	
	-- Try to migrate from old store
	local oldSuccess, oldData = safeExecuteWithRetry(
		function()
			return oldCoinStore:GetAsync(player.UserId)
		end,
		CONFIG.ERROR_MIGRATION,
		player.Name
	)
	
	-- If old data exists, migrate it
	if oldSuccess and oldData then
		local migratedData = {
			Coins = oldData,
			VIP = CONFIG.DEFAULT_VIP
		}
		CoinSaver.saveData(player) -- Save to new store immediately
		return migratedData
	end
	
	-- Return default data if all else fails
	return createDefaultData()
end

return CoinSaver