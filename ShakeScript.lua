local model = script.Parent
local ball = model:WaitForChild("ball")
local part = model:WaitForChild("CelebrationParticleEmitter")
local prompt = Instance.new("ProximityPrompt")
prompt.ActionText = "Ask the 8-Ball"
prompt.HoldDuration = 0.5
prompt.MaxActivationDistance = 30 -- Was 8
prompt.RequiresLineOfSight = false -- Avoid obstructions
prompt.Enabled = true
prompt.Parent = ball
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local BadgeService = game:GetService("BadgeService")
local CoinSaver = require(game.ServerScriptService.CoinSaver)
local buyVIPEvent = game.ReplicatedStorage:WaitForChild("BuyVIPEvent")

local coinSound = Instance.new("Sound")
coinSound.SoundId = "rbxassetid://607665037"
coinSound.Parent = model

local COIN_PACK_ID = 3258288474
local VIP_PASS_ID = 1161085782 -- Replace with real GamePass ID
local BADGE_ID_VISITOR = 4484079797052173 -- Replace
local BADGE_ID_MASTER = 1768735404098629 -- Replace

local personalities = {
	{color = Color3.fromRGB(255, 0, 0), type = "Angry", font = Enum.Font.Arcade, responses = {
		"YES, YOU FOOL!", "NO, STOP WASTING MY TIME!", "MAYBE, IF YOU SHUT UP!",
		"YES, NOW GO AWAY!", "NO, YOU DON’T DESERVE IT!", "ASK AGAIN, I DARE YOU!",
		"YES, AND I HATE YOU FOR IT!", "NO, YOU’RE TOO DUMB!", "MAYBE, STOP BUGGING ME!",
		"YES, GRRRR!"
	}},
	{color = Color3.fromRGB(0, 0, 255), type = "Mysterious", font = Enum.Font.Fantasy, responses = {
		"The stars say… yes.", "Shadows whisper… no.", "The void ponders… maybe.",
		"Fate aligns… yes.", "The cosmos denies… no.", "A riddle says… maybe.",
		"Eternity nods… yes.", "Darkness shrugs… no.", "The unknown hints… maybe.",
		"Destiny hums… yes."
	}},
	{color = Color3.fromRGB(255, 105, 180), type = "Sweet", font = Enum.Font.Cartoon, responses = {
		"Oh sweetie, yes, so lovely!", "No, but you’re still amazing!", "Maybe, isn’t that fun?",
		"Yes, darling, perfect!", "No, cutie, try again!", "Maybe, you precious thing!",
		"Yes, oh how wonderful!", "No, but you’re adorable!", "Maybe, so exciting!",
		"Yes, my little star!"
	}},
	{color = Color3.fromRGB(0, 255, 0), type = "Sarcastic", font = Enum.Font.SourceSansBold, responses = {
		"Yes, genius, obviously.", "No, shocker, huh?", "Maybe, if you’re lucky, dimwit.",
		"Yes, you finally got one right!", "No, what a surprise.", "Maybe, don’t hold your breath.",
		"Yes, wow, you’re a prodigy.", "No, try harder, loser.", "Maybe, who even cares?",
		"Yes, clap for yourself, moron."
	}}
}

local isShaking = false

