local cloud = script.Parent:WaitForChild("CloudPart")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Sound (optional - you can remove if you don't want any sound)
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
local touchCooldown = {}
local COOLDOWN_TIME = 0.5

-- Hover setup
local baseCFrame = cloud.CFrame
local hoverAmplitude = 3
local hoverSpeed = 0.5

local function onTouched(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	if not humanoid then return end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end

	-- Cooldown check
	if touchCooldown[player] and os.clock() - touchCooldown[player] < COOLDOWN_TIME then
		return
	end
	touchCooldown[player] = os.clock()

	-- Optional: sound and particles
	boingSound.PlaybackSpeed = math.random(8, 12) / 10
	boingSound:Play()
	particleEmitter:Emit(20)

	-- Optional: cloud wobble with flash
	local originalSize = cloud.Size
	local originalColor = cloud.Color or Color3.fromRGB(239, 209, 248)
	local originalTexture = cloud.TextureID or "rbxassetid://131570193623799"
	local newTexture = ""

	cloud.Color = Color3.fromRGB(115, 253, 255)
	cloud.TextureID = newTexture
	TweenService:Create(cloud, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize * 1.2}):Play()
	wait(0.1)
	TweenService:Create(cloud, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = originalSize, Color = originalColor}):Play()
	wait(0.2)
	cloud.TextureID = originalTexture

	-- Clean up cooldown when player leaves
	game.Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			touchCooldown[player] = nil
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

cloud.Touched:Connect(onTouched)
