local model = script.Parent
local ball = model:WaitForChild("ball")
local part = model:WaitForChild("CelebrationParticleEmitter")
local clickDetector = model:WaitForChild("ClickDetector")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CoinSaver = require(game.ServerScriptService.CoinSaver)

local coinSound = Instance.new("Sound")
coinSound.SoundId = "rbxassetid://607665037"
coinSound.Parent = model

local personality = {
	color = Color3.fromRGB(0, 0, 255), type = "Mysterious", font = Enum.Font.Fantasy, responses = {
		"The stars say… yes.", "Shadows whisper… no.", "The void ponders… maybe.",
		"Fate aligns… yes.", "The cosmos denies… no.", "A riddle says… maybe.",
		"Eternity nods… yes.", "Darkness shrugs… no.", "The unknown hints… maybe.",
		"Destiny hums… yes."
	}
}

local isShaking = false -- Flag to pause hover/spin during shake

local function shakeBall()
	isShaking = true
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
	celebParticles.Texture = "rbxassetid://6700009498"
	celebParticles.Color = ColorSequence.new(Color3.fromRGB(0, 0, 255))
	celebSound.SoundId = "rbxassetid://9116395089"
	celebParticles.Enabled = true
	celebSound:Play()
	wait(1)
	celebParticles.Enabled = false
	-- Explicit reset after celebration
	ball.Size = ballOriginalSize
	text.Size = textOriginalSize
	ballToon.Size = toonOriginalSize
	isShaking = false
	return personality
end

-- Hover and Spin Setup
local baseCFrame = ball.CFrame -- Anchor point for hover/spin
local hoverAmplitude = 1.5 -- 1.5 studs hover
local hoverSpeed = 0.4 -- Slow, ethereal hover
local spinSpeed = 20 -- Very slow, hypnotic spin (~18s rotation)

RunService.Heartbeat:Connect(function(dt)
	if not isShaking then
		local hoverOffset = Vector3.new(0, math.sin(os.clock() * hoverSpeed) * hoverAmplitude, 0)
		local spinAngle = os.clock() * spinSpeed
		local text = model:WaitForChild("Text")
		local ballToon = model:WaitForChild("ballToon")
		-- Apply hover and spin to all parts
		ball.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
		text.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
		ballToon.CFrame = baseCFrame * CFrame.Angles(0, math.rad(spinAngle), 0) + hoverOffset
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
	local vip = player:WaitForChild("VIP")
	local final = shakeBall()
	coins.Value = coins.Value + (vip.Value and 10 or 5)
	coinSound:Play()
	CoinSaver.saveData(player)
	shakeEvent:FireClient(player, {type = "Response", ball = model, personality = final}, coins.Value)
end)

rerollEvent.OnServerEvent:Connect(function(player, ballModel)
	if ballModel ~= model then return end
	local coins = player:WaitForChild("Coins")
	if coins.Value >= 100 then
		coins.Value = coins.Value - 100
		CoinSaver.saveData(player)
		local final = shakeBall()
		shakeEvent:FireClient(player, {type = "RerollResponse", ball = model, personality = final}, coins.Value)
	end
end)