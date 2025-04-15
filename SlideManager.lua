local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

print("SlideManager started")

-- Configuration
local SLIDE_SPEED = 40 -- Studs/s
local SLIDE_LENGTH = 46 -- Studs (Z: -8 to -54)
local BASE_Y = 98 -- Middle Y (~95 to 103)
local WAVE_AMPLITUDE = 4 -- Y ±4 studs
local WAVE_CYCLES = 2 -- 2 waves
local Y_OFFSET = 4 -- Studs above path
local SOUND_ID = "rbxassetid://9120858323"
local PARTICLE_TEXTURE = "rbxassetid://14500233914"
local MAX_SLIDE_TIME = 10 -- Seconds
local SEAT_ANIMATION = "rbxassetid://2506281703"
local DEBUG = true -- Toggle for debugging

-- Track state
local slidingPlayers = {} -- [player] = {connection, gyro, particles, sound, animTrack, progress, speed, startTime, cameraConn}

-- Slide path function
local function getSlidePosition(t)
	t = math.clamp(t, 0, 1)
	local z = -8 - t * SLIDE_LENGTH
	local y = BASE_Y + math.sin(t * 2 * math.pi * WAVE_CYCLES) * WAVE_AMPLITUDE
	return Vector3.new(-110.514, y + Y_OFFSET, z)
end

-- Start sliding
local function startSliding(player)
	if slidingPlayers[player] then return end
	local character = player.Character
	if not character or not character:FindFirstChild("Humanoid") or not character:FindFirstChild("HumanoidRootPart") then return end

	print(player.Name, "started sliding")
	local humanoid = character.Humanoid
	local rootPart = character.HumanoidRootPart
	humanoid.JumpPower = 0
	humanoid.AutoRotate = false
	humanoid.PlatformStand = true

	-- Create BodyGyro
	local gyro = Instance.new("BodyGyro")
	gyro.MaxTorque = Vector3.new(0, math.huge, 0)
	gyro.P = 5000
	gyro.D = 500
	gyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
	gyro.Parent = rootPart

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
	particleEmitter.Rate = 40
	particleEmitter.Speed = NumberRange.new(6, 12)
	particleEmitter.SpreadAngle = Vector2.new(45, 45)
	particleEmitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.5),
		NumberSequenceKeypoint.new(1, 0)
	})
	particleEmitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0.4),
		NumberSequenceKeypoint.new(1, 1)
	})
	particleEmitter.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
	particleEmitter.Parent = rootPart
	particleEmitter.Enabled = true

	-- Add sound
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 1
	sound.Looped = true
	sound.Parent = rootPart
	sound:Play()

	-- Lock camera
	local camera = workspace.CurrentCamera
	local cameraConn
	if player == Players.LocalPlayer then
		camera.CameraType = Enum.CameraType.Scriptable
		cameraConn = RunService.RenderStepped:Connect(function()
			if not slidingPlayers[player] then return end
			local pos = rootPart.Position
			camera.CFrame = CFrame.new(pos + Vector3.new(0, 2, 5), pos)
		end)
	end

	-- Track sliding
	slidingPlayers[player] = {
		connection = nil,
		gyro = gyro,
		particles = particleEmitter,
		sound = sound,
		animTrack = animTrack,
		progress = 0,
		speed = SLIDE_SPEED,
		startTime = tick(),
		cameraConn = cameraConn
	}

	-- Update position
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not character or not character.Parent or not slidingPlayers[player] or not humanoid.Parent then
			slidingPlayers[player] = nil
			gyro:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			animTrack:Stop()
			if cameraConn then cameraConn:Disconnect() end
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
			camera.CameraType = Enum.CameraType.Custom
			print(player.Name, "stopped sliding - character gone")
			connection:Disconnect()
			return
		end

		-- Update progress
		local currentSpeed = slidingPlayers[player].speed
		local progress = slidingPlayers[player].progress + (currentSpeed / SLIDE_LENGTH) * dt

		-- End slide
		if progress >= 1 then
			local exitPos = getSlidePosition(1)
			slidingPlayers[player] = nil
			rootPart.Position = exitPos
			rootPart.Velocity = Vector3.new(0, 0, -currentSpeed)
			gyro:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			animTrack:Stop()
			if cameraConn then cameraConn:Disconnect() end
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
			camera.CameraType = Enum.CameraType.Custom
			print(player.Name, "stopped sliding - reached end")
			connection:Disconnect()
			return
		end

		-- Timeout
		if tick() - slidingPlayers[player].startTime > MAX_SLIDE_TIME then
			local exitPos = getSlidePosition(progress)
			slidingPlayers[player] = nil
			rootPart.Position = exitPos
			rootPart.Velocity = Vector3.new(0, 0, -currentSpeed)
			gyro:Destroy()
			particleEmitter:Destroy()
			sound:Stop()
			sound:Destroy()
			animTrack:Stop()
			if cameraConn then cameraConn:Disconnect() end
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
			camera.CameraType = Enum.CameraType.Custom
			print(player.Name, "stopped sliding - timeout")
			connection:Disconnect()
			return
		end

		-- Set position
		slidingPlayers[player].progress = progress
		local pos = getSlidePosition(progress)
		rootPart.Position = pos
		if DEBUG then
			print(player.Name, "progress:", progress, "speed:", currentSpeed, "pos:", pos)
		end

		-- Pitch shift
		sound.PlaybackSpeed = 0.9 + (currentSpeed / SLIDE_SPEED) * 0.8
	end)
	slidingPlayers[player].connection = connection
