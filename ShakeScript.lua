--[[
	Configuration
	All game settings and constants in one place
]]
local CONFIG = {
	-- Game Settings
	DEFAULT_COINS = 100,
	DAILY_BONUS_AMOUNT = 100,
	SHAKE_REWARD_VIP = 10,
	SHAKE_REWARD_NORMAL = 5,
	REROLL_COST = 100,
	
	-- Animation Settings
	SHAKE_DURATION = 15,
	SHAKE_INTERVAL = 0.2,
	SHAKE_INTERVAL_DECREASE = 0.01,
	SHAKE_OFFSET = 0.1,
	CELEBRATION_DURATION = 1,
	PROMPT_TIMEOUT = 5,
	
	-- Visual Settings
	HOVER_AMPLITUDE = 1.5,
	HOVER_SPEED = 0.5,
	SPIN_SPEED = 36,
	
	-- Asset IDs
	ASSET_IDS = {
		-- Sounds
		COIN_SOUND = "rbxassetid://607665037",
		CLICK_BALL_SOUND = "rbxassetid://9125397583",
		CELEBRATION_SOUND_ANGRY = "rbxassetid://186669531",
		CELEBRATION_SOUND_MYSTERIOUS = "rbxassetid://9116395089",
		CELEBRATION_SOUND_SWEET = "rbxassetid://111598396888819",
		CELEBRATION_SOUND_SARCASTIC = "rbxassetid://18204124897",
		BADGE_SOUND = "rbxassetid://6648577112",
		DAILY_BONUS_SOUND = "rbxassetid://9125644905",
		
		-- Particles
		CELEBRATION_PARTICLES_ANGRY = "rbxassetid://16933997761",
		CELEBRATION_PARTICLES_MYSTERIOUS = "rbxassetid://6700009498",
		CELEBRATION_PARTICLES_SWEET = "rbxassetid://5762409776",
		CELEBRATION_PARTICLES_SARCASTIC = "rbxassetid://16908034492",
		BADGE_PARTICLES = "rbxassetid://18699497367",
		DAILY_BONUS_PARTICLES = "rbxassetid://438224846"
	},
	
	-- Product IDs
	PRODUCT_IDS = {
		COIN_PACK = 3258288474,
		VIP_PASS = 1161085782
	},
	
	-- Badge IDs
	BADGE_IDS = {
		VISITOR = 4484079797052173,
		MASTER = 1768735404098629
	}
}

-- Services
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")
local CoinSaver = require(game.ServerScriptService.CoinSaver)

-- Model references
local model = script.Parent
local ball = model:WaitForChild("ball")
local part = model:WaitForChild("CelebrationParticleEmitter")

-- Events
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")
local buyVIPEvent = game.ReplicatedStorage:WaitForChild("BuyVIPEvent")
local promptEnableEvent = Instance.new("RemoteEvent")
promptEnableEvent.Name = "PromptEnableEvent"
promptEnableEvent.Parent = game.ReplicatedStorage

-- Sounds
local coinSound = Instance.new("Sound")
coinSound.SoundId = CONFIG.ASSET_IDS.COIN_SOUND
coinSound.Parent = model

local clickBallSound = Instance.new("Sound")
clickBallSound.SoundId = CONFIG.ASSET_IDS.CLICK_BALL_SOUND
clickBallSound.Parent = ball

-- Constants
local COIN_PACK_ID = CONFIG.PRODUCT_IDS.COIN_PACK
local VIP_PASS_ID = CONFIG.PRODUCT_IDS.VIP_PASS
local BADGE_ID_VISITOR = CONFIG.BADGE_IDS.VISITOR
local BADGE_ID_MASTER = CONFIG.BADGE_IDS.MASTER

-- Ball animation constants
local baseCFrame = ball.CFrame
local hoverAmplitude = CONFIG.HOVER_AMPLITUDE
local hoverSpeed = CONFIG.HOVER_SPEED
local spinSpeed = CONFIG.SPIN_SPEED

-- State variables
local isShaking = false
local activeTweens = {} -- Track tweens for cleanup
local forceDailyBonus = false

