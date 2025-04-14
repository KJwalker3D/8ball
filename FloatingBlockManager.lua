local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

print("FloatingBlockManager started")

-- Configuration
local SINK_DISTANCE = 2.5
local SINK_TIME = 2
local POP_TIME = 1
local BOB_AMPLITUDE = 0.3
local BOB_PERIOD = 4
local PARTICLE_COUNT = 12
local CHECK_INTERVAL = 0.1 -- 10 Hz

-- Track state
local originalPositions = {}
local isSunk = {}
local isAnimating = {}
local touchingPlayers = {} -- [blockModel] = { [player] = true }
local bobbingTweens = {}
local activeTweens = {} -- [part] = tween
local taggedBlocks = CollectionService:GetTagged("FloatingBlock")
local blockRegions = {} -- [blockModel] = {boundsMin, boundsMax}

-- Animate block parts
local function animateBlock(blockModel, targetOffsetY)
	if isAnimating[blockModel] then
		print("Skipping animation for", blockModel.Name, "- already animating")
		return
	end
	isAnimating[blockModel] = true
	print("Animating", blockModel.Name, "with offset Y =", targetOffsetY)
	if not blockModel:IsA("Model") then
		print("Cannot animate", blockModel.Name, ": not a model")
		isAnimating[blockModel] = nil
		return
	end
	for _, part in ipairs(blockModel:GetChildren()) do
		if part:IsA("BasePart") then
			if not part.Anchored then
				part.Anchored = true
				print("Forced Anchored = true for", part.Name)
			end
			if not originalPositions[part] then
				print("Warning: No original position for", part.Name)
				originalPositions[part] = part.Position.Y
			end
			local targetY = originalPositions[part] + targetOffsetY
			print("Tweening", part.Name, "from Y =", part.Position.Y, "to Y =", targetY)
			if activeTweens[part] then
				activeTweens[part]:Cancel()
				activeTweens[part] = nil
			end
			local tween = TweenService:Create(
				part,
				TweenInfo.new(
					targetOffsetY < 0 and SINK_TIME or POP_TIME,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{Position = Vector3.new(part.Position.X, targetY, part.Position.Z)}
			)
			activeTweens[part] = tween
			tween:Play()
			tween.Completed:Connect(function()
				print("Tween completed for", part.Name, "at Y =", part.Position.Y)
				if activeTweens[part] == tween then
					activeTweens[part] = nil
				end
				-- Clear animating state only after all parts finish
				local allDone = true
				for _, p in ipairs(blockModel:GetChildren()) do
					if p:IsA("BasePart") and activeTweens[p] then
						allDone = false
						break
					end
				end
				if allDone then
					isAnimating[blockModel] = nil
				end
			end)
		end
	end
end

-- Bobbing animation
local function updateBobbing(blockModel, shouldBob)
	print("Bobbing", blockModel.Name, shouldBob and "on" or "off")
	if bobbingTweens[blockModel] then
		for _, tweenPair in pairs(bobbingTweens[blockModel]) do
			tweenPair.up:Cancel()
			tweenPair.down:Cancel()
		end
		bobbingTweens[blockModel] = nil
	end
	if shouldBob then
		bobbingTweens[blockModel] = {}
		for _, part in ipairs(blockModel:GetChildren()) do
			if part:IsA("BasePart") then
				local originalY = originalPositions[part]
				local tweenUp = TweenService:Create(
					part,
					TweenInfo.new(BOB_PERIOD / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Position = Vector3.new(part.Position.X, originalY + BOB_AMPLITUDE, part.Position.Z)}
				)
				local tweenDown = TweenService:Create(
					part,
					TweenInfo.new(BOB_PERIOD / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
					{Position = Vector3.new(part.Position.X, originalY, part.Position.Z)}
				)
				bobbingTweens[blockModel][part] = {up = tweenUp, down = tweenDown}
				coroutine.wrap(function()
					while bobbingTweens[blockModel] and bobbingTweens[blockModel][part] do
						tweenUp:Play()
						tweenUp.Completed:Wait()
						tweenDown:Play()
						tweenDown.Completed:Wait()
					end
				end)()
			end
		end
	end
end

-- Update block regions
local function updateBlockRegion(blockModel)
	if not blockModel.PrimaryPart then
		print("No PrimaryPart for", blockModel.Name, "- skipping region update")
		blockRegions[blockModel] = nil
		return false
	end
	local cframe, size = blockModel:GetBoundingBox()
	if size.X < 0.1 or size.Z < 0.1 then
		print("Invalid size for", blockModel.Name, ": X =", size.X, "Z =", size.Z)
		blockRegions[blockModel] = nil
		return false
	end
	print("Updated region for", blockModel.Name, "size =", size)
	local boundsMin = cframe.Position - Vector3.new(size.X/2, 2, size.Z/2)
	local boundsMax = cframe.Position + Vector3.new(size.X/2, 6, size.Z/2)
	blockRegions[blockModel] = {boundsMin = boundsMin, boundsMax = boundsMax}
	return true
end

-- Check players in block's trigger area
local function updateTriggerArea(blockModel)
	local regionData = blockRegions[blockModel]
	if not regionData then return end
	local region = Region3.new(regionData.boundsMin, regionData.boundsMax)
	local parts = Workspace:FindPartsInRegion3(region, blockModel, 100)
	local newTouching = {}

	for _, part in ipairs(parts) do
		if part.Name == "HumanoidRootPart" then
			local character = part.Parent
			local player = Players:GetPlayerFromCharacter(character)
			if player then
				newTouching[player] = true
			end
		end
	end

	-- Check for players who left
	for player in pairs(touchingPlayers[blockModel] or {}) do
		if not newTouching[player] then
			print("Player", player.Name, "left", blockModel.Name)
			touchingPlayers[blockModel][player] = nil
		end
	end

	-- Check for new players
	for player in pairs(newTouching) do
		if not touchingPlayers[blockModel][player] then
			print("Player", player.Name, "entered", blockModel.Name)
			touchingPlayers[blockModel][player] = true
		end
	end

	-- Update block state
	local hasPlayers = next(touchingPlayers[blockModel]) ~= nil
	if hasPlayers and not isSunk[blockModel] then
		print("Sinking", blockModel.Name)
		isSunk[blockModel] = true
		animateBlock(blockModel, -SINK_DISTANCE)
		updateBobbing(blockModel, false)
		if blockModel.PrimaryPart then
			local sound = blockModel.PrimaryPart:FindFirstChild("SinkSound")
			if sound then
				sound.Pitch = 1 + (math.random(-20, 20) / 100)
				sound:Play()
				print("Played sound for", blockModel.Name)
			end
		end
	elseif not hasPlayers and isSunk[blockModel] then
		print("Popping up", blockModel.Name)
		isSunk[blockModel] = false
		touchingPlayers[blockModel] = {}
		animateBlock(blockModel, 0)
		updateBobbing(blockModel, true)
		if blockModel.PrimaryPart then
			local particles = blockModel.PrimaryPart:FindFirstChild("PopParticles")
			if particles then
				particles:Emit(PARTICLE_COUNT)
				print("Emitted", PARTICLE_COUNT, "particles for", blockModel.Name)
			end
		end
	end
end

-- Set up blocks
print("Found", #taggedBlocks, "tagged blocks")
for _, blockModel in ipairs(taggedBlocks) do
	print("Processing block:", blockModel.Name)
	if blockModel:IsA("Model") then
		print("Is Model:", blockModel.Name)
		originalPositions[blockModel] = {}
		if not blockModel.PrimaryPart then
			for _, part in ipairs(blockModel:GetChildren()) do
				if part:IsA("BasePart") then
					blockModel.PrimaryPart = part
					print("Auto-set PrimaryPart for", blockModel.Name, "to", part.Name)
					break
				end
			end
		end
		for _, part in ipairs(blockModel:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				originalPositions[part] = part.Position.Y
				print("Stored position for", part.Name, "in", blockModel.Name, "at Y =", originalPositions[part])
			end
		end

		isSunk[blockModel] = false
		isAnimating[blockModel] = false
		touchingPlayers[blockModel] = {}
		print("Set up", blockModel.Name)
		if updateBlockRegion(blockModel) then
			updateBobbing(blockModel, true)
		end

		if blockModel.PrimaryPart then
			if not blockModel.PrimaryPart:FindFirstChild("SinkSound") then
				local sound = Instance.new("Sound")
				sound.Name = "SinkSound"
				sound.SoundId = "rbxassetid://9120858323"
				sound.Volume = 0.5
				sound.Parent = blockModel.PrimaryPart
				print("Added SinkSound to", blockModel.Name)
			end
			if not blockModel.PrimaryPart:FindFirstChild("PopParticles") then
				local particles = Instance.new("ParticleEmitter")
				particles.Name = "PopParticles"
				particles.Texture = "rbxassetid://14500233914"
				particles.Lifetime = NumberRange.new(0.5, 1)
				particles.Rate = 0
				particles.Speed = NumberRange.new(2, 5)
				particles.SpreadAngle = Vector2.new(60, 60)
				particles.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.7),
					NumberSequenceKeypoint.new(1, 1.2)
				})
				particles.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1)
				})
				particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
				particles.Enabled = false
				particles.Parent = blockModel.PrimaryPart
				print("Added PopParticles to", blockModel.Name)
			end
		else
			print("Warning: No PrimaryPart for", blockModel.Name, "- effects skipped")
		end
	else
		print("Not a Model:", blockModel.Name, "is a", blockModel.ClassName)
	end