end

-- Stop sliding
local function stopSliding(player)
	if slidingPlayers[player] then
		print(player.Name, "stopped sliding")
		local data = slidingPlayers[player]
		if data.gyro then data.gyro:Destroy() end
		if data.particles then data.particles:Destroy() end
		if data.sound then
			data.sound:Stop()
			data.sound:Destroy()
		end
		if data.animTrack then data.animTrack:Stop() end
		if data.connection then data.connection:Disconnect() end
		if data.cameraConn then data.cameraConn:Disconnect() end
		slidingPlayers[player] = nil
		if player.Character and player.Character:FindFirstChild("Humanoid") then
			player.Character.Humanoid.JumpPower = 50
			player.Character.Humanoid.AutoRotate = true
			player.Character.Humanoid.PlatformStand = false
		end
		if player == Players.LocalPlayer then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end
end

-- Set up slide
local function setupSlide()
	local slideModel = workspace:FindFirstChild("Slide")
	if not slideModel then
		print("Warning: No Slide model found in Workspace")
		return
	end

	-- Find or create StartZone
	local startZone = slideModel:FindFirstChild("StartZone")
	if not startZone then
		startZone = Instance.new("Part")
		startZone.Name = "StartZone"
		startZone.Size = Vector3.new(30, 5, 4)
		startZone.Position = Vector3.new(-110.514, 107, 7)
		startZone.Anchored = true
		startZone.CanCollide = true
		startZone.Transparency = 0.5
		startZone.Parent = slideModel
		print("Created StartZone at", startZone.Position)
	end

	-- Tag slide part
	local slidePart = slideModel:FindFirstChild("Slide")
	if slidePart and slidePart:IsA("BasePart") then
		slidePart.Anchored = true
		slidePart.CanCollide = true
		CollectionService:AddTag(slidePart, "Slide")
		print("Set up slide part:", slidePart.Name)
	end

	-- Connect StartZone touch
	startZone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			startSliding(player)
		end
	end)
end

-- Initialize
setupSlide()

-- Handle new slides
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Slide" and child:IsA("Model") then
		setupSlide()
	end
end)

-- Clean up
Players.PlayerRemoving:Connect(function(player)
	stopSliding(player)
end)