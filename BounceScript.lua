


--------------

local cloud = script.Parent:WaitForChild("CloudPart")
local TweenService = game:GetService("TweenService")

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
local COOLDOWN_TIME = 0.5 -- Seconds

local function bouncePlayer(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end -- Not a player or incomplete character

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end -- Not a player (e.g., NPC)

	-- Check cooldown
	if bounceCooldown[player] and os.clock() - bounceCooldown[player] < COOLDOWN_TIME then
		return
	end
	bounceCooldown[player] = os.clock()

	-- Calculate bounce direction
	local bounceDirection = (rootPart.Position - cloud.Position).Unit + Vector3.new(0, 1, 0)
	local bounceForce = bounceDirection * 100

	-- Apply bounce
	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = bounceForce
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Parent = rootPart

	-- Sound and particles
	boingSound:Play()
	particleEmitter:Emit(20)

	-- Wobble cloud
	local originalSize = cloud.Size
	TweenService:Create(cloud, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize * 1.2}):Play()
	wait(0.1)
	TweenService:Create(cloud, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = originalSize}):Play()

	-- Remove bounce
	wait(0.2)
	bodyVelocity:Destroy()

	-- Clean up cooldown when player leaves
	game.Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			bounceCooldown[player] = nil
		end
	end)
end

-- Ensure cloud is anchored and non-collidable
cloud.Anchored = true
cloud.CanCollide = false

cloud.Touched:Connect(bouncePlayer)