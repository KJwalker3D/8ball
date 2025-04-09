local cloudModel = script.Parent
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- Get all parts in the model
local cloudParts = {}
for _, part in ipairs(cloudModel:GetDescendants()) do
	if part:IsA("BasePart") then
		table.insert(cloudParts, part)
		part.Anchored = true
		part.CanCollide = false
	end
end

-- Sound (attached to the model, plays globally)
local boingSound = Instance.new("Sound")
boingSound.SoundId = "rbxassetid://5356058949"
boingSound.Volume = 0.8
boingSound.Name = "BoingSound"
boingSound.Parent = cloudModel


-- Debounce table
local bounceCooldown = {}
local COOLDOWN_TIME = 0.5

-- Hover setup (based on first part's CFrame)
local baseCFrame = cloudParts[1].CFrame
local hoverAmplitude = 3
local hoverSpeed = 0.5

-- Bounce function
local function bouncePlayer(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChild("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local player = game.Players:GetPlayerFromCharacter(character)
	if not player then return end

	if bounceCooldown[player] and os.clock() - bounceCooldown[player] < COOLDOWN_TIME then
		return
	end
	bounceCooldown[player] = os.clock()

	-- Bounce direction
	local bounceDirection = (rootPart.Position - cloudParts[1].Position).Unit + Vector3.new(0, 1, 0)
	local bounceForce = bounceDirection * 50

	local bodyVelocity = Instance.new("BodyVelocity")
	bodyVelocity.Velocity = bounceForce
	bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyVelocity.Parent = rootPart

	-- Sound and particles
	boingSound.PlaybackSpeed = math.random(8, 12) / 10
	boingSound:Play()

	for _, part in ipairs(cloudParts) do
		local emitter = part:FindFirstChild("CloudParticles")
		if emitter then
			emitter:Emit(10)
		end
	end

	-- Flash color and bounce size for all parts
	for _, part in ipairs(cloudParts) do
		local originalSize = part.Size
		local originalColor = part.Color
		part.Color = Color3.fromRGB(115, 253, 255)

		local growTween = TweenService:Create(part, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Size = originalSize * 1.2})
		growTween:Play()
		growTween.Completed:Wait()

		local shrinkTween = TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {Size = originalSize, Color = originalColor})
		shrinkTween:Play()
	end

	-- Remove bounce force
	wait(0.2)
	bodyVelocity:Destroy()

	-- Clean up cooldown if player leaves
	game.Players.PlayerRemoving:Connect(function(leavingPlayer)
		if leavingPlayer == player then
			bounceCooldown[player] = nil
		end
	end)
end

-- Attach .Touched event to all parts
for _, part in ipairs(cloudParts) do
	part.Touched:Connect(bouncePlayer)
end


