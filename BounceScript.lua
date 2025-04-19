local cloudModel = script.Parent
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local COOLDOWN_TIME = 0.5
local BOUNCE_FORCE = 6000 -- Increased for a stronger bounce
local bounceCooldown = {}
local hoverAmplitude = 2
local hoverSpeed = 1
local hoverTime = 0

-- Store original positions for relative bobbing
local cloudParts = {}
for _, part in ipairs(cloudModel:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = true
		part.CanCollide = true
		table.insert(cloudParts, {
			part = part,
			originalPosition = part.Position
		})
	end
end

-- Sound
local boingSound = Instance.new("Sound")
boingSound.SoundId = "rbxassetid://5356058949"
boingSound.Volume = 0.8
boingSound.Name = "BoingSound"
boingSound.Parent = cloudModel

-- Hover bobbing (preserves part layout)
RunService.Heartbeat:Connect(function(dt)
	hoverTime += dt
	local offset = math.sin(hoverTime * hoverSpeed * math.pi * 2) * hoverAmplitude
	for _, data in ipairs(cloudParts) do
		local part = data.part
		local original = data.originalPosition
		part.Position = original + Vector3.new(0, offset, 0)
	end
end)

-- Bounce logic
local function bouncePlayer(hit)
	local character = hit.Parent
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoid or not rootPart then return end

	local player = Players:GetPlayerFromCharacter(character)
	if not player then return end

	if bounceCooldown[player] and os.clock() - bounceCooldown[player] < COOLDOWN_TIME then
		return
	end
	bounceCooldown[player] = os.clock()

	-- Closest part to base bounce on
	local closestPart = cloudParts[1].part
	local minDist = math.huge
	for _, data in ipairs(cloudParts) do
		local dist = (data.part.Position - rootPart.Position).Magnitude
		if dist < minDist then
			minDist = dist
			closestPart = data.part
		end
	end

	local awayVector = (rootPart.Position - closestPart.Position).Unit
	local bounceVector = (awayVector + Vector3.new(0, 1, 0)).Unit * BOUNCE_FORCE

	-- Apply VectorForce
	local att = Instance.new("Attachment", rootPart)
	local force = Instance.new("VectorForce")
	force.Attachment0 = att
	force.Force = bounceVector
	force.RelativeTo = Enum.ActuatorRelativeTo.World
	force.ApplyAtCenterOfMass = true
	force.Parent = rootPart

	task.delay(0.2, function()
		force:Destroy()
		att:Destroy()
	end)

	-- Feedback
	boingSound.PlaybackSpeed = math.random(8, 12) / 10
	boingSound:Play()

	for _, data in ipairs(cloudParts) do
		local emitter = data.part:FindFirstChild("CloudParticles")
		if emitter then emitter:Emit(10) end
	end

	for _, data in ipairs(cloudParts) do
		local part = data.part
		local originalSize = part.Size
		local originalColor = part.Color
		part.Color = Color3.fromRGB(115, 253, 255)

		local squash = TweenService:Create(part, TweenInfo.new(0.1), {
			Size = originalSize * Vector3.new(1.2, 0.8, 1.2)
		})
		squash:Play()
		squash.Completed:Wait()

		local restore = TweenService:Create(part, TweenInfo.new(0.2), {
			Size = originalSize,
			Color = originalColor
		})
		restore:Play()
	end

	Players.PlayerRemoving:Connect(function(leaving)
		if leaving == player then
			bounceCooldown[player] = nil
		end
	end)
end

-- Connect to .Touched
for _, data in ipairs(cloudParts) do
	data.part.Touched:Connect(bouncePlayer)
end
