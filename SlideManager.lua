local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("SlideManager started")

-- Configuration
local SLIDE_SPEED = 255 -- Studs/s
local WAVE_AMPLITUDE = 4
local WAVE_CYCLES = 2
local Y_OFFSET = 0
local CAMERA_OFFSET = Vector3.new(0, 0, 0) -- Higher offset to avoid camera clipping
local SOUND_ID = "rbxassetid://136877968528580"
local MAX_SLIDE_TIME = 9
local SEAT_ANIMATION = "rbxassetid://2506281703"
local DEBUG = true
local SOUND_FADE_DURATION = 0.5

-- Remote event for client
local slideEvent = Instance.new("RemoteEvent")
slideEvent.Name = "SlideEffectEvent"
slideEvent.Parent = ReplicatedStorage

-- Track state
local slidingPlayers = {}

-- Slide path info
local slidePart
local slideStartPos
local slideEndPos
local slideDirection

-- Slide path function
local function getSlidePosition(t)
	t = math.clamp(t, 0, 1)
	local basePos = slideStartPos:Lerp(slideEndPos, t)
	local waveOffsetY = math.sin(t * 2 * math.pi * WAVE_CYCLES) * WAVE_AMPLITUDE
	return basePos + Vector3.new(0, waveOffsetY + Y_OFFSET, 0) + CAMERA_OFFSET
end

local function stopSliding(player)
	if slidingPlayers[player] then
		print(player.Name, "stopped sliding")
		local data = slidingPlayers[player]
		local humanoid = player.Character and player.Character:FindFirstChild("Humanoid")

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
			end)
		end

		if data.gyro then data.gyro:Destroy() end
		if data.animTrack then data.animTrack:Stop() end
		if data.connection then data.connection:Disconnect() end
		slidingPlayers[player] = nil
		slideEvent:FireClient(player, false)

		if humanoid then
			humanoid.JumpPower = 75
			humanoid.AutoRotate = true
			humanoid.PlatformStand = false
		end
	end
end

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

	local gyro = Instance.new("BodyGyro")
	gyro.MaxTorque = Vector3.new(0, math.huge, 0)
	gyro.P = 5000
	gyro.D = 500
	gyro.CFrame = CFrame.new(Vector3.new(0, 0, 0), Vector3.new(0, 0, -1))
	gyro.Parent = rootPart

	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator", humanoid)
	local animation = Instance.new("Animation")
	animation.AnimationId = SEAT_ANIMATION
	local animTrack = animator:LoadAnimation(animation)
	animTrack:Play()

	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 1
	sound.Looped = true
	sound.Parent = rootPart
	sound:Play()

	slideEvent:FireClient(player, true, SLIDE_SPEED)

	slidingPlayers[player] = {
		connection = nil,
		gyro = gyro,
		sound = sound,
		animTrack = animTrack,
		progress = 0.01,
		speed = SLIDE_SPEED,
		startTime = tick()
	}

	local connection
	connection = RunService.Heartbeat:Connect(function(dt)
		if not character or not character.Parent or not slidingPlayers[player] or not humanoid.Parent then
			stopSliding(player)
			return
		end

		local slideLength = (slideEndPos - slideStartPos).Magnitude
		local currentSpeed = slidingPlayers[player].speed
		local progress = slidingPlayers[player].progress + (currentSpeed / slideLength) * dt

		if progress >= 1 then
			rootPart.Position = getSlidePosition(1)
			rootPart.Velocity = Vector3.new(0, 0, -currentSpeed)
			stopSliding(player)
			return
		end

		if tick() - slidingPlayers[player].startTime > MAX_SLIDE_TIME then
			rootPart.Position = getSlidePosition(progress)
			rootPart.Velocity = Vector3.new(0, 0, -currentSpeed)
			stopSliding(player)
			return
		end

		slidingPlayers[player].progress = progress
		local pos = getSlidePosition(progress)
		rootPart.Position = pos
		sound.PlaybackSpeed = 1
		if DEBUG then
			print(player.Name, "progress:", progress, "pos:", pos)
		end
	end)
	slidingPlayers[player].connection = connection
end

local function setupSlide()
	local slideModel = workspace:FindFirstChild("Slide")
	if not slideModel then
		print("Warning: No Slide model found in Workspace")
		return
	end

	local startZone = slideModel:FindFirstChild("StartZone")
	if not startZone then
		startZone = Instance.new("Part")
		startZone.Name = "StartZone"
		startZone.Size = Vector3.new(168, 3, 34)
		startZone.Position = Vector3.new(-666.696, 180.218, 699.938)
		startZone.Anchored = true
		startZone.CanCollide = true
		startZone.Transparency = 1
		startZone.Parent = slideModel
		print("Created StartZone at", startZone.Position)
	end

	slidePart = slideModel:FindFirstChild("Slide")
	if slidePart and slidePart:IsA("BasePart") then
		slidePart.Anchored = true
		slidePart.CanCollide = true
		CollectionService:AddTag(slidePart, "Slide")
		print("Set up slide part:", slidePart.Name)

		local cframe = slidePart.CFrame
		local length = slidePart.Size.Z
		slideDirection = -cframe.LookVector
		slideStartPos = Vector3.new(-666.696, 180.218, 699.938)
		slideEndPos = cframe.Position - slideDirection * (length / 2)
	end

	startZone.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			startSliding(player)
		end
	end)
end

setupSlide()

workspace.ChildAdded:Connect(function(child)
	if child.Name == "Slide" and child:IsA("Model") then
		setupSlide()
	end
end)

Players.PlayerRemoving:Connect(function(player)
	stopSliding(player)
end)