local ball = script.Parent
local clickDetector = ball:WaitForChild("ClickDetector")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")

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
	for i = 1, 15 do
		local rand = personalities[math.random(1, #personalities)]
		ball.Color = rand.color
		wait(0.2 - (i * 0.01))
	end
	local final = personalities[math.random(1, #personalities)]
	ball.Color = final.color
	ball:SetAttribute("Personality", final.type)
	return final
end

game.Players.PlayerAdded:Connect(function(player)
	local coins = Instance.new("IntValue")
	coins.Name = "Coins"
	coins.Value = 100 -- Start with 100 coins
	coins.Parent = player

	local lastClaim = Instance.new("IntValue")
	lastClaim.Name = "LastClaim"
	lastClaim.Value = os.time() -- Set to now so next claim is in 24h
	lastClaim.Parent = player

	-- Sync initial coins to client
	shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
end)

clickDetector.MouseClick:Connect(function(player)
	local coins = player:WaitForChild("Coins")
	local lastClaim = player:WaitForChild("LastClaim")

	-- Daily claim check
	local currentTime = os.time()
	local dayInSeconds = 24 * 60 * 60
	if currentTime - lastClaim.Value >= dayInSeconds then
		coins.Value = coins.Value + 100
		lastClaim.Value = currentTime
	end

	local final = shakeBall()
	coins.Value = coins.Value + 5 -- Add 5 coins per question
	shakeEvent:FireClient(player, final, coins.Value)
end)

rerollEvent.OnServerEvent:Connect(function(player)
	local coins = player:WaitForChild("Coins")
	if coins.Value >= 100 then
		coins.Value = coins.Value - 100
		local final = shakeBall()
		shakeEvent:FireClient(player, final, coins.Value)
	end
end)