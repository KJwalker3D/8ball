local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("FloatingBlockManager started")

-- Create RemoteEvent for coin updates
local CoinUpdateEvent = Instance.new("RemoteEvent")
CoinUpdateEvent.Name = "CoinUpdateEvent"
CoinUpdateEvent.Parent = ReplicatedStorage

-- Configuration
local CONFIG = {
	-- Animation Settings
	SINK_DISTANCE = 2.5, -- Studs to sink
	SINK_TIME = 1, -- Seconds to sink
	POP_TIME = 1, -- Seconds to pop up
	SOUND_FADE_DURATION = 1, -- Seconds for sound fade-out
	TOUCH_ENDED_DEBOUNCE = 0.7, -- Seconds to verify player left

	-- Floating Effect Settings
	FLOAT_AMPLITUDE = {min = 0.3, max = 0.8}, -- Studs up and down (increased for more movement)
	FLOAT_SPEED = {min = 0.5, max = 1.2}, -- Cycles per second (increased for more movement)
	FLOAT_PHASE_OFFSET = {min = 0, max = 2 * math.pi}, -- Random phase offset
	FLOAT_UPDATE_INTERVAL = 0.1, -- Seconds between updates (10 FPS for smoother movement)

	-- Coin Settings
	COIN_REWARD = 1, -- Coins per collection
	COIN_COOLDOWN = 30, -- Seconds between coin spawns
	COIN_LIFETIME = 10, -- Seconds before coin disappears
	COIN_SPAWN_HEIGHT = 20, -- Studs above block
	COIN_SIZE = Vector3.new(2, 2, 2), -- Size of the coin
	COIN_MATERIAL = Enum.Material.Neon, -- Material of the coin
	COIN_COLOR = Color3.fromRGB(255, 215, 0), -- Gold color
	COIN_SOUND_VOLUME = 1, -- Volume of collection sound
	COIN_SOUND_ID = "rbxassetid://607665037",
	COIN_PARTICLES_ID = "rbxassetid://18699497367",

	-- Coin Notification Settings
	COIN_NOTIFICATION_DURATION = 2, -- Seconds to show notification
	COIN_NOTIFICATION_COLOR = Color3.fromRGB(255, 215, 0), -- Gold color
	COIN_NOTIFICATION_SIZE = UDim2.new(0, 200, 0, 50), -- Size of notification
	COIN_NOTIFICATION_TEXT = "+1 Coin!", -- Text to display
	COIN_NOTIFICATION_FONT = Enum.Font.GothamBold, -- Font style
	COIN_NOTIFICATION_TEXT_SIZE = 24, -- Font size

	-- Coin Particle Settings
	COIN_PARTICLE_RATE = 10, -- Particles per second
	COIN_PARTICLE_LIFETIME = {min = 1, max = 2}, -- Seconds
	COIN_PARTICLE_SPEED = {min = 2, max = 4}, -- Studs per second
	COIN_PARTICLE_SPREAD = Vector2.new(90, 90), -- Degrees
	COIN_PARTICLE_SIZE = {
		{time = 0, size = 0.5},
		{time = 0.5, size = 0.3},
		{time = 1, size = 0.1}
	},
	COIN_PARTICLE_TRANSPARENCY = {
		{time = 0, transparency = 0},
		{time = 0.5, transparency = 0.5},
		{time = 1, transparency = 1}
	},

	-- Animation Easing
	SINK_EASING_STYLE = Enum.EasingStyle.Quad,
	SINK_EASING_DIRECTION = Enum.EasingDirection.Out,
	POP_EASING_STYLE = Enum.EasingStyle.Back,
	POP_EASING_DIRECTION = Enum.EasingDirection.Out,

	-- Performance Settings
	MAX_CONCURRENT_TWEENS = 50, -- Increased from 10 to 50
	TWEEN_CLEANUP_INTERVAL = 30, -- Seconds between cleanup of old tweens
	DEBUG_MODE = false, -- Enable/disable debug prints

	-- Touch Settings
	TOUCH_DEBOUNCE_TIME = 0.05, -- Reduced from 0.1 to 0.05 seconds

	-- Visual Settings
	PARTICLE_COUNT = 50, -- Particles on pop
	SHOW_TRIGGER_ZONES = false, -- Toggle for debugging
	HIGHLIGHT_TRANSPARENCY = 0.7,
	HIGHLIGHT_COLOR = Color3.new(1, 0, 0),

	-- Sound Settings
	SINK_SOUND_ID = "rbxassetid://9120858323",
	SINK_SOUND_VOLUME = 0.5,

	-- Particle Settings
	PARTICLE_TEXTURE = "rbxassetid://14500233914",
	PARTICLE_LIFETIME = {min = 1, max = 2},
	PARTICLE_SPEED = {min = 5, max = 10},
	PARTICLE_SPREAD = Vector2.new(90, 90),
	PARTICLE_SIZE = {
		{time = 0, size = 3},
		{time = 1, size = 6}
	},
	PARTICLE_TRANSPARENCY = {
		{time = 0, transparency = 0},
		{time = 0.5, transparency = 0.5},
		{time = 1, transparency = 1}
	},
	PARTICLE_COLOR = Color3.fromRGB(255, 255, 255),

	-- Error Handling
	MAX_SETUP_RETRIES = 3,
	SETUP_RETRY_DELAY = 0.5
}

