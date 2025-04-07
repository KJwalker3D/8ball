local model = script.Parent
local ball = model:WaitForChild("ball")
local part = model:WaitForChild("CelebrationParticleEmitter")
local clickDetector = model:WaitForChild("ClickDetector")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local CoinSaver = require(game.ServerScriptService.CoinSaver)

local coinSound = Instance.new("Sound")
coinSound.SoundId = "rbxassetid://607665037"
coinSound.Parent = model

local COIN_PACK_ID = 3258288474

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

local function shakeBall()
	local particles = ball:FindFirstChild("ParticleEmitterBallSparkles")
	local celebParticles = part:FindFirstChild("CelebrationParticles")
	local celebSound = model:WaitForChild("CelebrationSound")
	local originalCFrame = ball.CFrame
	local text = model:WaitForChild("Text")
	local ballToon = model:WaitForChild("ballToon")
	for i = 1, 15 do
		local rand = personalities[math.random(1, #personalities)]
		ball.Color = rand.color
		if particles then particles.Color = ColorSequence.new(rand.color) end
		local offset = Vector3.new(math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1)
		TweenService:Create(ball, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		TweenService:Create(text, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		TweenService:Create(ballToon, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		wait(0.2 - (i * 0.01))
	end
	local final = personalities[math.random(1, #personalities)]
	ball.Color = final.color
	if particles then particles.Color = ColorSequence.new(final.color) end
	TweenService:Create(ball, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
	TweenService:Create(text, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
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
	return final
end

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
	return success and data or 100 -- Default to 100 if load fails or no data
end

Players.PlayerAdded:Connect(function(player)
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = loadCoins(player)
	coins.Parent = player
	local lastClaim = Instance.new("IntValue")
	lastClaim.Name = "LastClaim"
	lastClaim.Value = os.time()
	lastClaim.Parent = player
	shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
end)

Players.PlayerRemoving:Connect(function(player)
	CoinSaver.saveCoins(player)
end)

game:BindToClose(function()
	for _, player in pairs(Players:GetPlayers()) do
		CoinSaver.saveCoins(player)
	end
end)

local clickBallSound = Instance.new("Sound")
clickBallSound.SoundId = "rbxassetid://9125397583"
clickBallSound.Parent = ball

clickDetector.MouseClick:Connect(function(player)
	clickBallSound:Play()
	shakeEvent:FireClient(player, {type = "ShowQuestion", ball = model}, player:WaitForChild("Coins").Value)
end)

shakeEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local coins = player:WaitForChild("Coins")
	local lastClaim = player:WaitForChild("LastClaim")
	local currentTime = os.time()
	local dayInSeconds = 24 * 60 * 60
	if currentTime - lastClaim.Value >= dayInSeconds then
		coins.Value = coins.Value + 100
		lastClaim.Value = currentTime
		coinSound:Play()
	end
	local final = shakeBall()
	coins.Value = coins.Value + 5
	coinSound:Play()
	CoinSaver.saveCoins(player)
	shakeEvent:FireClient(player, {type = "Response", ball = model, personality = final}, coins.Value)
end)

rerollEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local coins = player:WaitForChild("Coins")
	if coins.Value >= 100 then
		coins.Value = coins.Value - 100
		local final = shakeBall()
		CoinSaver.saveCoins(player)
		shakeEvent:FireClient(player, {type = "RerollResponse", ball = model, personality = final}, coins.Value)
	end
end)

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
	if receiptInfo.ProductId == COIN_PACK_ID then
		local coins = player:WaitForChild("Coins")
		coins.Value = coins.Value + 100
		CoinSaver.saveCoins(player)
		shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end