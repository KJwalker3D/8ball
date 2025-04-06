-- 100 coins developer product id: 3258288474

local model = script.Parent
local ball = model:WaitForChild("ball")
local clickDetector = model:WaitForChild("ClickDetector")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")
local MarketplaceService = game:GetService("MarketplaceService")

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

local COIN_PACK_ID = 3258288474 -- Replace with your Product ID

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
	coins.Value = 100
	coins.Parent = player

	local lastClaim = Instance.new("IntValue")
	lastClaim.Name = "LastClaim"
	lastClaim.Value = os.time()
	lastClaim.Parent = player

	shakeEvent:FireClient(player, {type = "Init"}, coins.Value)
end)

clickDetector.MouseClick:Connect(function(player)
	shakeEvent:FireClient(player, {type = "ShowQuestion"}, player:WaitForChild("Coins").Value)
end)

shakeEvent.OnServerEvent:Connect(function(player)
	local coins = player:WaitForChild("Coins")
	local lastClaim = player:WaitForChild("LastClaim")

	local currentTime = os.time()
	local dayInSeconds = 24 * 60 * 60
	if currentTime - lastClaim.Value >= dayInSeconds then
		coins.Value = coins.Value + 100
		lastClaim.Value = currentTime
	end

	local final = shakeBall()
	coins.Value = coins.Value + 5
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

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end

	if receiptInfo.ProductId == COIN_PACK_ID then
		local coins = player:WaitForChild("Coins")
		coins.Value = coins.Value + 100
		shakeEvent:FireClient(player, {type = "Init"}, coins.Value) -- Sync coins
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end

	return Enum.ProductPurchaseDecision.NotProcessedYet
end