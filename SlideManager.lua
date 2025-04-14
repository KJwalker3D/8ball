local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("SlideManager started")

-- Configuration
local SLIDE_SPEED = 40 -- Studs/s at max slope
local ACCELERATION = 30 -- Studs/s²
local STEERING_SPEED = 5 -- Studs/s
local SLIDE_TAG = "Slide"
local SOUND_ID = "rbxassetid://9120858323"
local PARTICLE_TEXTURE = "rbxassetid://14500233914"
local MAX_SLIDE_TIME = 5 -- Seconds
local DEBUG = false -- Toggle for stuck debugging

-- Track state
local slidingPlayers = {} -- [player] = {connection, velocity, particles, sound, speed, startTime, slidePart}

-- Get slide direction
local function getSlideDirection(part)
	local cframe = part.CFrame
	local angleY = math.rad(part.Rotation.Y)
	local slopeDir = cframe:VectorToWorldSpace(Vector3.new(0, -math.sin(angleY), -math.cos(angleY)))
	local slopeAngle = math.asin(math.clamp(-slopeDir.Y, -1, 1))
	return slopeDir.Unit, math.abs(slopeAngle)
end

-- Start sliding
local function startSliding(player, slidePart)
	if slidingPlayers[player] then return end
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then return end

	print(player.Name, "started sliding on", slidePart.Name)
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false

	-- Create LinearVelocity
	local velocity = Instance.new("LinearVelocity")
	velocity.MaxForce = math.huge
	velocity.VectorVelocity = Vector3.new(0, 0, 0)
	velocity.Attachment0 = rootPart:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", rootPart)
	velocity.Parent = rootPart

	-- Add particles
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Texture = PARTICLE_TEXTURE
	particleEmitter.Lifetime = NumberRange.new(0.3, 0.5)
	particleEmitter.Rate = 20
	particleEmitter.Speed = NumberRange.new(5, 10)
	particleEmitter.SpreadAngle = Vector2.new(30, 30)
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.5),
		NumberSequenceKeypoint.new(1, 1)
	})
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	particleEmitter.Parent = rootPart
	particleEmitter.Enabled = true

	-- Add sound
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 0.7
	sound.Looped = true
	sound.Parent = rootPart
	sound:Play()

	-- Track sliding
	slidingPlayers[player] = {
		connection = nil,
		velocity = velocity,
		particles = particleEmitter,
		sound = sound,
		speed = 0,
		startTime = tick(),
		slidePart = slidePart
	}

	-- Update velocity
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not character or not character.Parent or not slidingPlayers[player] or not humanoid.Parent then
			slidingPlayers[player] = nil
			velocity:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			print(player.Name, "stopped sliding - character gone")
			connection:Disconnect()
			return
		end

		-- Check if still sliding
		local touchingSlide = false
		local currentSlidePart = slidingPlayers[player].slidePart
		for _, part in ipairs(CollectionService:GetTagged(SLIDE_TAG)) do
			if part:IsA("BasePart") and (rootPart.Position - part.Position).Magnitude < (part.Size.Magnitude + 10) then
				touchingSlide = true
				currentSlidePart = part
				slidingPlayers[player].slidePart = part
				break
			end
		end

		-- Timeout
		if tick() - slidingPlayers[player].startTime > MAX_SLIDE_TIME then
			touchingSlide = false
		end

		if not touchingSlide then
			slidingPlayers[player] = nil
			velocity:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			print(player.Name, "stopped sliding - left slide")
			connection:Disconnect()
			return
		end

		-- Update velocity
		local slideDir, slopeAngle = getSlideDirection(currentSlidePart)
		local targetSpeed = SLIDE_SPEED * math.sin(slopeAngle)
		local currentSpeed = slidingPlayers[player].speed
		currentSpeed = math.min(currentSpeed + ACCELERATION * dt, targetSpeed)
		slidingPlayers[player].speed = currentSpeed

		-- Steering
		local inputDir = Vector3.new(0, 0, 0)
		local rightVector = currentSlidePart.CFrame:VectorToWorldSpace(Vector3.new(1, 0, 0))
		if humanoid.MoveDirection.Magnitude > 0 then
			inputDir = rightVector * humanoid.MoveDirection.X * STEERING_SPEED
		end

		velocity.VectorVelocity = (slideDir * currentSpeed + inputDir)

		-- Ground player
		local rayOrigin = rootPart.Position
		local rayDirection = Vector3.new(0, -10, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = CollectionService:GetTagged(SLIDE_TAG)
		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		if result and (rootPart.Position - result.Position).Magnitude < 5 then
			local hitPos = result.Position
			rootPart.Position = Vector3.new(rootPart.Position.X, hitPos.Y + 2, rootPart.Position.Z)
		elseif DEBUG then
			print(player.Name, "No raycast hit at", rootPart.Position)
		end

		-- Pitch shift
		sound.PlaybackSpeed = 0.8 + currentSpeed / SLIDE_SPEED * 0.4
	end)
	slidingPlayers[player].connection = connection
end

-- Stop sliding
local function stopSliding(player)
	if slidingPlayers[player] then
		print(player.Name, "stopped sliding")
		local data = slidingPlayers[player]
		if data.velocity then data.velocity:Destroy() end
		if data.particles then data.particles:Destroy() end
		if data.sound then
			data.sound:Stop()
			data.sound:Destroy()
		end
		if data.connection then data.connection:Disconnect() end
		slidingPlayers[player] = nil
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.JumpPower = 50
			player.Character.Humanoid.AutoRotate = true
		end
	end
end

-- Set up slide parts
local function setupSlidePart(slidePart)
	if slidePart:IsA("BasePart") then
		slidePart.Anchored = true
		slidePart.CanCollide = true
		CollectionService:AddTag(slidePart, SLIDE_TAG)
		print("Set up slide part:", slidePart.Name)
		slidePart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player then
				startSliding(player, slidePart)
			end
		end)
	end
end

-- Initialize slide
local slideModel = workspace:FindFirstChild("Slide")
if slideModel then
	for _, part in ipairs(slideModel:GetChildren()) do
		setupSlidePart(part)
	end
else
	print("Warning: No Slide model found in Workspace")
end

-- Handle new slide parts
CollectionService:GetInstanceAddedSignal(SLIDE_TAG):Connect(function(slidePart)
	setupSlidePart(slidePart)
end)

-- Clean up
Players.PlayerRemoving:Connect(function(player)
	stopSliding(player)
end)

workspace.ChildAdded:Connect(function(child)
	if child.Name == "Slide" and child:IsA("Model") then
		for _, part in ipairs(child:GetChildren()) do
			setupSlidePart(part)
		end
	end
end)