-- Personalities
local personalities = {
	{color = Color3.fromRGB(255, 0, 0), type = "Angry", font = Enum.Font.Arcade, responses = {
		"YES, YOU FOOL!", "NO, STOP WASTING MY TIME!", "MAYBE, IF YOU SHUT UP!",
		"YES, NOW GO AWAY!", "NO, YOU DON'T DESERVE IT!", "ASK AGAIN, I DARE YOU!",
		"YES, AND I HATE YOU FOR IT!", "NO, YOU'RE TOO DUMB!", "MAYBE, STOP BUGGING ME!",
		"YES, GRRRR!"
	}},
	{color = Color3.fromRGB(0, 0, 255), type = "Mysterious", font = Enum.Font.Fantasy, responses = {
		"The stars say… yes.", "Shadows whisper… no.", "The void ponders… maybe.",
		"Fate aligns… yes.", "The cosmos denies… no.", "A riddle says… maybe.",
		"Eternity nods… yes.", "Darkness shrugs… no.", "The unknown hints… maybe.",
		"Destiny hums… yes."
	}},
	{color = Color3.fromRGB(255, 105, 180), type = "Sweet", font = Enum.Font.Cartoon, responses = {
		"Oh sweetie, yes, so lovely!", "No, but you're still amazing!", "Maybe, isn't that fun?",
		"Yes, darling, perfect!", "No, cutie, try again!", "Maybe, you precious thing!",
		"Yes, oh how wonderful!", "No, but you're adorable!", "Maybe, so exciting!",
		"Yes, my little star!"
	}},
	{color = Color3.fromRGB(0, 255, 0), type = "Sarcastic", font = Enum.Font.SourceSansBold, responses = {
		"Yes, genius, obviously.", "No, shocker, huh?", "Maybe, if you're lucky, dimwit.",
		"Yes, you finally got one right!", "No, what a surprise.", "Maybe, don't hold your breath.",
		"Yes, wow, you're a prodigy.", "No, try harder, loser.", "Maybe, who even cares?",
		"Yes, clap for yourself, moron."
	}}
}

-- Proximity Prompt
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Ask the 8-Ball"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 30
prompt.RequiresLineOfSight = false
prompt.Enabled = true
prompt.Parent = ball

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
--- @param parent Instance The parent instance
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

--- Safely executes a function with error handling
--- @param func function The function to execute
--- @param errorMessage string The error message to display if the function fails
--- @return boolean, any Whether the function succeeded and its return value
local function safeExecute(func, errorMessage)
	local success, result = pcall(func)
	if not success then
		warn(errorMessage .. ": " .. tostring(result))
	end
	return success, result
end

--[[
	Core Game Functions
	Functions that handle the main game mechanics
]]

