local cloud = script.Parent:WaitForChild("CloudPart")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Sound
local boingSound = Instance.new("Sound")
boingSound.SoundId = "rbxassetid://5356058949"
boingSound.Volume = 0.8
boingSound.Parent = cloud

-- Particles
local particleEmitter = Instance.new("ParticleEmitter")
particleEmitter.Texture = "rbxassetid://14500233914"
particleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
particleEmitter.Size = NumberSequence.new(1, 0)
particleEmitter.Lifetime = NumberRange.new(0.5, 0.8)
particleEmitter.Rate = 0
particleEmitter.Speed = NumberRange.new(5, 10)
particleEmitter.SpreadAngle = Vector2.new(360, 360)
particleEmitter.Parent = cloud

-- Debounce table
local bounceCooldown = {}
local COOLDOWN_TIME = 0.5

-- Hover setup
local baseCFrame = cloud.CFrame
local hoverAmplitude = 3
local hoverSpeed = 0.5

local function bouncePlayer(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Check cooldown
	if bounceCooldown[player] and os.clock() - bounceCooldown[player] < COOLDOWN_TIME then
		return
	end
	bounceCooldown[player] = os.clock()

	-- Calculate bounce direction
	local bounceDirection = (rootPart.Position - cloud.Position).Unit + Vector3.new(0, 1, 0)
	local bounceForce = bounceDirection * 50

	-- Apply bounce
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = bounceForce
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Parent = rootPart

	-- Sound and particles
	boingSound.PlaybackSpeed = math.random(8, 12) / 10
	boingSound:Play()
	particleEmitter:Emit(20)

	-- Wobble cloud with color flash and texture swap
	local originalSize = cloud.Size
	local originalColor = cloud.Color or Color3.fromRGB(239, 209, 248)
	local originalTexture = cloud.TextureID or "rbxassetid://131570193623799"
	local newTexture = "" -- Empty texture during bounce

	cloud.Color = Color3.fromRGB(115, 253, 255) -- Bright green flash
	cloud.TextureID = newTexture -- Swap to empty texture instantly
	TweenService:Create(cloud, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize * 1.2}):Play()
	wait(0.1)
	TweenService:Create(cloud, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = originalSize, Color = originalColor}):Play()
	wait(0.2) -- Match tween duration
	cloud.TextureID = originalTexture -- Swap back instantly

	-- Remove bounce
	bodyVelocity:Destroy()

	-- Clean up cooldown
	game.Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			bounceCooldown[player] = nil
		end
	end)
end

-- Lock cloud properties
cloud.Anchored = true
cloud.CanCollide = false
for _, part in pairs(script.Parent:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = true
		part.CanCollide = false
	end
end

-- Hover animation
RunService.Heartbeat:Connect(function()
	local hoverOffset = Vector3.new(0, math.sin(os.clock() * hoverSpeed) * hoverAmplitude, 0)
	cloud.CFrame = baseCFrame + hoverOffset
end)

cloud.Touched:Connect(bouncePlayer)