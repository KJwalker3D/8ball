local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("SlideManager started")

-- Configuration
local SLIDE_SPEED = 40 -- Studs/s
local MIN_SPEED = 10 -- Studs/s minimum
local ACCELERATION = 15 -- Studs/s²
local SLIDE_TAG = "Slide"
local SOUND_ID = "rbxassetid://9120858323"
local PARTICLE_TEXTURE = "rbxassetid://14500233914"
local MAX_SLIDE_TIME = 5 -- Seconds
local EXIT_DEBOUNCE = 1 -- Seconds
local SEAT_ANIMATION = "rbxassetid://2506281703" -- Default seated
local DEBUG = true -- Toggle for debugging

-- Track state
local slidingPlayers = {} -- [player] = {connection, velocity, orientation, particles, sound, animTrack, speed, startTime, slidePart, exitTime}

-- Get slide direction
local function getSlideDirection(part)
	local cframe = part.CFrame
	local lookVector = cframe.LookVector -- Try +LookVector for downward
	local slopeDir = Vector3.new(lookVector.X, lookVector.Y, lookVector.Z)
	if slopeDir.Y > -0.1 then -- Force downward if near-flat
		slopeDir = (slopeDir - Vector3.new(0, slopeDir.Y, 0)) - Vector3.new(0, 0.5, 0)
	end
	slopeDir = slopeDir.Unit
	local slopeAngle = math.acos(math.clamp(-slopeDir.Y, -1, 1))
	if DEBUG then
		print("Slide", part.Name, "LookVector:", cframe.LookVector, "dir:", slopeDir, "angle:", math.deg(slopeAngle))
	end
	return slopeDir, math.max(slopeAngle, math.rad(10))
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
	humanoid.PlatformStand = true

	-- Create BodyVelocity
	local velocity = Instance.new("BodyVelocity")
	velocity.MaxForce = Vector3.new(math.huge, 0, math.huge)
	velocity.P = 5000
	velocity.Velocity = Vector3.new(0, 0, 0)
	velocity.Parent = rootPart

	-- Create AlignOrientation
	local orientation = Instance.new("AlignOrientation")
	orientation.Mode = Enum.OrientationAlignmentMode.OneAttachment
	orientation.MaxTorque = math.huge
	orientation.Responsiveness = 50
	orientation.PrimaryAxis = Vector3.new(0, 0, 1)
	orientation.SecondaryAxis = Vector3.new(0, 1, 0)
	orientation.CFrame = CFrame.new(Vector3.new(0, 0, 0), slidePart.CFrame.LookVector)
	orientation.Attachment0 = rootPart:FindFirstChildOfClass("Attachment") or Instance.new("Attachment", rootPart)
	orientation.Parent = rootPart

	-- Play seated animation
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = SEAT_ANIMATION
	local animTrack = animator:LoadAnimation(animation)
	animTrack:Play()

	-- Add particles
	local particleEmitter = Instance.new("ParticleEmitter")
	particleEmitter.Texture = PARTICLE_TEXTURE
	particleEmitter.Lifetime = NumberRange.new(0.4, 0.6)
	particleEmitter.Rate = 25
	particleEmitter.Speed = NumberRange.new(6, 12)
	particleEmitter.SpreadAngle = Vector2.new(45, 45)
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.6),
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
		orientation = orientation,
		particles = particleEmitter,
		sound = sound,
		animTrack = animTrack,
		speed = 0,
		startTime = tick(),
		slidePart = slidePart,
		exitTime = nil
	}

	-- Update velocity
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not character or not character.Parent or not slidingPlayers[player] or not humanoid.Parent then
			slidingPlayers[player] = nil
			velocity:Destroy()
			orientation:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			animTrack:Stop()
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
			print(player.Name, "stopped sliding - character gone")
			connection:Disconnect()
			return
		end

		-- Find closest slide part
		local slideModel = workspace:FindFirstChild("Slide")
		if not slideModel then
			slidingPlayers[player].exitTime = tick()
		end
		local touchingSlide = false
		local currentSlidePart = slidingPlayers[player].slidePart
		local slideCFrame, slideSize = slideModel:GetBoundingBox()
		if (rootPart.Position - slideCFrame.Position).Magnitude < (slideSize.Magnitude / 2 + 10) then
			local rayOrigin = rootPart.Position
			local rayDirection = Vector3.new(0, -15, 0)
			local raycastParams = RaycastParams.new()
			raycastParams.FilterType = Enum.RaycastFilterType.Include
			raycastParams.FilterDescendantsInstances = CollectionService:GetTagged(SLIDE_TAG)
			local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
			if result then
				touchingSlide = true
				for _, part in ipairs(CollectionService:GetTagged(SLIDE_TAG)) do
					if part == result.Instance then
						currentSlidePart = part
						slidingPlayers[player].slidePart = part
						break
					end
				end
			end
		end

		-- Debounce exit
		if not touchingSlide then
			if not slidingPlayers[player].exitTime then
				slidingPlayers[player].exitTime = tick()
			end
			if tick() - slidingPlayers[player].exitTime < EXIT_DEBOUNCE then
				touchingSlide = true
			end
		else
			slidingPlayers[player].exitTime = nil
		end

		-- Timeout
		if tick() - slidingPlayers[player].startTime > MAX_SLIDE_TIME then
			touchingSlide = false
		end

		if not touchingSlide then
			local exitSpeed = slidingPlayers[player].speed
			local exitDir = currentSlidePart.CFrame.LookVector
			slidingPlayers[player] = nil
			rootPart.Velocity = exitDir * exitSpeed * 0.7
			velocity:Destroy()
			orientation:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			animTrack:Stop()
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
			print(player.Name, "stopped sliding - left slide")
			connection:Disconnect()
			return
		end

		-- Update velocity
		local slideDir, slopeAngle = getSlideDirection(currentSlidePart)
		local targetSpeed = math.max(MIN_SPEED, SLIDE_SPEED * math.sin(slopeAngle))
		local currentSpeed = slidingPlayers[player].speed
		currentSpeed = math.min(currentSpeed + ACCELERATION * dt, targetSpeed)
		slidingPlayers[player].speed = currentSpeed

		velocity.Velocity = slideDir * currentSpeed
		orientation.CFrame = CFrame.new(Vector3.new(0, 0, 0), slideDir)
		if DEBUG then
			print(player.Name, "speed:", currentSpeed, "velocity:", velocity.Velocity)
		end

		-- Ground player
		local rayOrigin = rootPart.Position
		local rayDirection = Vector3.new(0, -15, 0)
		local raycastParams = RaycastParams.new()
		raycastParams.FilterType = Enum.RaycastFilterType.Include
		raycastParams.FilterDescendantsInstances = CollectionService:GetTagged(SLIDE_TAG)
		local result = workspace:Raycast(rayOrigin, rayDirection, raycastParams)
		if result and (rootPart.Position - result.Position).Magnitude < 5 then
			local hitPos = result.Position
			rootPart.Position = Vector3.new(rootPart.Position.X, hitPos.Y + 2, rootPart.Position.Z)
		elseif DEBUG then
			print(player.Name, "No grounding at", rootPart.Position, "speed:", currentSpeed)
		end

		-- Pitch shift
		sound.PlaybackSpeed = 0.8 + currentSpeed / SLIDE_SPEED * 0.6
	end)
	slidingPlayers[player].connection = connection
end

-- Stop sliding
local function stopSliding(player)
	if slidingPlayers[player] then
		print(player.Name, "stopped sliding")
		local data = slidingPlayers[player]
		if data.velocity then data.velocity:Destroy() end
		if data.orientation then data.orientation:Destroy() end
		if data.particles then data.particles:Destroy() end
		if data.sound then
			data.sound:Stop()
			data.sound:Destroy()
		end
		if data.animTrack then data.animTrack:Stop() end
		if data.connection then data.connection:Disconnect() end
		slidingPlayers[player] = nil
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.JumpPower = 50
			player.Character.Humanoid.AutoRotate = true
			player.Character.Humanoid.PlatformStand = false
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