--- Shakes the 8-ball and returns a random personality
--- @param player Player The player who triggered the shake
--- @return table The selected personality
local function shakeBall(player)
	isShaking = true
	local particles = ball:FindFirstChild("ParticleEmitterBallSparkles")
	local celebParticles = part:FindFirstChild("CelebrationParticles")
	local celebSound = model:WaitForChild("CelebrationSound")
	local ballToon = model:WaitForChild("ballToon")
	local originalCFrame = ball.CFrame
	
	-- Shake animation
	for i = 1, CONFIG.SHAKE_DURATION do
		local rand = personalities[math.random(1, #personalities)]
		ball.Color = rand.color
		if particles then particles.Color = ColorSequence.new(rand.color) end
		
		local offset = Vector3.new(
			math.random(-1, 1) * CONFIG.SHAKE_OFFSET,
			math.random(-1, 1) * CONFIG.SHAKE_OFFSET,
			math.random(-1, 1) * CONFIG.SHAKE_OFFSET
		)
		
		local tweenBall = TweenService:Create(ball, TweenInfo.new(0.1), {CFrame = originalCFrame + offset})
		local tweenToon = TweenService:Create(ballToon, TweenInfo.new(0.1), {CFrame = originalCFrame + offset})
		activeTweens[tweenBall] = true
		activeTweens[tweenToon] = true
		tweenBall:Play()
		tweenToon:Play()
		
		wait(CONFIG.SHAKE_INTERVAL - (i * CONFIG.SHAKE_INTERVAL_DECREASE))
	end
	
	-- Final personality selection
	local final = personalities[math.random(1, #personalities)]
	ball.Color = final.color
	if particles then particles.Color = ColorSequence.new(final.color) end
	
	local finalTweenBall = TweenService:Create(ball, TweenInfo.new(0.2), {CFrame = originalCFrame})
	local finalTweenToon = TweenService:Create(ballToon, TweenInfo.new(0.2), {CFrame = originalCFrame})
	activeTweens[finalTweenBall] = true
	activeTweens[finalTweenToon] = true
	finalTweenBall:Play()
	finalTweenToon:Play()
	
	-- Set personality and play effects
	ball:SetAttribute("Personality", final.type)
	local particleTexture, particleColor, soundId
	
	if final.type == "Angry" then
		particleTexture = CONFIG.ASSET_IDS.CELEBRATION_PARTICLES_ANGRY
		particleColor = Color3.fromRGB(255, 0, 0)
		soundId = CONFIG.ASSET_IDS.CELEBRATION_SOUND_ANGRY
	elseif final.type == "Mysterious" then
		particleTexture = CONFIG.ASSET_IDS.CELEBRATION_PARTICLES_MYSTERIOUS
		particleColor = Color3.fromRGB(0, 0, 255)
		soundId = CONFIG.ASSET_IDS.CELEBRATION_SOUND_MYSTERIOUS
	elseif final.type == "Sweet" then
		particleTexture = CONFIG.ASSET_IDS.CELEBRATION_PARTICLES_SWEET
		particleColor = Color3.fromRGB(255, 105, 180)
		soundId = CONFIG.ASSET_IDS.CELEBRATION_SOUND_SWEET
	elseif final.type == "Sarcastic" then
		particleTexture = CONFIG.ASSET_IDS.CELEBRATION_PARTICLES_SARCASTIC
		particleColor = Color3.fromRGB(0, 255, 0)
		soundId = CONFIG.ASSET_IDS.CELEBRATION_SOUND_SARCASTIC
	end
	
	celebParticles.Texture = particleTexture
	celebParticles.Color = ColorSequence.new(particleColor)
	celebSound.SoundId = soundId
	celebParticles.Enabled = true
	celebSound:Play()
	
	wait(CONFIG.CELEBRATION_DURATION)
	celebParticles.Enabled = false
	isShaking = false
	
	-- Timeout to re-enable prompt if client doesn't respond
	spawn(function()
		wait(CONFIG.PROMPT_TIMEOUT)
		if not prompt.Enabled then
			prompt.Enabled = true
			print("Prompt re-enabled via timeout for " .. player.Name)
		end
	end)
	
	-- Cleanup tweens
	for tween in pairs(activeTweens) do
		activeTweens[tween] = nil
	end
	
	return final
end

--[[
	Player Data Functions
	Functions that handle player data loading, saving, and management
]]

--- Loads coins for a player with retry logic
--- @param player Player The player to load coins for
--- @return number The player's coin amount
local function loadCoins(player)
	local success, data
	for i = 1, 3 do
		success, data = pcall(function()
			return game:GetService("DataStoreService"):GetDataStore("PlayerCoinsV1"):GetAsync(player.UserId)
		end)
		if success then break end
		warn("Failed to load coins for " .. player.Name .. " (Attempt " .. i .. "): " .. tostring(data))
		wait(2)
	end
	return success and data or CONFIG.DEFAULT_COINS
end

--[[
	Reward Functions
	Functions that handle badges, daily bonuses, and other rewards
]]

--- Awards a badge to a player with visual effects
--- @param player Player The player to award the badge to
--- @param badgeId number The ID of the badge to award
--- @param badgeName string The display name of the badge
local function awardBadge(player, badgeId, badgeName)
	if not BadgeService:UserHasBadgeAsync(player.UserId, badgeId) then
		BadgeService:AwardBadge(player.UserId, badgeId)
		
		-- Create badge notification
		local notification = createNotification("Badge Earned: " .. badgeName .. "!", Color3.fromRGB(255, 215, 0), ball)
		
		-- Create celebration effects
		local particles = createParticleEmitter(CONFIG.ASSET_IDS.BADGE_PARTICLES, Color3.fromRGB(255, 215, 0), ball, 30)
		
		local sound = createSound(CONFIG.ASSET_IDS.BADGE_SOUND, ball, 0.7)
		sound:Play()
		
		-- Animate and cleanup
		wait(1.5)
		TweenService:Create(notification.textLabel, TweenInfo.new(0.5), {
			TextTransparency = 1,
			TextStrokeTransparency = 1
		}):Play()
		wait(0.5)
		particles.Enabled = false
		particles:Destroy()
		notification.billboard:Destroy()
		sound:Destroy()
	end
end

--- Shows the daily bonus animation and effects
--- @param player Player The player who received the daily bonus
local function showDailyBonus(player)
	local bonusParticles = createParticleEmitter(CONFIG.ASSET_IDS.DAILY_BONUS_PARTICLES, Color3.fromRGB(255, 215, 0), ball, 50)
	bonusParticles.Enabled = true
	
	local bonusSound = createSound(CONFIG.ASSET_IDS.DAILY_BONUS_SOUND, ball, 0.7)
	bonusSound:Play()
	
	local notification = createNotification("Daily Bonus: +100 Coins!", Color3.fromRGB(255, 215, 0), ball)
	
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

--[[
	Animation Functions
	Functions that handle visual effects and animations
]]

-- Hover and Spin animation
RunService.Heartbeat:Connect(function(dt)
	if not isShaking then
		local hoverOffset = Vector3.new(0, math.sin(os.clock() * hoverSpeed) * hoverAmplitude, 0)
		local spinAngle = os.clock() * spinSpeed
		local ballToon = model:WaitForChild("ballToon")
		ball.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
		ballToon.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
	end
end)

--[[
	Event Handlers
	Functions that handle various game events
]]

-- Player join/leave handlers
Players.PlayerAdded:Connect(function(player)
	local data
	local success = false
	
	-- Retry CoinSaver.loadData
	for i = 1, 3 do
		success, data = pcall(function()
			return CoinSaver.loadData(player)
		end)
		if success then
			print("Coin load attempt", i, "for", player.Name, ": Coins =", data and data.Coins or "nil")
			break
		end
		warn("Failed to load CoinSaver data for", player.Name, "on attempt", i)
		wait(1)
	end
	
	-- Fallback if load fails
	if not success or not data or not data.Coins then
		data = {Coins = CONFIG.DEFAULT_COINS, VIP = false}
		warn("Using default data for", player.Name, ": Coins = " .. CONFIG.DEFAULT_COINS)
	end
	
	-- Initialize player data
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins or CONFIG.DEFAULT_COINS
	coins.Parent = player
	
	local vip = Instance.new("BoolValue")
	vip.Name = "VIP"
	vip.Value = MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID) or data.VIP
	vip.Parent = player
	
	local lastClaim = Instance.new("IntValue")
	lastClaim.Name = "LastClaim"
	lastClaim.Value = os.time()
	lastClaim.Parent = player
	
	-- Initialize shake progress tracking
	local shakeProgress = Instance.new("Folder")
	shakeProgress.Name = "ShakeProgress"
	shakeProgress.Parent = player
	for _, personality in pairs(personalities) do
		local clicked = Instance.new("BoolValue")
		clicked.Name = personality.type
		clicked.Value = false
		clicked.Parent = shakeProgress
	end
	
	-- Check and award Welcome badge
	local badgeSuccess, hasBadge = false, false
	for i = 1, 3 do
		badgeSuccess, hasBadge = pcall(function()
			return BadgeService:UserHasBadgeAsync(player.UserId, BADGE_ID_VISITOR)
		end)
		if badgeSuccess then
			print("Badge check attempt", i, "for", player.Name, ": hasBadge =", hasBadge)
			break
		end
		warn("Failed to check Welcome badge for", player.Name, "on attempt", i)
		wait(1)
	end
	
	if badgeSuccess and not hasBadge then
		awardBadge(player, BADGE_ID_VISITOR, "Welcome!")
		print("Awarded Welcome badge to", player.Name)
	else
		if not badgeSuccess then
			warn("All attempts failed to check Welcome badge for", player.Name)
		else
			print(player.Name, "already has Welcome badge")
		end
	end
	
	shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
end)

Players.PlayerRemoving:Connect(function(player)
	CoinSaver.saveData(player)
	if isShaking then
		for tween in pairs(activeTweens) do
			tween:Cancel()
			activeTweens[tween] = nil
		end
		isShaking = false
		prompt.Enabled = true
	end
end)

-- Game close handler
game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		CoinSaver.saveData(player)
	end
end)

-- Proximity prompt handler
prompt.Triggered:Connect(function(player)
	if isShaking then
		shakeEvent:FireClient(player, {type = "Busy", ball = model})
		print("Prompt blocked: isShaking true")
		return
	end
	prompt.Enabled = false
	print("ProximityPrompt triggered for " .. player.Name .. ", prompt disabled")
	clickBallSound:Play()
	shakeEvent:FireClient(player, {type = "ShowQuestion", ball = model}, player:WaitForChild("Coins").Value)
end)

-- Remote event handlers
shakeEvent.OnServerEvent:Connect(function(player, ballModel, question)
	if ballModel ~= model then return end
	if isShaking then
		shakeEvent:FireClient(player, {type = "Busy", ball = model})
		return
	end
	
	local coins = player:WaitForChild("Coins")
	local vip = player:WaitForChild("VIP")
	local lastClaim = player:WaitForChild("LastClaim")
	local currentTime = os.time()
	local dayInSeconds = 24 * 60 * 60
	
	-- Check and award daily bonus
	if forceDailyBonus or (currentTime - lastClaim.Value >= dayInSeconds) then
		coins.Value = coins.Value + CONFIG.DAILY_BONUS_AMOUNT
		lastClaim.Value = currentTime
		coinSound:Play()
		showDailyBonus(player)
		print("Daily Bonus Triggered for " .. player.Name)
	end
	
	-- Process shake
	local final = shakeBall(player)
	coins.Value = coins.Value + (vip.Value and CONFIG.SHAKE_REWARD_VIP or CONFIG.SHAKE_REWARD_NORMAL)
	coinSound:Play()
	
	-- Check for Master Shaker badge
	local shakeProgress = player:WaitForChild("ShakeProgress")
	local personalityClicked = shakeProgress:FindFirstChild(final.type)
	if personalityClicked and not personalityClicked.Value then 
		personalityClicked.Value = true
		local allClicked = true
		for _, clicked in pairs(shakeProgress:GetChildren()) do 
			if not clicked.Value then
				allClicked = false
				break
			end
		end
		if allClicked then
			awardBadge(player, BADGE_ID_MASTER, "Master Shaker")
		end
	end
	
	CoinSaver.saveData(player)
	shakeEvent:FireClient(player, {
		type = "Response",
		ball = model,
		personality = final,
		response = final.responses[math.random(1, #final.responses)],
		question = question
	}, coins.Value)
end)

promptEnableEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	prompt.Enabled = true
	print("Prompt re-enabled for " .. player.Name .. " after client fade")
end)

rerollEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local coins = player:WaitForChild("Coins")
	if coins.Value >= 100 then
		coins.Value = coins.Value - 100
		local final = shakeBall(player)
		local shakeProgress = player:WaitForChild("ShakeProgress")
		local personalityClicked = shakeProgress:FindFirstChild(final.type)
		if personalityClicked and not personalityClicked.Value then
			personalityClicked.Value = true
			local allClicked = true
			for _, clicked in pairs(shakeProgress:GetChildren()) do
				if not clicked.Value then
					allClicked = false
					break
				end
			end
			if allClicked then
				awardBadge(player, BADGE_ID_MASTER, "Master Shaker")
			end
		end
		CoinSaver.saveData(player)
		shakeEvent:FireClient(player, {
			type = "RerollResponse",
			ball = model,
			personality = final,
			response = final.responses[math.random(1, #final.responses)]
		}, coins.Value)
	end
end)

buyVIPEvent.OnServerEvent:Connect(function(player)
	MarketplaceService:PromptGamePassPurchase(player, VIP_PASS_ID)
end)

-- Marketplace handlers
MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, gamePassId, purchased)
	if gamePassId == VIP_PASS_ID and purchased then
		local vip = player:WaitForChild("VIP")
		vip.Value = true
		CoinSaver.saveData(player)
		shakeEvent:FireClient(player, {type = "Init"}, player:WaitForChild("Coins").Value)
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if receiptInfo.ProductId == COIN_PACK_ID then
		local coins = player:WaitForChild("Coins")
		coins.Value = coins.Value + 100
		CoinSaver.saveData(player)
		shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

-- Debug information
print("Prompt created:", prompt.Parent == ball and "on ball" or "not on ball")
print("Prompt enabled:", prompt.Enabled)
print("Ball position:", ball.Position)
print("Ball size:", ball.Size)