end

-- Update trigger areas
local lastCheck = 0
RunService.Heartbeat:Connect(function()
	local now = tick()
	if now - lastCheck < CHECK_INTERVAL then return end
	lastCheck = now
	for _, blockModel in ipairs(taggedBlocks) do
		if blockModel:IsA("Model") then
			updateTriggerArea(blockModel)
		end
	end
end)

-- Handle new blocks
CollectionService:GetInstanceAddedSignal("FloatingBlock"):Connect(function(blockModel)
	print("New block added:", blockModel.Name)
	if blockModel:IsA("Model") then
		originalPositions[blockModel] = {}
		if not blockModel.PrimaryPart then
			for _, part in ipairs(blockModel:GetChildren()) do
				if part:IsA("BasePart") then
					blockModel.PrimaryPart = part
					print("Auto-set PrimaryPart for", blockModel.Name, "to", part.Name)
					break
				end
			end
		end
		for _, part in ipairs(blockModel:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				originalPositions[part] = part.Position.Y
				print("Stored position for", part.Name, "in", blockModel.Name, "at Y =", originalPositions[part])
			end
		end
		isSunk[blockModel] = false
		isAnimating[blockModel] = false
		touchingPlayers[blockModel] = {}
		table.insert(taggedBlocks, blockModel)
		if updateBlockRegion(blockModel) then
			updateBobbing(blockModel, true)
		end

		if blockModel.PrimaryPart then
			if not blockModel.PrimaryPart:FindFirstChild("SinkSound") then
				local sound = Instance.new("Sound")
				sound.Name = "SinkSound"
				sound.SoundId = "rbxassetid://9120858323"
				sound.Volume = 0.5
				sound.Parent = blockModel.PrimaryPart
				print("Added SinkSound to", blockModel.Name)
			end
			if not blockModel.PrimaryPart:FindFirstChild("PopParticles") then
				local particles = Instance.new("ParticleEmitter")
				particles.Name = "PopParticles"
				particles.Texture = "rbxassetid://14500233914"
				particles.Lifetime = NumberRange.new(0.5, 1)
				particles.Rate = 0
				particles.Speed = NumberRange.new(2, 5)
				particles.SpreadAngle = Vector2.new(60, 60)
				particles.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0.7),
					NumberSequenceKeypoint.new(1, 1.2)
				})
				particles.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(1, 1)
				})
				particles.Color = ColorSequence.new(Color3.fromRGB(100, 200, 255))
				particles.Enabled = false
				particles.Parent = blockModel.PrimaryPart
				print("Added PopParticles to", blockModel.Name)
			end
		end
	end
end)

-- Cleanup
CollectionService:GetInstanceRemovedSignal("FloatingBlock"):Connect(function(blockModel)
	print("Block removed:", blockModel.Name)
	originalPositions[blockModel] = nil
	isSunk[blockModel] = nil
	isAnimating[blockModel] = nil
	touchingPlayers[blockModel] = nil
	blockRegions[blockModel] = nil
	for _, part in ipairs(blockModel:GetChildren()) do
		if part:IsA("BasePart") and activeTweens[part] then
			activeTweens[part]:Cancel()
			activeTweens[part] = nil
		end
	end
	if bobbingTweens[blockModel] then
		for _, tweenPair in pairs(bobbingTweens[blockModel]) do
			tweenPair.up:Cancel()
			tweenPair.down:Cancel()
		end
		bobbingTweens[blockModel] = nil
	end
	for i, taggedBlock in ipairs(taggedBlocks) do
		if taggedBlock == blockModel then
			table.remove(taggedBlocks, i)
			break
		end
	end
end)

for _, b in ipairs(CollectionService:GetTagged("FloatingBlock")) do local _, s = b:GetBoundingBox() print(b.Name, s) end