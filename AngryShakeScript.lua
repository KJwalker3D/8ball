local model = script.Parent
local ball = model:WaitForChild("ball")
local part = model:WaitForChild("CelebrationParticleEmitter")
local clickDetector = model:WaitForChild("ClickDetector")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local TweenService = game:GetService("TweenService")

local personality = {
	color = Color3.fromRGB(255, 0, 0), type = "Angry", font = Enum.Font.Arcade, responses = {
		"YES, YOU FOOL!", "NO, STOP WASTING MY TIME!", "MAYBE, IF YOU SHUT UP!",
		"YES, NOW GO AWAY!", "NO, YOU DON’T DESERVE IT!", "ASK AGAIN, I DARE YOU!",
		"YES, AND I HATE YOU FOR IT!", "NO, YOU’RE TOO DUMB!", "MAYBE, STOP BUGGING ME!",
		"YES, GRRRR!"
	}
}

local function shakeBall()
	local particles = ball:FindFirstChild("ParticleEmitterBallSparkles")
	local celebParticles = part:FindFirstChild("CelebrationParticles")
	local celebSound = model:FindFirstChild("CelebrationSound")
	local originalCFrame = ball.CFrame
	local text = model:FindFirstChild("Text")
	local ballToon = model:FindFirstChild("ballToon")
	for i = 1, 15 do
		ball.Color = personality.color
		if particles then particles.Color = ColorSequence.new(personality.color) end
		local offset = Vector3.new(math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1, math.random(-1, 1) * 0.1)
		TweenService:Create(ball, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		TweenService:Create(text, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		TweenService:Create(ballToon, TweenInfo.new(0.1), {CFrame = originalCFrame + offset}):Play()
		wait(0.2 - (i * 0.01))
	end
	ball.Color = personality.color
	if particles then particles.Color = ColorSequence.new(personality.color) end
	TweenService:Create(ball, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
	TweenService:Create(text, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
	TweenService:Create(ballToon, TweenInfo.new(0.2), {CFrame = originalCFrame}):Play()
	ball:SetAttribute("Personality", personality.type)
	-- Celebration
	celebParticles.Texture = "rbxassetid://16933997761"
	celebParticles.Color = ColorSequence.new(Color3.fromRGB(255, 0, 0))
	celebSound.SoundId = "rbxassetid://186669531"
	celebParticles.Enabled = true
	celebSound:Play()
	wait(1)
	celebParticles.Enabled = false
	return personality
end

local clickBallSound = Instance.new("Sound")
clickBallSound.SoundId = "rbxassetid://9125397583"
clickBallSound.Parent = ball

clickDetector.MouseClick:Connect(function(player)
	clickBallSound:Play()
	shakeEvent:FireClient(player, {type = "ShowQuestion", ball = model}, player:WaitForChild("Coins").Value)
end)

shakeEvent.OnServerEvent:Connect(function(player)
	local coins = player:WaitForChild("Coins")
	local final = shakeBall()
	coins.Value = coins.Value + 5
	shakeEvent:FireClient(player, {type = "Response", ball = model, personality = final}, coins.Value)
end)