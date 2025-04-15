local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

print("FloatingBlockManager started")

-- Configuration
local SINK_DISTANCE = 2.5 -- Studs to sink
local SINK_TIME = 1 -- Seconds to sink
local POP_TIME = 1 -- Seconds to pop up
local PARTICLE_COUNT = 50 -- Particles on pop
local SOUND_FADE_DURATION = 1 -- Seconds for sound fade-out
local TOUCH_ENDED_DEBOUNCE = 0.7 -- Seconds to verify player left
local SHOW_TRIGGER_ZONES = true -- Toggle for debugging

-- Track state
local originalCFrames = {} -- [blockModel] = CFrame
local blockStates = {} -- [blockModel] = {isSunk, isAnimating, touchingPlayers, touchConnections, highlight}
local activeTweens = {} -- [blockModel] = tween
local taggedBlocks = {} -- Track valid blocks

-- Animate block
local function animateBlock(blockModel, targetOffsetY, force)
	if blockStates[blockModel].isAnimating and not force then
		print("Skipping animation for", blockModel.Name, "- already animating")
		return
	end
	blockStates[blockModel].isAnimating = true
	print("Animating", blockModel.Name, "to offset Y =", targetOffsetY)

	local primaryPart = blockModel.PrimaryPart
	if not primaryPart then
		print("No PrimaryPart for", blockModel.Name, "- aborting animation")
		blockStates[blockModel].isAnimating = nil
		return
	end

	if not originalCFrames[blockModel] then
		originalCFrames[blockModel] = primaryPart.CFrame
		print("Stored original CFrame for", blockModel.Name, "at Y =", primaryPart.Position.Y)
	end

	local targetY = originalCFrames[blockModel].Position.Y + targetOffsetY
	local targetCFrame = CFrame.new(primaryPart.Position.X, targetY, primaryPart.Position.Z) * primaryPart.CFrame.Rotation
	print("Tweening", blockModel.Name, "from Y =", primaryPart.Position.Y, "to Y =", targetY)

	if activeTweens[blockModel] then
		activeTweens[blockModel]:Cancel()
		activeTweens[blockModel] = nil
		print("Canceled existing tween for", blockModel.Name)
	end

	local tweenInfo = TweenInfo.new(
		targetOffsetY < 0 and SINK_TIME or POP_TIME,
		Enum.EasingStyle.Sine,
		Enum.EasingDirection.InOut
	)
	local tween = TweenService:Create(primaryPart, tweenInfo, {CFrame = targetCFrame})
	activeTweens[blockModel] = tween
	local startTime = tick()
	tween:Play()
	tween.Completed:Connect(function(status)
		local duration = tick() - startTime
		print("Tween completed for", blockModel.Name, "at Y =", primaryPart.Position.Y, "status:", status, "duration:", duration)
		if activeTweens[blockModel] == tween then
			activeTweens[blockModel] = nil
		end
		blockStates[blockModel].isAnimating = nil
		-- Fallback if tween fails
		if math.abs(primaryPart.Position.Y - targetY) > 0.1 then
			print("Forcing Y =", targetY, "for", blockModel.Name)
			primaryPart.CFrame = targetCFrame
		end
	end)
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
			particles.PopParticles:Emit(PARTICLE_COUNT)
			print("Emitted", PARTICLE_COUNT, "particles for", blockModel.Name)
		end
	end
end

