local model = script.Parent
local ball = model:WaitForChild("ball")
local part = model:WaitForChild("CelebrationParticleEmitter")
local clickDetector = model:WaitForChild("ClickDetector")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")
local TweenService = game:GetService("TweenService")
local CoinSaver = require(game.ServerScriptService.CoinSaver)

local coinSound = Instance.new("Sound")
coinSound.SoundId = "rbxassetid://607665037"
coinSound.Parent = model
local emoColor = Color3.fromRGB(214, 214, 214)

local personality = {
	color = emoColor, type = "Emo", font = Enum.Font.JosefinSans, responses = {
		"Yes, but it won’t fix the emptiness inside.",
		"No, just like everything else in this bleak world.",
		"Maybe, though the shadows don’t care either way.",
		"Yes, a fleeting light in this endless night.",
		"No, the universe sighs at your hope.",
		"Maybe, lost in the fog of my soul.",
		"Yes, even if joy feels like a lie.",
		"No, tears stain the answer black.",
		"Maybe, whispering through the void.",
		"Yes, but the pain lingers still."
	}
}


---change text color to white raindrops to light blue      
local function shakeBall()
	local particles = ball:FindFirstChild("ParticleEmitterBallSparkles")
	local celebParticles = part:FindFirstChild("CelebrationParticles")
	local celebSound = model:WaitForChild("CelebrationSound")
	local originalCFrame = ball.CFrame
	local ballOriginalSize = ball.Size
	local text = model:WaitForChild("Text")
	local textOriginalSize = text.Size
	local ballToon = model:WaitForChild("ballToon")
	local toonOriginalSize = ballToon.Size
	for i = 1, 15 do
		ball.Color = personality.color
		if particles then particles.Color = ColorSequence.new(personality.color) end
		local offset = Vector3.new(math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1)
		local scale = 1 + math.sin(i * 0.5) * 0.1
		TweenService:Create(ball, TweenInfo.new(0.1), {CFrame = originalCFrame + offset, Size = ballOriginalSize * scale}):Play()
		TweenService:Create(text, TweenInfo.new(0.1), {CFrame = originalCFrame + offset, Size = textOriginalSize * scale}):Play()
		TweenService:Create(ballToon, TweenInfo.new(0.1), {CFrame = originalCFrame + offset, Size = toonOriginalSize * scale}):Play()
		wait(0.2 - (i * 0.01))
	end
	ball.Color = personality.color
	if particles then particles.Color = ColorSequence.new(personality.color) end
	TweenService:Create(ball, TweenInfo.new(0.2), {CFrame = originalCFrame, Size = ballOriginalSize}):Play()
	TweenService:Create(text, TweenInfo.new(0.2), {CFrame = originalCFrame, Size = textOriginalSize}):Play()
	TweenService:Create(ballToon, TweenInfo.new(0.2), {CFrame = originalCFrame, Size = toonOriginalSize}):Play()
	ball:SetAttribute("Personality", personality.type)
	celebParticles.Texture = "rbxassetid://5118926745" -- raindrop
	celebParticles.Color = ColorSequence.new(emoColor)
	celebSound.SoundId = "rbxassetid://135308045" -- Chaotic laugh
	celebParticles.Enabled = true
	celebSound:Play()
	wait(1)
	celebParticles.Enabled = false
	ball.Size = ballOriginalSize
	text.Size = textOriginalSize
	ballToon.Size = toonOriginalSize
	return personality
end

local clickBallSound = Instance.new("Sound")
clickBallSound.SoundId = "rbxassetid://9125397583"
clickBallSound.Parent = ball

clickDetector.MouseClick:Connect(function(player)
	clickBallSound:Play()
	local vip = player:WaitForChild("VIP")
	if not vip.Value then
		shakeEvent:FireClient(player, {type = "Response", ball = model, personality = {responses = {"VIP Only!"}, color = Color3.fromRGB(255, 215, 0), font = Enum.Font.SourceSansBold}}, player:WaitForChild("Coins").Value)
		return
	end
	shakeEvent:FireClient(player, {type = "ShowQuestion", ball = model}, player:WaitForChild("Coins").Value)
end)

shakeEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local vip = player:WaitForChild("VIP")
	if not vip.Value then return end
	local coins = player:WaitForChild("Coins")
	local final = shakeBall()
	coins.Value = coins.Value + 10 -- VIP bonus
	coinSound:Play()
	CoinSaver.saveData(player)
	shakeEvent:FireClient(player, {type = "Response", ball = model, personality = final}, coins.Value)
end)

rerollEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local vip = player:WaitForChild("VIP")
	if not vip.Value then return end
	local coins = player:WaitForChild("Coins")
	if coins.Value >= 100 then
		coins.Value = coins.Value - 100
		local final = shakeBall()
		CoinSaver.saveData(player)
		shakeEvent:FireClient(player, {type = "RerollResponse", ball = model, personality = final}, coins.Value)
	end
end)