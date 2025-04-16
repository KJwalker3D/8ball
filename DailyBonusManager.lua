--[[
    Configuration
    All daily bonus settings and constants
]]
local CONFIG = {
	-- Daily Bonus Settings
	DAILY_BONUS_AMOUNT = 100,
	DAY_IN_SECONDS = 24 * 60 * 60,

	-- Asset IDs
	ASSET_IDS = {
		DAILY_BONUS_SOUND = "rbxassetid://9125644905",
		DAILY_BONUS_PARTICLES = "rbxassetid://438224846"
	}
}

-- Services
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ServerScriptService = game:GetService("ServerScriptService")

-- Load CoinSaver with error handling
local CoinSaver
local success, result = pcall(function()
	CoinSaver = require(ServerScriptService.CoinSaver)
end)
if not success then
	warn("[DailyBonusManager] Failed to load CoinSaver: " .. tostring(result))
	CoinSaver = { saveData = function() end }
end

--[[
    Utility Functions
    Helper functions for common operations
]]

--- Creates a new sound instance with the given ID
--- @param soundId string The sound ID to use
--- @param parent Instance The parent instance
--- @param volume number? Optional volume (default: 1)
--- @return Sound The created sound instance
local function createSound(soundId, parent, volume)
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = volume or 1
	sound.Parent = parent
	return sound
end

--- Creates a new particle emitter with the given settings
--- @param texture string The particle texture ID
--- @param color Color3 The particle color
--- @param parent Instance feelings The parent instance
--- @param rate number The emission rate
--- @return ParticleEmitter The created particle emitter
local function createParticleEmitter(texture, color, parent, rate)
	local particles = Instance.new("ParticleEmitter")
	particles.Texture = texture
	particles.Color = ColorSequence.new(color)
	particles.Rate = rate
	particles.Lifetime = NumberRange.new(0.5, 1)
	particles.Speed = NumberRange.new(5, 10)
	particles.SpreadAngle = Vector2.new(360, 360)
	particles.Parent = parent
	return particles
end

--- Creates a notification billboard
--- @param text string The text to display
--- @param color Color3 The text color
--- @param parent Instance The parent instance
--- @return table A table containing the billboard and text label
local function createNotification(text, color, parent)
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NotificationGui"
	billboard.Size = UDim2.new(0, 50, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = parent

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = text
	textLabel.TextColor3 = color
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	return {
		billboard = billboard,
		textLabel = textLabel
	}
end

--[[
    Daily Bonus Functions
    Functions that handle daily bonus mechanics
]]

--- Shows the daily bonus animation and effects
--- @param player Player The player who received the daily bonus
--- @param ballModel Model The 8-ball model
local function showDailyBonus(player, ballModel)
	warn("[DailyBonusManager] Showing daily bonus for " .. player.Name)
	local bonusParticles = createParticleEmitter(
		CONFIG.ASSET_IDS.DAILY_BONUS_PARTICLES,
		Color3.fromRGB(255, 215, 0),
		ballModel.ball, -- Attach to ball part
		50
	)
	bonusParticles.Enabled = true

	local bonusSound = createSound(CONFIG.ASSET_IDS.DAILY_BONUS_SOUND, ballModel.ball, 0.7)
	bonusSound:Play()

	local notification = createNotification(
		"Daily Bonus: +" .. CONFIG.DAILY_BONUS_AMOUNT .. " Coins!",
		Color3.fromRGB(255, 215, 0),
		ballModel.ball
	)

	wait(1.5)
	local tween = TweenService:Create(notification.textLabel, TweenInfo.new(0.5), {
		TextTransparency = 1,
		TextStrokeTransparency = 1
	})
	tween:Play()
	wait(0.5)
	bonusParticles.Enabled = false
	bonusParticles:Destroy()
	bonusSound:Destroy()
	notification.billboard:Destroy()
end

--- Checks if a player is eligible for daily bonus and awards it if so
--- @param player Player The player to check
--- @param ballModel Model The 8-ball model
--- @param force boolean? Whether to force the daily bonus regardless of time
--- @return boolean Whether the daily bonus was awarded
local function checkAndAwardDailyBonus(player, ballModel, force)
	warn("[DailyBonusManager] Checking daily bonus for " .. player.Name .. ", force: " .. tostring(force))
	local lastClaim = player:WaitForChild("LastClaim")
	local coins = player:WaitForChild("Coins")
	local currentTime = os.time()

	if force or (currentTime - lastClaim.Value >= CONFIG.DAY_IN_SECONDS) then
		warn("[DailyBonusManager] Awarding " .. CONFIG.DAILY_BONUS_AMOUNT .. " coins to " .. player.Name)
		coins.Value = coins.Value + CONFIG.DAILY_BONUS_AMOUNT
		lastClaim.Value = currentTime
		showDailyBonus(player, ballModel)
		CoinSaver.saveData(player)
		return true
	end
	warn("[DailyBonusManager] No daily bonus awarded for " .. player.Name .. ": time not elapsed")
	return false
end

-- Test function to verify module functionality
local function testDailyBonus()
	for _, player in pairs(Players:GetPlayers()) do
		warn("[DailyBonusManager] Running test for " .. player.Name)
		checkAndAwardDailyBonus(player, game.Workspace:FindFirstChild("BallModel") or Instance.new("Model"), true)
	end
end

-- Run test on load (remove after confirming it works)
--warn("[DailyBonusManager] Module loaded, running test")
testDailyBonus()

return {
	checkAndAwardDailyBonus = checkAndAwardDailyBonus,
	showDailyBonus = showDailyBonus
}