local function shakeBall()
	isShaking = true
	local particles = ball:FindFirstChild("ParticleEmitterBallSparkles")
	local celebParticles = part:FindFirstChild("CelebrationParticles")
	local celebSound = model:WaitForChild("CelebrationSound")
	local originalCFrame = ball.CFrame
	local ballToon = model:WaitForChild("ballToon")
	for i = 1, 15 do
		local rand = personalities[math.random(1, #personalities)]
		ball.Color = rand.color
		if particles then particles.Color = ColorSequence.new(rand.color) end
		local offset = Vector3.new(math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1)
		TweenService:Create(ball, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		TweenService:Create(ballToon, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		wait(0.2 - (i * 0.01))
	end
	local final = personalities[math.random(1, #personalities)]
	ball.Color = final.color
	if particles then particles.Color = ColorSequence.new(final.color) end
	TweenService:Create(ball, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
	TweenService:Create(ballToon, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
	ball:SetAttribute("Personality", final.type)
	if final.type == "Angry" then
		celebParticles.Texture = "rbxassetid://16933997761"
		celebParticles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
		celebSound.SoundId = "rbxassetid://186669531"
	elseif final.type == "Mysterious" then
		celebParticles.Texture = "rbxassetid://6700009498"
		celebParticles.Color = ColorSequence.new(Color3.fromRGB(0, 0, 255))
		celebSound.SoundId = "rbxassetid://9116395089"
	elseif final.type == "Sweet" then
		celebParticles.Texture = "rbxassetid://5762409776"
		celebParticles.Color = ColorSequence.new(Color3.fromRGB(255, 105, 180))
		celebSound.SoundId = "rbxassetid://111598396888819"
	elseif final.type == "Sarcastic" then
		celebParticles.Texture = "rbxassetid://16908034492"
		celebParticles.Color = ColorSequence.new(Color3.fromRGB(0, 255, 0))
		celebSound.SoundId = "rbxassetid://18204124897"
	end
	celebParticles.Enabled = true
	celebSound:Play()
	wait(1)
	celebParticles.Enabled = false
	isShaking = false
	return final
end

-- Hover and Spin
local baseCFrame = ball.CFrame
local hoverAmplitude = 1.5
local hoverSpeed = 0.5
local spinSpeed = 36

RunService.Heartbeat:Connect(function(dt)
	if not isShaking then
		local hoverOffset = Vector3.new(0, math.sin(os.clock() * hoverSpeed) * hoverAmplitude, 0)
		local spinAngle = os.clock() * spinSpeed
		local ballToon = model:WaitForChild("ballToon")
		ball.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
		ballToon.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
	end
end)

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
	return success and data or 100
end

local function awardBadge(player, badgeId, badgeName)
	if not BadgeService:UserHasBadgeAsync(player.UserId, badgeId) then
		BadgeService:AwardBadge(player.UserId, badgeId)
		local billboard = Instance.new("BillboardGui")
		billboard.Name = "BadgeGui"
		billboard.Size = UDim2.new(0, 50, 0, 25)
		billboard.StudsOffset = Vector3.new(0, 3, 0)
		billboard.AlwaysOnTop = true
		billboard.Parent = ball

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 1, 0)
		textLabel.BackgroundTransparency = 1
		textLabel.Text = "Badge Earned: " .. badgeName .. "!"
		textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
		textLabel.TextStrokeTransparency = 0
		textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
		textLabel.Font = Enum.Font.SourceSansBold
		textLabel.TextScaled = true
		textLabel.Parent = billboard

		local particles = Instance.new("ParticleEmitter")
		particles.Texture = "rbxassetid://18699497367"
		particles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
		particles.Rate = 30
		particles.Lifetime = NumberRange.new(0.5, 1)
		particles.Speed = NumberRange.new(5, 10)
		particles.SpreadAngle = Vector2.new(360, 360)
		particles.Parent = ball
		particles.Enabled = true

		local sound = Instance.new("Sound")
		sound.SoundId = "rbxassetid://6648577112"
		sound.Parent = ball
		sound:Play()

		wait(1.5)
		TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1}):Play()
		wait(0.5)
		particles.Enabled = false
		particles:Destroy()
		billboard:Destroy()
		sound:Destroy()
	end
end

Players.PlayerAdded:Connect(function(player)
	local data = CoinSaver.loadData(player)
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = data.Coins
	coins.Parent = player
	local vip = Instance.new("BoolValue")
	vip.Name = "VIP"
	vip.Value = MarketplaceService:UserOwnsGamePassAsync(player.UserId, VIP_PASS_ID) or data.VIP
	vip.Parent = player
	local lastClaim = Instance.new("IntValue")
	lastClaim.Name = "LastClaim"
	lastClaim.Value = os.time()
	lastClaim.Parent = player

	local shakeProgress = Instance.new("Folder")
	shakeProgress.Name = "ShakeProgress"
	shakeProgress.Parent = player
	for _, personality in pairs(personalities) do
		local clicked = Instance.new("BoolValue")
		clicked.Name = personality.type
		clicked.Value = false
		clicked.Parent = shakeProgress
	end

	awardBadge(player, BADGE_ID_VISITOR, "Welcome!")

	shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
end)

Players.PlayerRemoving:Connect(function(player)
	CoinSaver.saveData(player)
end)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		CoinSaver.saveData(player)
	end
end)

local clickBallSound = Instance.new("Sound")
clickBallSound.SoundId = "rbxassetid://9125397583"
clickBallSound.Parent = ball

local function showDailyBonus(player)
	local bonusParticles = Instance.new("ParticleEmitter")
	bonusParticles.Texture = "rbxassetid://438224846"
	bonusParticles.Color = ColorSequence.new(Color3.fromRGB(255, 215, 0))
	bonusParticles.Rate = 50
	bonusParticles.Lifetime = NumberRange.new(0.5, 1)
	bonusParticles.Speed = NumberRange.new(5, 10)
	bonusParticles.SpreadAngle = Vector2.new(360, 360)
	bonusParticles.Parent = ball
	bonusParticles.Enabled = true

	local bonusSound = Instance.new("Sound")
	bonusSound.SoundId = "rbxassetid://9125644905"
	bonusSound.Volume = 0.7
	bonusSound.Parent = ball
	bonusSound:Play()

	local billboard = Instance.new("BillboardGui")
	billboard.Name = "DailyBonusGui"
	billboard.Size = UDim2.new(0, 50, 0, 25)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = ball

	local textLabel = Instance.new("TextLabel")
	textLabel.Size = UDim2.new(2, 0, 2, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Text = "Daily Bonus: +100 Coins!"
	textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	textLabel.TextStrokeTransparency = 0
	textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = true
	textLabel.Parent = billboard

	wait(1.5)
	local tween = TweenService:Create(textLabel, TweenInfo.new(0.5), {TextTransparency = 1, TextStrokeTransparency = 1})
	tween:Play()

	wait(0.5)
	bonusParticles.Enabled = false
	bonusParticles:Destroy()
	bonusSound:Destroy()
	billboard:Destroy()
end

local forceDailyBonus = false

prompt.Triggered:Connect(function(player)
	if isShaking then
		print("Prompt blocked: isShaking true")
		return
	end
	print("ProximityPrompt triggered for " .. player.Name)
	clickBallSound:Play()
	shakeEvent:FireClient(player, {type = "ShowQuestion", ball = model}, player:WaitForChild("Coins").Value)
end)

-- Debug prompt setup
print("Prompt created:", prompt.Parent == ball and "on ball" or "not on ball")
print("Prompt enabled:", prompt.Enabled)
print("Ball position:", ball.Position)
print("Ball size:", ball.Size)

shakeEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local coins = player:WaitForChild("Coins")
	local vip = player:WaitForChild("VIP")
	local lastClaim = player:WaitForChild("LastClaim")
	local currentTime = os.time()
	local dayInSeconds = 24 * 60 * 60
	if forceDailyBonus or (currentTime - lastClaim.Value >= dayInSeconds) then
		coins.Value = coins.Value + 100
		lastClaim.Value = currentTime
		coinSound:Play()
		showDailyBonus(player)
		print("Daily Bonus Triggered for " .. player.Name)
	end
	local final = shakeBall()
	coins.Value = coins.Value + (vip.Value and 10 or 5)
	coinSound:Play()

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
	shakeEvent:FireClient(player, {type = "Response", ball = model, personality = final}, coins.Value)
end)

rerollEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local coins = player:WaitForChild("Coins")
	if coins.Value >= 100 then
		coins.Value = coins.Value - 100
		local final = shakeBall()

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
		shakeEvent:FireClient(player, {type = "RerollResponse", ball = model, personality = final}, coins.Value)
	end
end)

buyVIPEvent.OnServerEvent:Connect(function(player)
	MarketplaceService:PromptGamePassPurchase(player, VIP_PASS_ID)
end)

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

--- kj: make two badges and add ids here
--- check if vip pass should be a game pass! and update
-- daily claim sound breaks vibe : change it