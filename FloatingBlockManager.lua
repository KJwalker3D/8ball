local CollectionService = game:GetService("CollectionService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

print("FloatingBlockManager started")

-- Configuration
local SINK_DISTANCE = 0.5
local SINK_TIME = 0.2
local POP_TIME = 0.2
local COOLDOWN_TIME = 1
local BOB_AMPLITUDE = 0.3
local BOB_PERIOD = 4
local PARTICLE_COUNT = 10

-- Track state
local originalPositions = {} -- Each part's original Y
local isSunk = {}
local touchingPlayers = {} -- [blockModel] = { [player] = true }
local lastTouchTimes = {}
local bobbingTweens = {}

-- Animate block parts
local function animateBlock(blockModel, targetOffsetY)
	print("Animating", blockModel.Name, "with offset Y =", targetOffsetY)
	if not blockModel:IsA("Model") then
		print("Cannot animate", blockModel.Name, ": not a model")
		return
	end
	for _, part in ipairs(blockModel:GetDescendants()) do
		if part:IsA("BasePart") then
			local tween = TweenService:Create(
				part,
				TweenInfo.new(
					targetOffsetY < 0 and SINK_TIME or POP_TIME,
					Enum.EasingStyle.Sine,
					Enum.EasingDirection.InOut
				),
				{Position = Vector3.new(part.Position.X, originalPositions[part] + targetOffsetY, part.Position.Z)}
			)
			tween:Play()
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
		for _, part in ipairs(blockModel:GetDescendants()) do
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

-- Check if player's character is still touching the block
local function isPlayerTouching(blockModel, player)
	local character = player.Character
	if not character then return false end
	for _, blockPart in ipairs(blockModel:GetDescendants()) do
		if blockPart:IsA("BasePart") then
			for _, charPart in ipairs(character:GetDescendants()) do
				if charPart:IsA("BasePart") and charPart:IsDescendantOf(character) then
					local touching = blockPart:GetTouchingParts()
					for _, touchingPart in ipairs(touching) do
						if touchingPart == charPart then
							return true
						end
					end
				end
			end
		end
	end
	return false
end

-- Handle touch
local function onTouched(blockModel, hit)
	print("Touched", blockModel.Name, "by", hit.Name)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if player and humanoid and not isSunk[blockModel] then
		local now = tick()
		local playerLastTouch = lastTouchTimes[player] and lastTouchTimes[player][blockModel] or 0
		if now - playerLastTouch < COOLDOWN_TIME then
			print("Cooldown for", player.Name, "on", blockModel.Name)
			return
		end

		lastTouchTimes[player] = lastTouchTimes[player] or {}
		lastTouchTimes[player][blockModel] = now

		touchingPlayers[blockModel] = touchingPlayers[blockModel] or {}
		if not touchingPlayers[blockModel][player] then
			touchingPlayers[blockModel][player] = true
			print("Player", player.Name, "added to", blockModel.Name)

			print("Sinking", blockModel.Name, "for", player.Name)
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
		end
	end
end

-- Handle touch ended
local function onTouchEnded(blockModel, hit)
	print("Touch ended on", blockModel.Name, "by", hit.Name)
	local character = hit.Parent
	local player = Players:GetPlayerFromCharacter(character)
	if player and touchingPlayers[blockModel] and touchingPlayers[blockModel][player] then
		-- Check if player is still touching with any part
		if not isPlayerTouching(blockModel, player) then
			touchingPlayers[blockModel][player] = nil
			print("Player", player.Name, "removed from", blockModel.Name)

			local hasPlayers = false
			for _ in pairs(touchingPlayers[blockModel]) do
				hasPlayers = true
				break
			end

			if not hasPlayers and isSunk[blockModel] then
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
	end
end

-- Set up blocks
local blocks = CollectionService:GetTagged("FloatingBlock")
print("Found", #blocks, "tagged blocks")
for _, blockModel in ipairs(blocks) do
	print("Processing block:", blockModel.Name)
	if blockModel:IsA("Model") then
		print("Is Model:", blockModel.Name)
		originalPositions[blockModel] = {}
		for _, part in ipairs(blockModel:GetDescendants()) do
			if part:IsA("BasePart") then
				originalPositions[part] = part.Position.Y
				print("Stored position for", part.Name, "in", blockModel.Name, "at Y =", originalPositions[part])
			end
		end

		isSunk[blockModel] = false
		touchingPlayers[blockModel] = {}
		print("Set up", blockModel.Name)

		for _, part in ipairs(blockModel:GetDescendants()) do
			if part:IsA("BasePart") then
				print("Connecting events for part:", part.Name, "in", blockModel.Name)
				part.Touched:Connect(function(hit) onTouched(blockModel, hit) end)
				part.TouchEnded:Connect(function(hit) onTouchEnded(blockModel, hit) end)
			end
		end

		updateBobbing(blockModel, true)

		if blockModel.PrimaryPart then
			if not blockModel.PrimaryPart:FindFirstChild("SinkSound") then
				local sound = Instance.new("Sound")
				sound.Name = "SinkSound"
				sound.SoundId = "rbxassetid://9047050076"
				sound.Volume = 0.5
				sound.Parent = blockModel.PrimaryPart
				print("Added SinkSound to", blockModel.Name)
			end
			if not blockModel.PrimaryPart:FindFirstChild("PopParticles") then
				local particles = Instance.new("ParticleEmitter")
				particles.Name = "PopParticles"
				particles.Texture = "rbxassetid://243660364"
				particles.Lifetime = NumberRange.new(0.5, 1)
				particles.Rate = 0
				particles.Speed = NumberRange.new(2, 5)
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

-- Handle new blocks
CollectionService:GetInstanceAddedSignal("FloatingBlock"):Connect(function(blockModel)
	print("New block added:", blockModel.Name)
	if blockModel:IsA("Model") then
		originalPositions[blockModel] = {}
		for _, part in ipairs(blockModel:GetDescendants()) do
			if part:IsA("BasePart") then
				originalPositions[part] = part.Position.Y
			end
		end
		isSunk[blockModel] = false
		touchingPlayers[blockModel] = {}
		for _, part in ipairs(blockModel:GetDescendants()) do
			if part:IsA("BasePart") then
				part.Touched:Connect(function(hit) onTouched(blockModel, hit) end)
				part.TouchEnded:Connect(function(hit) onTouchEnded(blockModel, hit) end)
			end
		end
		updateBobbing(blockModel, true)

		if blockModel.PrimaryPart then
			if not blockModel.PrimaryPart:FindFirstChild("SinkSound") then
				local sound = Instance.new("Sound")
				sound.Name = "SinkSound"
				sound.SoundId = "rbxassetid://9047050076"
				sound.Volume = 0.5
				sound.Parent = blockModel.PrimaryPart
			end
			if not blockModel.PrimaryPart:FindFirstChild("PopParticles") then
				local particles = Instance.new("ParticleEmitter")
				particles.Name = "PopParticles"
				particles.Texture = "rbxassetid://243660364"
				particles.Lifetime = NumberRange.new(0.5, 1)
				particles.Rate = 0
				particles.Speed = NumberRange.new(2, 5)
				particles.Enabled = false
				particles.Parent = blockModel.PrimaryPart
			end
		end
	end
end)

-- Cleanup
CollectionService:GetInstanceRemovedSignal("FloatingBlock"):Connect(function(blockModel)
	print("Block removed:", blockModel.Name)
	originalPositions[blockModel] = nil
	isSunk[blockModel] = nil
	touchingPlayers[blockModel] = nil
	if bobbingTweens[blockModel] then
		for _, tweenPair in pairs(bobbingTweens[blockModel]) do
			tweenPair.up:Cancel()
			tweenPair.down:Cancel()
		end
		bobbingTweens[blockModel] = nil
	end
end)