-- Track state
local originalPositions = {} -- [part] = Y
local blockStates = {} -- [blockModel] = {isSunk, isAnimating, touchingPlayers, touchConnections, highlight}
local activeTweens = {} -- [part] = tween
local taggedBlocks = {} -- Track valid blocks
local tweenCount = 0 -- Track number of active tweens
local coinCooldowns = {} -- [blockModel] = lastSpawnTime
local floatStates = {} -- [blockModel] = {amplitude, speed, phase, time}
local floatConnection = nil -- Single connection for all blocks

-- Performance monitoring
local function debugPrint(...)
	if CONFIG.DEBUG_MODE then
		print(...)
	end
end

-- Utility Functions
local function createSound(parent, soundId, volume)
	local sound = Instance.new("Sound")
	sound.Name = "SinkSound"
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = parent
	return sound
end

local function createParticleEmitter(parent, config)
	local particles = Instance.new("ParticleEmitter")
	particles.Name = "PopParticles"
	particles.Texture = config.PARTICLE_TEXTURE
	particles.Lifetime = NumberRange.new(config.PARTICLE_LIFETIME.min, config.PARTICLE_LIFETIME.max)
	particles.Rate = 0
	particles.Speed = NumberRange.new(config.PARTICLE_SPEED.min, config.PARTICLE_SPEED.max)
	particles.SpreadAngle = config.PARTICLE_SPREAD

	-- Convert size sequence
	local sizeKeypoints = {}
	for _, point in ipairs(config.PARTICLE_SIZE) do
		table.insert(sizeKeypoints, NumberSequenceKeypoint.new(point.time, point.size))
	end
	particles.Size = NumberSequence.new(sizeKeypoints)

	-- Convert transparency sequence
	local transparencyKeypoints = {}
	for _, point in ipairs(config.PARTICLE_TRANSPARENCY) do
		table.insert(transparencyKeypoints, NumberSequenceKeypoint.new(point.time, point.transparency))
	end
	particles.Transparency = NumberSequence.new(transparencyKeypoints)

	particles.Color = ColorSequence.new(config.PARTICLE_COLOR)
	particles.Enabled = false
	particles.Parent = parent
	return particles
end

local function createHighlight(blockModel)
	local highlight = Instance.new("Highlight")
	highlight.Name = "TriggerZone"
	highlight.Adornee = blockModel
	highlight.FillColor = CONFIG.HIGHLIGHT_COLOR
	highlight.FillTransparency = CONFIG.HIGHLIGHT_TRANSPARENCY
	highlight.OutlineColor = CONFIG.HIGHLIGHT_COLOR
	highlight.OutlineTransparency = 0
	highlight.Parent = blockModel
	return highlight
end

