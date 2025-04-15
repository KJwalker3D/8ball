local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- Added for sound fade

print("SlideManager started")

-- Configuration
local SLIDE_SPEED = 40 -- Studs/s
local SLIDE_LENGTH = 46 -- Studs (Z: -8 to -54)
local BASE_Y = 98 -- Middle Y (~95 to 103)
local WAVE_AMPLITUDE = 4 -- Y ±4 studs
local WAVE_CYCLES = 2 -- 2 waves
local Y_OFFSET = 4 -- Studs above path
local SOUND_ID = "rbxassetid://136877968528580"
local MAX_SLIDE_TIME = 10 -- Seconds
local SEAT_ANIMATION = "rbxassetid://2506281703"
local DEBUG = true -- Toggle for debugging
local SOUND_FADE_DURATION = 0.5 -- Seconds for sound fade-out

-- Remote event for client
local slideEvent = Instance.new("RemoteEvent")
slideEvent.Name = "SlideEffectEvent"
slideEvent.Parent = ReplicatedStorage

-- Track state
local slidingPlayers = {} -- [player] = {connection, gyro, particles, sound, animTrack, progress, speed, startTime, cameraConn}

-- Slide path function
local function getSlidePosition(t)
	t = math.clamp(t, 0, 1)
	local z = -8 - t * SLIDE_LENGTH
	local y = BASE_Y + math.sin(t * 2 * math.pi * WAVE_CYCLES) * WAVE_AMPLITUDE
	return Vector3.new(-110.514, y + Y_OFFSET, z)
end

-- Stop sliding
local function stopSliding(player)
	if slidingPlayers[player] then
		print(player.Name, "stopped sliding")
		local data = slidingPlayers[player]
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

		-- Fade out sound
		if data.sound then
			local fadeTween = TweenService:Create(
				data.sound,
				TweenInfo.new(SOUND_FADE_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
				{Volume = 0}
			)
			fadeTween:Play()
			fadeTween.Completed:Connect(function()
				data.sound:Stop()
				data.sound:Destroy()
				print("Sound faded out for", player.Name)
			end)
		end

		-- Cleanup other components
		if data.gyro then data.gyro:Destroy() end
		if data.animTrack then data.animTrack:Stop() end
		if data.connection then data.connection:Disconnect() end
		slidingPlayers[player] = nil
		slideEvent:FireClient(player, false)

		-- Reset humanoid
		if humanoid then
			humanoid.JumpPower = 50
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
		end

		-- Reset camera
		if player == Players.LocalPlayer then
			workspace.CurrentCamera.CameraType = Enum.CameraType.Custom
		end
	end
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

	-- Add sound
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 1
	sound.Looped = true
	sound.Parent = rootPart
	sound:Play()

	-- Notify the client
	slideEvent:FireClient(player, true, SLIDE_SPEED)

	-- Track sliding
	slidingPlayers[player] = {
		connection = nil,
		gyro = gyro,
		sound = sound,
		animTrack = animTrack,
		progress = 0,
		speed = SLIDE_SPEED,
		startTime = tick()
	}

	-- Update position
	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not character or not character.Parent or not slidingPlayers[player] or not humanoid.Parent then
			stopSliding(player)
			print(player.Name, "stopped sliding - character gone")
			return
		end

		-- Update progress
		local currentSpeed = slidingPlayers[player].speed
		local progress = slidingPlayers[player].progress + (currentSpeed / SLIDE_LENGTH) * dt

		-- End slide
		if progress >= 1 then
			local exitPos = getSlidePosition(1)
			rootPart.Position = exitPos
			rootPart.Velocity = Vector3.new(0, 0, -currentSpeed)
			stopSliding(player)
			print(player.Name, "stopped sliding - reached end")
			return
		end

		-- Timeout
		if tick() - slidingPlayers[player].startTime > MAX_SLIDE_TIME then
			local exitPos = getSlidePosition(progress)
			rootPart.Position = exitPos
			rootPart.Velocity = Vector3.new(0, 0, -currentSpeed)
			stopSliding(player)
			print(player.Name, "stopped sliding - timeout")
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
		sound.PlaybackSpeed = 1
	end)
	slidingPlayers[player].connection = connection
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
		startZone.Size = Vector3.new(33, 7, 7)
		startZone.Position = Vector3.new(-110.514, 107, 10)
		startZone.Anchored = true
		startZone.CanCollide = true
		startZone.Transparency = 1
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