-- Setup block
local function setupBlock(blockModel)
	local success, err = pcall(function()
		if not blockModel:IsA("Model") then
			print("Not a Model:", blockModel.Name, "is a", blockModel.ClassName)
			return false
		end
		print("Setting up block:", blockModel.Name)

		-- Set PrimaryPart
		if not blockModel.PrimaryPart then
			for _, part in ipairs(blockModel:GetChildren()) do
				if part:IsA("BasePart") then
					blockModel.PrimaryPart = part
					print("Auto-set PrimaryPart for", blockModel.Name, "to", part.Name)
					break
				end
			end
		end
		if not blockModel.PrimaryPart then
			print("No BasePart found for", blockModel.Name, "- skipping")
			return false
		end

		-- Validate bounding box
		local cframe, size = blockModel:GetBoundingBox()
		if not cframe or not size or size.X < 0.1 or size.Y < 0.1 or size.Z < 0.1 then
			print("Invalid bounding box for", blockModel.Name, "- size:", size or "nil")
			return false
		end
		local partCount = 0
		local primaryPart = blockModel.PrimaryPart
		for _, p in ipairs(blockModel:GetChildren()) do
			if p:IsA("BasePart") then
				partCount = partCount + 1
				if p ~= primaryPart then
					-- Weld to PrimaryPart
					local weld = Instance.new("WeldConstraint")
					weld.Name = "BlockWeld_" .. p.Name
					weld.Part0 = primaryPart
					weld.Part1 = p
					weld.Parent = primaryPart
					print("Welded", p.Name, "to PrimaryPart", primaryPart.Name)
				end
			end
		end
		print("Block", blockModel.Name, "size:", size, "center Y:", cframe.Position.Y, "parts:", partCount, "PrimaryPart Y:", primaryPart.Position.Y, "CanCollide:", primaryPart.CanCollide)

		-- Anchor and clean parts
		for _, part in ipairs(blockModel:GetChildren()) do
			if part:IsA("BasePart") then
				part.Anchored = true
				part:BreakJoints() -- Remove non-WeldConstraint joints
				local joints = part:GetJoints()
				for _, joint in ipairs(joints) do
					if (joint:IsA("Constraint") and not joint:IsA("WeldConstraint")) or joint:IsA("Weld") then
						print("Removing joint", joint.Name, "from", part.Name)
						joint:Destroy()
					end
				end
			end
		end

		-- Initialize state
		blockStates[blockModel] = {
			isSunk = false,
			isAnimating = false,
			touchingPlayers = {},
			touchConnections = {},
			highlight = nil
		}

		-- Connect touch events to PrimaryPart
		local touchConn = primaryPart.Touched:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and hit.Name == "HumanoidRootPart" then
				local posY = hit.Position.Y
				if not blockStates[blockModel].touchingPlayers[player] then
					blockStates[blockModel].touchingPlayers[player] = true
					local count = 0
					for _ in pairs(blockStates[blockModel].touchingPlayers) do count = count + 1 end
					print("Player", player.Name, "touched", blockModel.Name, "| touchingPlayers:", count, "player Y:", posY, "block Y:", primaryPart.Position.Y)
					if not blockStates[blockModel].isSunk then
						print("Sinking", blockModel.Name)
						blockStates[blockModel].isSunk = true
						animateBlock(blockModel, -SINK_DISTANCE, true)
						if blockModel.PrimaryPart then
							local sound = blockModel.PrimaryPart:FindFirstChild("SinkSound")
							if sound then
								sound:Stop()
								sound.Volume = 0.5
								sound:Play()
								local fadeTween = TweenService:Create(
									sound,
									TweenInfo.new(SOUND_FADE_DURATION, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
									{Volume = 0}
								)
								fadeTween:Play()
								fadeTween.Completed:Connect(function()
									sound:Stop()
									sound.Volume = 0.5
									print("Sound faded out for", blockModel.Name)
								end)
							end
						end
					end
				end
			end
		end)
		local touchEndedConn = primaryPart.TouchEnded:Connect(function(hit)
			local player = Players:GetPlayerFromCharacter(hit.Parent)
			if player and hit.Name == "HumanoidRootPart" then
				task.wait(TOUCH_ENDED_DEBOUNCE)
				if blockStates[blockModel] and blockStates[blockModel].touchingPlayers[player] then
					blockStates[blockModel].touchingPlayers[player] = nil
					local count = 0
					for _ in pairs(blockStates[blockModel].touchingPlayers) do count = count + 1 end
					print("Player", player.Name, "left", blockModel.Name, "| touchingPlayers:", count, "player Y:", hit.Position.Y, "block Y:", primaryPart.Position.Y)
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
				local sound = Instance.new("Sound")
				sound.Name = "SinkSound"
				sound.SoundId = "rbxassetid://9120858323"
				sound.Volume = 0.5
				sound.Parent = blockModel.PrimaryPart
				print("Added SinkSound to", blockModel.Name)
			end
			if not blockModel.PrimaryPart:FindFirstChild("ParticleAttachment") then
				local attachment = Instance.new("Attachment")
				attachment.Name = "ParticleAttachment"
				attachment.Position = Vector3.new(0, size.Y/2, 0)
				attachment.Parent = blockModel.PrimaryPart
				local particles = Instance.new("ParticleEmitter")
				particles.Name = "PopParticles"
				particles.Texture = "rbxassetid://243728076"
				particles.Lifetime = NumberRange.new(1, 2)
				particles.Rate = 0
				particles.Speed = NumberRange.new(5, 10)
				particles.SpreadAngle = Vector2.new(90, 90)
				particles.Size = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1),
					NumberSequenceKeypoint.new(1, 2)
				})
				particles.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 0),
					NumberSequenceKeypoint.new(0.5, 0.5),
					NumberSequenceKeypoint.new(1, 1)
				})
				particles.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255))
				particles.Enabled = false
				particles.Parent = attachment
				print("Added PopParticles to", blockModel.Name, "at Y =", size.Y/2)
			end
		end

		-- Trigger zone with Highlight
		if SHOW_TRIGGER_ZONES then
			local highlight = Instance.new("Highlight")
			highlight.Name = "TriggerZone"
			highlight.Adornee = blockModel
			highlight.FillColor = Color3.new(1, 0, 0)
			highlight.FillTransparency = 0.7
			highlight.OutlineColor = Color3.new(1, 0, 0)
			highlight.OutlineTransparency = 0
			highlight.Parent = blockModel
			blockStates[blockModel].highlight = highlight
			print("Added Highlight zone for", blockModel.Name)
		end

		return true
	end)
	if not success then
		print("Error setting up", blockModel.Name, ":", err)
		return false
	end
	return true
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
	if blockStates[blockModel] then
		for _, conn in ipairs(blockStates[blockModel].touchConnections) do
			conn:Disconnect()
		end
		if activeTweens[blockModel] then
			activeTweens[blockModel]:Cancel()
			activeTweens[blockModel] = nil
		end
		if blockStates[blockModel].highlight then
			blockStates[blockModel].highlight:Destroy()
		end
		blockStates[blockModel] = nil
	end
	for i, taggedBlock in ipairs(taggedBlocks) do
		if taggedBlock == blockModel then
			table.remove(taggedBlocks, i)
			break
		end
	end
	originalCFrames[blockModel] = nil
end)