local function safeExecute(func, ...)
	local success, result = pcall(func, ...)
	if not success then
		warn("Error in safeExecute:", result)
		return nil
	end
	return result
end

-- Initialize floating effect
local function initFloatingEffect()
	if floatConnection then return end
	
	floatConnection = game:GetService("RunService").Heartbeat:Connect(function(dt)
		for blockModel, state in pairs(floatStates) do
			if blockModel and blockModel.Parent and not blockStates[blockModel].isAnimating then
				state.time = state.time + dt
				local offset = math.sin(state.time * state.speed + state.phase) * state.amplitude
				
				-- Only update the primary part for better performance
				local primaryPart = blockModel.PrimaryPart
				if primaryPart then
					local originalY = originalPositions[primaryPart]
					if originalY then
						-- Store the current position
						local currentPos = primaryPart.Position
						-- Update the position with the floating offset
						primaryPart.Position = Vector3.new(
							currentPos.X,
							originalY + offset,
							currentPos.Z
						)
						debugPrint("Block", blockModel.Name, "floating to Y =", originalY + offset)
					end
				end
			end
		end
	end)
end

-- Animate block
local function animateBlock(blockModel, targetOffsetY, force)
	if blockStates[blockModel].isAnimating and not force then
		debugPrint("Skipping animation for", blockModel.Name, "- already animating")
		return
	end

	-- Check tween limit
	if tweenCount >= CONFIG.MAX_CONCURRENT_TWEENS then
		debugPrint("Tween limit reached, waiting for cleanup")
		task.wait(0.1)
		return animateBlock(blockModel, targetOffsetY, force)
	end

	blockStates[blockModel].isAnimating = true
	debugPrint("Animating", blockModel.Name, "to offset Y =", targetOffsetY)

	local parts = {}
	for _, part in ipairs(blockModel:GetChildren()) do
		if part:IsA("BasePart") then
			table.insert(parts, part)
		end
	end

	if #parts == 0 then
		debugPrint("No BaseParts in", blockModel.Name, "- aborting animation")
		blockStates[blockModel].isAnimating = nil
		return
	end

	if #parts ~= 2 then
		debugPrint("Warning:", blockModel.Name, "has", #parts, "BaseParts, expected 2")
	end

	for _, part in ipairs(parts) do
		if not originalPositions[part] then
			originalPositions[part] = part.Position.Y
			debugPrint("Stored original Y =", originalPositions[part], "for", part.Name)
		end

		local targetY = originalPositions[part] + targetOffsetY
		debugPrint("Tweening", part.Name, "from Y =", part.Position.Y, "to Y =", targetY)

		if activeTweens[part] then
			activeTweens[part]:Cancel()
			activeTweens[part] = nil
			tweenCount = tweenCount - 1
			debugPrint("Canceled existing tween for", part.Name)
		end

		-- Select easing based on direction
		local easingStyle = targetOffsetY < 0 and CONFIG.SINK_EASING_STYLE or CONFIG.POP_EASING_STYLE
		local easingDirection = targetOffsetY < 0 and CONFIG.SINK_EASING_DIRECTION or CONFIG.POP_EASING_DIRECTION

		local tweenInfo = TweenInfo.new(
			targetOffsetY < 0 and CONFIG.SINK_TIME or CONFIG.POP_TIME,
			easingStyle,
			easingDirection
		)

		local tween = TweenService:Create(
			part,
			tweenInfo,
			{CFrame = CFrame.new(part.Position.X, targetY, part.Position.Z) * part.CFrame.Rotation}
		)

		activeTweens[part] = tween
		tweenCount = tweenCount + 1

		local startTime = tick()
		tween:Play()
		tween.Completed:Connect(function(status)
			local duration = tick() - startTime
			debugPrint("Tween completed for", part.Name, "at Y =", part.Position.Y, "status:", status, "duration:", duration)
			if activeTweens[part] == tween then
				activeTweens[part] = nil
				tweenCount = tweenCount - 1
			end

			-- Check if all parts done
			local allDone = true
			for _, p in ipairs(parts) do
				if activeTweens[p] then
					allDone = false
					break
				end
			end

			if allDone then
				blockStates[blockModel].isAnimating = nil
				debugPrint("All animations done for", blockModel.Name)
			end

			-- Fallback if tween fails
			if math.abs(part.Position.Y - targetY) > 0.1 then
				debugPrint("Forcing Y =", targetY, "for", part.Name)
				part.CFrame = CFrame.new(part.Position.X, targetY, part.Position.Z) * part.CFrame.Rotation
			end
		end)
	end
end

-- Pop block up
local function popBlock(blockModel)
	if not blockStates[blockModel].isSunk then
		return
	end
	print("Popping up", blockModel.Name)
	blockStates[blockModel].isSunk = false
	blockStates[blockModel].touchingPlayers = {}
	animateBlock(blockModel, 0, true)
	if blockModel.PrimaryPart then
		local particles = blockModel.PrimaryPart:FindFirstChild("ParticleAttachment")
		if particles and particles:FindFirstChild("PopParticles") then
			particles.PopParticles:Emit(CONFIG.PARTICLE_COUNT)
			print("Emitted", CONFIG.PARTICLE_COUNT, "particles for", blockModel.Name)
		end
	end
end

-- Cleanup block
local function cleanupBlock(blockModel)
	if not blockModel then return end

	-- Cleanup floating state
	floatStates[blockModel] = nil

	-- Cleanup connection if no blocks left
	if floatConnection and next(floatStates) == nil then
		floatConnection:Disconnect()
		floatConnection = nil
	end

	-- Cleanup connections
	if blockStates[blockModel] then
		for _, conn in ipairs(blockStates[blockModel].touchConnections) do
			conn:Disconnect()
		end

		-- Cleanup highlight
		if blockStates[blockModel].highlight then
			blockStates[blockModel].highlight:Destroy()
		end
	end

	-- Cleanup sound and particles
	if blockModel.PrimaryPart then
		local sound = blockModel.PrimaryPart:FindFirstChild("SinkSound")
		if sound then
			sound:Destroy()
		end

		local attachment = blockModel.PrimaryPart:FindFirstChild("ParticleAttachment")
		if attachment then
			attachment:Destroy()
		end
	end

	-- Cleanup tweens
	for _, part in ipairs(blockModel:GetChildren()) do
		if part:IsA("BasePart") and activeTweens[part] then
			activeTweens[part]:Cancel()
			activeTweens[part] = nil
		end
	end

	-- Cleanup state
	blockStates[blockModel] = nil
	for _, part in ipairs(blockModel:GetChildren()) do
		if part:IsA("BasePart") then
			originalPositions[part] = nil
		end
	end

	-- Remove from tagged blocks
	for i, taggedBlock in ipairs(taggedBlocks) do
		if taggedBlock == blockModel then
			table.remove(taggedBlocks, i)
			break
		end
	end
end

-- Coin Functions
local function createCoin(blockModel)
	local coin = Instance.new("Part")
	coin.Name = "CollectibleCoin"
	coin.Shape = Enum.PartType.Cylinder
	coin.Size = CONFIG.COIN_SIZE
	coin.CanCollide = false
	coin.Anchored = true
	coin.Material = CONFIG.COIN_MATERIAL
	coin.Color = CONFIG.COIN_COLOR

	-- Position coin above block
	local blockPos = blockModel.PrimaryPart.Position
	coin.CFrame = CFrame.new(blockPos.X, blockPos.Y + CONFIG.COIN_SPAWN_HEIGHT, blockPos.Z)

	-- Add particles
	local attachment = Instance.new("Attachment")
	attachment.Parent = coin

	local particles = Instance.new("ParticleEmitter")
	particles.Texture = CONFIG.COIN_PARTICLES_ID
	particles.Lifetime = NumberRange.new(CONFIG.COIN_PARTICLE_LIFETIME.min, CONFIG.COIN_PARTICLE_LIFETIME.max)
	particles.Rate = CONFIG.COIN_PARTICLE_RATE
	particles.Speed = NumberRange.new(CONFIG.COIN_PARTICLE_SPEED.min, CONFIG.COIN_PARTICLE_SPEED.max)
	particles.SpreadAngle = CONFIG.COIN_PARTICLE_SPREAD

	-- Convert size sequence
	local sizeKeypoints = {}
	for _, point in ipairs(CONFIG.COIN_PARTICLE_SIZE) do
		table.insert(sizeKeypoints, NumberSequenceKeypoint.new(point.time, point.size))
	end
	particles.Size = NumberSequence.new(sizeKeypoints)

	-- Convert transparency sequence
	local transparencyKeypoints = {}
	for _, point in ipairs(CONFIG.COIN_PARTICLE_TRANSPARENCY) do
		table.insert(transparencyKeypoints, NumberSequenceKeypoint.new(point.time, point.transparency))
	end
	particles.Transparency = NumberSequence.new(transparencyKeypoints)

	particles.Color = ColorSequence.new(CONFIG.COIN_COLOR)
	particles.Parent = attachment

	coin.Parent = Workspace

	-- Set lifetime
	task.delay(CONFIG.COIN_LIFETIME, function()
		if coin and coin.Parent then
			coin:Destroy()
		end
	end)

	return coin
end

local function handleCoinCollection(player, blockModel)
	if not player or not player.Character then 
		debugPrint("Coin collection failed: Player or character not found")
		return 
	end
	local humanoidRootPart = player.Character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then 
		debugPrint("Coin collection failed: HumanoidRootPart not found for player", player.Name)
		return 
	end

	-- Check cooldown
	local currentTime = tick()
	if coinCooldowns[blockModel] and currentTime - coinCooldowns[blockModel] < CONFIG.COIN_COOLDOWN then
		debugPrint("Coin collection skipped: Cooldown active for block", blockModel.Name, 
			"Time remaining:", CONFIG.COIN_COOLDOWN - (currentTime - coinCooldowns[blockModel]))
		return
	end

	-- Spawn coin
	local coin = createCoin(blockModel)
	coinCooldowns[blockModel] = currentTime
	debugPrint("Coin spawned for player", player.Name, "at block", blockModel.Name)

	-- Create a touch connection for the coin
	local touchConnection
	touchConnection = coin.Touched:Connect(function(hit)
		local touchingPlayer = Players:GetPlayerFromCharacter(hit.Parent)
		if touchingPlayer and touchingPlayer == player then
			debugPrint("Coin touched by player", player.Name)

			-- Create and play sound on player's character
			local sound = Instance.new("Sound")
			sound.SoundId = CONFIG.COIN_SOUND_ID
			sound.Volume = CONFIG.COIN_SOUND_VOLUME
			sound.Parent = humanoidRootPart
			sound:Play()
			debugPrint("Coin collection sound played for player", player.Name)

			-- Clean up sound after playing
			task.delay(sound.TimeLength, function()
				if sound and sound.Parent then
					sound:Destroy()
				end
			end)

			-- Award coins to player
			local coins = player:FindFirstChild("Coins")
			if coins then
				local oldValue = coins.Value
				coins.Value = coins.Value + CONFIG.COIN_REWARD
				debugPrint("Coins awarded to player", player.Name, 
					"Old value:", oldValue, 
					"New value:", coins.Value)

				-- Notify client of coin update
				CoinUpdateEvent:FireClient(player, coins.Value, CONFIG.COIN_REWARD)

				-- Create notification
				local notification = Instance.new("BillboardGui")
				notification.Name = "CoinNotification"
				notification.Size = CONFIG.COIN_NOTIFICATION_SIZE
				notification.AlwaysOnTop = true

				local textLabel = Instance.new("TextLabel")
				textLabel.Size = UDim2.new(1, 0, 1, 0)
				textLabel.BackgroundTransparency = 1
				textLabel.Text = CONFIG.COIN_NOTIFICATION_TEXT
				textLabel.TextColor3 = CONFIG.COIN_NOTIFICATION_COLOR
				textLabel.Font = CONFIG.COIN_NOTIFICATION_FONT
				textLabel.TextSize = CONFIG.COIN_NOTIFICATION_TEXT_SIZE
				textLabel.TextStrokeTransparency = 0
				textLabel.TextStrokeColor3 = Color3.new(0, 0, 0)
				textLabel.Parent = notification

				notification.Parent = humanoidRootPart
				debugPrint("Coin notification created for player", player.Name)

				-- Animate notification
				local startPos = humanoidRootPart.Position
				local tweenInfo = TweenInfo.new(
					CONFIG.COIN_NOTIFICATION_DURATION,
					Enum.EasingStyle.Quad,
					Enum.EasingDirection.Out
				)

				local tween = TweenService:Create(
					notification,
					tweenInfo,
					{
						StudsOffset = Vector3.new(0, 5, 0),
						StudsOffsetWorldSpace = startPos + Vector3.new(0, 5, 0)
					}
				)

				tween:Play()
				debugPrint("Coin notification animation started for player", player.Name)

				-- Clean up notification
				task.delay(CONFIG.COIN_NOTIFICATION_DURATION, function()
					if notification and notification.Parent then
						notification:Destroy()
						debugPrint("Coin notification cleaned up for player", player.Name)
					end
				end)
			else
				debugPrint("Warning: Coins value not found for player", player.Name)
			end

			-- Clean up
			if touchConnection then
				touchConnection:Disconnect()
				debugPrint("Coin touch connection cleaned up for player", player.Name)
			end
			coin:Destroy()
			debugPrint("Coin destroyed for player", player.Name)
		end
	end)

	-- Set lifetime
	task.delay(CONFIG.COIN_LIFETIME, function()
		if coin and coin.Parent then
			if touchConnection then
				touchConnection:Disconnect()
				debugPrint("Coin touch connection cleaned up (lifetime expired) for player", player.Name)
			end
			coin:Destroy()
			debugPrint("Coin destroyed (lifetime expired) for player", player.Name)
		end
	end)
end

-- Tween management
local function cleanupOldTweens()
	local currentTime = tick()
	local removedCount = 0

	for part, tween in pairs(activeTweens) do
		if not part:IsDescendantOf(game) then
			tween:Cancel()
			activeTweens[part] = nil
			tweenCount = tweenCount - 1
			removedCount = removedCount + 1
		end
	end

	if removedCount > 0 then
		debugPrint("Cleaned up", removedCount, "old tweens")
	end
end

-- Setup block
local function setupBlock(blockModel)
	-- Input validation
	if not blockModel then
		warn("setupBlock: blockModel is nil")
		return false
	end

	local retries = 0
	while retries < CONFIG.MAX_SETUP_RETRIES do
		local success, err = pcall(function()
			if not blockModel:IsA("Model") then
				warn("setupBlock: Invalid type for", blockModel.Name, "- expected Model, got", blockModel.ClassName)
				return false
			end

			debugPrint("Setting up block:", blockModel.Name)

			-- Set PrimaryPart
			if not blockModel.PrimaryPart then
				-- Find the first BasePart instead of the largest one
				for _, part in ipairs(blockModel:GetChildren()) do
					if part:IsA("BasePart") then
						blockModel.PrimaryPart = part
						debugPrint("Auto-set PrimaryPart for", blockModel.Name, "to", part.Name)
						break
					end
				end
			end

			if not blockModel.PrimaryPart then
				warn("setupBlock: No BasePart found for", blockModel.Name)
				return false
			end

			-- Validate bounding box
			local cframe, size = blockModel:GetBoundingBox()
			if not cframe or not size or size.X < 0.1 or size.Y < 0.1 or size.Z < 0.1 then
				warn("setupBlock: Invalid bounding box for", blockModel.Name, "- size:", size or "nil")
				return false
			end

			local partCount = 0
			local partsList = {}
			for _, p in ipairs(blockModel:GetChildren()) do
				if p:IsA("BasePart") then
					partCount = partCount + 1
					table.insert(partsList, p.Name)
				end
			end

			debugPrint("Block", blockModel.Name, "size:", size, "center Y:", cframe.Position.Y, 
				"parts:", partCount, "names:", table.concat(partsList, ", "), 
				"PrimaryPart Y:", blockModel.PrimaryPart.Position.Y, 
				"CanCollide:", blockModel.PrimaryPart.CanCollide)

			-- Anchor and clean parts
			for _, part in ipairs(blockModel:GetChildren()) do
				if part:IsA("BasePart") then
					part.Anchored = true
					part:BreakJoints()
					local joints = part:GetJoints()
					for _, joint in ipairs(joints) do
						if joint:IsA("Constraint") or joint:IsA("Weld") then
							debugPrint("Removing joint", joint.Name, "from", part.Name)
							joint:Destroy()
						end
					end
				end
			end

			-- Store original positions for all parts
			for _, part in ipairs(blockModel:GetChildren()) do
				if part:IsA("BasePart") then
					originalPositions[part] = part.Position.Y
					debugPrint("Stored original Y =", originalPositions[part], "for", part.Name)
				end
			end

			-- Initialize floating effect with larger values
			floatStates[blockModel] = {
				amplitude = math.random() * (CONFIG.FLOAT_AMPLITUDE.max - CONFIG.FLOAT_AMPLITUDE.min) + CONFIG.FLOAT_AMPLITUDE.min,
				speed = math.random() * (CONFIG.FLOAT_SPEED.max - CONFIG.FLOAT_SPEED.min) + CONFIG.FLOAT_SPEED.min,
				phase = math.random() * (CONFIG.FLOAT_PHASE_OFFSET.max - CONFIG.FLOAT_PHASE_OFFSET.min) + CONFIG.FLOAT_PHASE_OFFSET.min,
				time = 0
			}
			debugPrint("Initialized floating effect for", blockModel.Name, 
				"amplitude:", floatStates[blockModel].amplitude,
				"speed:", floatStates[blockModel].speed,
				"phase:", floatStates[blockModel].phase)

			-- Initialize floating effect if not already running
			initFloatingEffect()

			-- Initialize state
			blockStates[blockModel] = {
				isSunk = false,
				isAnimating = false,
				touchingPlayers = {},
				touchConnections = {},
				highlight = nil,
				lastTouchTime = 0
			}

			-- Connect touch events to PrimaryPart
			local primaryPart = blockModel.PrimaryPart
			local touchConn = primaryPart.Touched:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and hit.Name == "HumanoidRootPart" then
					local currentTime = tick()
					if currentTime - blockStates[blockModel].lastTouchTime < CONFIG.TOUCH_DEBOUNCE_TIME then
						return -- Prevent rapid touch events
					end
					blockStates[blockModel].lastTouchTime = currentTime

					local posY = hit.Position.Y
					if not blockStates[blockModel].touchingPlayers[player] then
						blockStates[blockModel].touchingPlayers[player] = true
						local count = 0
						for _ in pairs(blockStates[blockModel].touchingPlayers) do count = count + 1 end
						debugPrint("Player", player.Name, "touched", blockModel.Name, 
							"| touchingPlayers:", count, "player Y:", posY, 
							"block Y:", primaryPart.Position.Y)
						if not blockStates[blockModel].isSunk then
							debugPrint("Sinking", blockModel.Name)
							blockStates[blockModel].isSunk = true
							animateBlock(blockModel, -CONFIG.SINK_DISTANCE, true)
							if blockModel.PrimaryPart then
								local sound = blockModel.PrimaryPart:FindFirstChild("SinkSound")
								if sound then
									sound:Stop()
									sound.Volume = CONFIG.SINK_SOUND_VOLUME
									sound:Play()
									local fadeTween = TweenService:Create(
										sound,
										TweenInfo.new(CONFIG.SOUND_FADE_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
										{Volume = 0}
									)
									fadeTween:Play()
									fadeTween.Completed:Connect(function()
										sound:Stop()
										sound.Volume = CONFIG.SINK_SOUND_VOLUME
										debugPrint("Sound faded out for", blockModel.Name)
									end)
								end
							end
							-- Spawn coin when block is touched
							handleCoinCollection(player, blockModel)
						end
					end
				end
			end)

			local touchEndedConn = primaryPart.TouchEnded:Connect(function(hit)
				local player = Players:GetPlayerFromCharacter(hit.Parent)
				if player and hit.Name == "HumanoidRootPart" then
					task.wait(CONFIG.TOUCH_ENDED_DEBOUNCE)
					if blockStates[blockModel] and blockStates[blockModel].touchingPlayers[player] then
						blockStates[blockModel].touchingPlayers[player] = nil
						local count = 0
						for _ in pairs(blockStates[blockModel].touchingPlayers) do count = count + 1 end
						debugPrint("Player", player.Name, "left", blockModel.Name, 
							"| touchingPlayers:", count, "player Y:", hit.Position.Y, 
							"block Y:", primaryPart.Position.Y)
						if count == 0 and blockStates[blockModel].isSunk then
							popBlock(blockModel)
						end
					end
				end
			end)

			table.insert(blockStates[blockModel].touchConnections, touchConn)
			table.insert(blockStates[blockModel].touchConnections, touchEndedConn)

			-- Add effects
			if blockModel.PrimaryPart then
				if not blockModel.PrimaryPart:FindFirstChild("SinkSound") then
					safeExecute(createSound, blockModel.PrimaryPart, CONFIG.SINK_SOUND_ID, CONFIG.SINK_SOUND_VOLUME)
					debugPrint("Added SinkSound to", blockModel.Name)
				end
				if not blockModel.PrimaryPart:FindFirstChild("ParticleAttachment") then
					local attachment = Instance.new("Attachment")
					attachment.Name = "ParticleAttachment"
					attachment.Position = Vector3.new(0, size.Y/2, 0)
					attachment.Parent = blockModel.PrimaryPart
					safeExecute(createParticleEmitter, attachment, CONFIG)
					debugPrint("Added PopParticles to", blockModel.Name, "at Y =", size.Y/2)
				end
			end

			-- Trigger zone with Highlight
			if CONFIG.SHOW_TRIGGER_ZONES then
				blockStates[blockModel].highlight = safeExecute(createHighlight, blockModel)
				debugPrint("Added Highlight zone for", blockModel.Name)
			end

			return true
		end)

		if success then
			return true
		end

		warn("setupBlock: Error setting up", blockModel.Name, ":", err)
		retries = retries + 1
		if retries < CONFIG.MAX_SETUP_RETRIES then
			task.wait(CONFIG.SETUP_RETRY_DELAY)
		end
	end

	cleanupBlock(blockModel)
	return false
end

-- Server: Setup blocks
local blocksFolder = Workspace:FindFirstChild("FloatingBlocks")
if not blocksFolder then
	blocksFolder = Instance.new("Folder")
	blocksFolder.Name = "FloatingBlocks"
	blocksFolder.Parent = Workspace
	print("Created FloatingBlocks folder")
end

local function setupAllBlocks()
	taggedBlocks = {}
	for _, blockModel in ipairs(blocksFolder:GetChildren()) do
		if setupBlock(blockModel) then
			table.insert(taggedBlocks, blockModel)
			print("Successfully set up", blockModel.Name)
		else
			print("Failed to set up", blockModel.Name)
		end
	end
	print("Found and set up", #taggedBlocks, "blocks")
end

setupAllBlocks()

-- Handle new blocks
blocksFolder.ChildAdded:Connect(function(blockModel)
	print("New block added:", blockModel.Name)
	if setupBlock(blockModel) then
		table.insert(taggedBlocks, blockModel)
	end
end)

-- Cleanup
blocksFolder.ChildRemoved:Connect(function(blockModel)
	print("Block removed:", blockModel.Name)
	cleanupBlock(blockModel)
end)

-- Start periodic cleanup
task.spawn(function()
	while true do
		task.wait(CONFIG.TWEEN_CLEANUP_INTERVAL)
		cleanupOldTweens()
	end
end)