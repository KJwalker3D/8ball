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
local originalPositions = {}
local isSunk = {} -- True if block is sunk
local touchingPlayers = {} -- Players touching each block
local lastTouchTimes = {} -- Cooldown per player
local bobbingTweens = {}

-- Animate block
local function animateBlock(blockModel, targetY)
	print("Animating", blockModel.Name, "to Y =", targetY)
	if not blockModel:IsA("Model") or not blockModel.PrimaryPart then
		print("Cannot animate", blockModel.Name, ": not a model or no PrimaryPart")
		return
	end
	local tween = TweenService:Create(
		blockModel.PrimaryPart,
		TweenInfo.new(
			targetY > blockModel.PrimaryPart.Position.Y and POP_TIME or SINK_TIME,
			Enum.EasingStyle.Sine,
			Enum.EasingDirection.InOut
		),
		{Position = Vector3.new(blockModel.PrimaryPart.Position.X, targetY, blockModel.PrimaryPart.Position.Z)}
	)
	tween:Play()
end

-- Bobbing animation
local function updateBobbing(blockModel, shouldBob)
	print("Bobbing", blockModel.Name, shouldBob and "on" or "off")
	if not blockModel.PrimaryPart then return end
	local tween = bobbingTweens[blockModel]
	if tween then
		tween:Cancel()
		bobbingTweens[blockModel] = nil
	end
	if shouldBob then
		local originalY = originalPositions[blockModel]
		local tweenUp = TweenService:Create(
			blockModel.PrimaryPart,
			TweenInfo.new(BOB_PERIOD / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Position = Vector3.new(blockModel.PrimaryPart.Position.X, originalY + BOB_AMPLITUDE, blockModel.PrimaryPart.Position.Z)}
		)
		local tweenDown = TweenService:Create(
			blockModel.PrimaryPart,
			TweenInfo.new(BOB_PERIOD / 2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
			{Position = Vector3.new(blockModel.PrimaryPart.Position.X, originalY, blockModel.PrimaryPart.Position.Z)}
		)
		bobbingTweens[blockModel] = tweenUp
		coroutine.wrap(function()
			while bobbingTweens[blockModel] == tweenUp do
				tweenUp:Play()
				tweenUp.Completed:Wait()
				tweenDown:Play()
				tweenDown.Completed:Wait()
			end
		end)()
	end
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
		if now - playerLastTouch < COOLDOWN_TIME then return end

		lastTouchTimes[player] = lastTouchTimes[player] or {}
		lastTouchTimes[player][blockModel] = now

		touchingPlayers[blockModel] = touchingPlayers[blockModel] or {}
		touchingPlayers[blockModel][player] = (touchingPlayers[blockModel][player] or 0) + 1

		if not isSunk[blockModel] then
			print("Sinking", blockModel.Name, "for", player.Name)
			isSunk[blockModel] = true
			local originalY = originalPositions[blockModel]
			animateBlock(blockModel, originalY - SINK_DISTANCE)
			updateBobbing(blockModel, false)

			local sound = blockModel.PrimaryPart:FindFirstChild("SinkSound")
			if sound then
				sound.Pitch = 1 + (math.random(-20, 20) / 100)
				sound:Play()
				print("Played sound for", blockModel.Name)
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
		touchingPlayers[blockModel][player] = touchingPlayers[blockModel][player] - 1
		if touchingPlayers[blockModel][player] <= 0 then
			touchingPlayers[blockModel][player] = nil
		end

		-- Check if no players are touching
		local hasPlayers = false
		for _ in pairs(touchingPlayers[blockModel]) do
			hasPlayers = true
			break
		end

		if not hasPlayers and isSunk[blockModel] then
			print("Popping up", blockModel.Name)
			isSunk[blockModel] = false
			touchingPlayers[blockModel] = {}
			local originalY = originalPositions[blockModel]
			animateBlock(blockModel, originalY)
			updateBobbing(blockModel, true)

			local particles = blockModel.PrimaryPart:FindFirstChild("PopParticles")
			if particles then
				particles:Emit(PARTICLE_COUNT)
				print("Emitted", PARTICLE_COUNT, "particles for", blockModel.Name)
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
		if not blockModel.PrimaryPart then
			local parts = blockModel:GetChildren()
			for _, part in ipairs(parts) do
				if part:IsA("BasePart") then
					blockModel.PrimaryPart = part
					print("Auto-set PrimaryPart for", blockModel.Name, "to", part.Name)
					break
				end
			end
		end
		if blockModel.PrimaryPart then
			print("Has PrimaryPart:", blockModel.PrimaryPart.Name)
			if blockModel.PrimaryPart.Anchored then
				originalPositions[blockModel] = blockModel.PrimaryPart.Position.Y
				isSunk[blockModel] = false
				touchingPlayers[blockModel] = {}
				print("Set up", blockModel.Name, "at Y =", originalPositions[blockModel])

				for _, part in ipairs(blockModel:GetDescendants()) do
					if part:IsA("BasePart") then
						print("Connecting events for part:", part.Name, "in", blockModel.Name)
						part.Touched:Connect(function(hit) onTouched(blockModel, hit) end)
						part.TouchEnded:Connect(function(hit) onTouchEnded(blockModel, hit) end)
					end
				end

		

				updateBobbing(blockModel, true)

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
				print("PrimaryPart not anchored for", blockModel.Name)
			end
		else
			print("No PrimaryPart for", blockModel.Name)
		end
	else
		print("Not a Model:", blockModel.Name, "is a", blockModel.ClassName)
	end
end

-- Handle new blocks
CollectionService:GetInstanceAddedSignal("FloatingBlock"):Connect(function(blockModel)
	print("New block added:", blockModel.Name)
	if blockModel:IsA("Model") and blockModel.PrimaryPart and blockModel.PrimaryPart.Anchored then
		originalPositions[blockModel] = blockModel.PrimaryPart.Position.Y
		isSunk[blockModel] = false
		touchingPlayers[blockModel] = {}
		for _, part in ipairs(blockModel:GetDescendants()) do
			if part:IsA("BasePart") then
				print("Connecting events for new part:", part.Name)
				part.Touched:Connect(function(hit) onTouched(blockModel, hit) end)
				part.TouchEnded:Connect(function(hit) onTouchEnded(blockModel, hit) end)
			end
		end
	
		updateBobbing(blockModel, true)

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
end)

-- Cleanup
CollectionService:GetInstanceRemovedSignal("FloatingBlock"):Connect(function(blockModel)
	print("Block removed:", blockModel.Name)
	originalPositions[blockModel] = nil
	isSunk[blockModel] = nil
	touchingPlayers[blockModel] = nil
	if bobbingTweens[blockModel] then
		bobbingTweens[blockModel]:Cancel()
		bobbingTweens[blockModel] = nil
	end
end)

for _, p in ipairs(workspace.BlockA:GetChildren()) do print(p.Name, p.ClassName, p.Anchored, p.CanCollide) end