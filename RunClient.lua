local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local character = player.Character
local humanoid = character and character:FindFirstChildOfClass("Humanoid")
local rootPart = character and character:FindFirstChild("HumanoidRootPart")

local runRemote = ReplicatedStorage:WaitForChild("RunToggle", 5)
local isRunning = false
local walkSpeed = 7
local runSpeed = 22
local runAnimId = "" --rbxassetid://656118852" -- Default run; set to "" for Humanoid default or custom ID
local runTrack = nil
local ancestryConnection = nil

-- Load animation
local function setupAnimation()
	if not humanoid then
		return
	end
	if runTrack then
		runTrack:Stop(0)
		runTrack:Destroy()
		runTrack = nil
	end
	if runAnimId == "" then
		print("Using default Humanoid run animation for", player.Name)
		return -- Skip custom animation
	end
	local animator = humanoid:FindFirstChildOfClass("Animator") or Instance.new("Animator")
	animator.Parent = humanoid
	local anim = Instance.new("Animation")
	anim.AnimationId = runAnimId
	pcall(function()
		runTrack = animator:LoadAnimation(anim)
		if runTrack then
			runTrack.Priority = Enum.AnimationPriority.Movement
			print("Loaded run animation", runAnimId, "for", player.Name)
		else
			warn("Failed to load run animation", runAnimId)
		end
	end)
end

-- Update run state
local function updateRunState(running)
	if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end
	-- Skip if sliding (adjust if SlideManager uses a marker)
	local isSliding = character and character:FindFirstChild("Sliding")
	if isSliding then
		if isRunning then
			isRunning = false
			if runTrack and runTrack.IsPlaying then
				runTrack:Stop(0.1)
			end
		end
		return
	end
	isRunning = running
	humanoid.WalkSpeed = running and runSpeed or walkSpeed
	if runTrack then
		if running and not runTrack.IsPlaying then
			runTrack:Play(0.1)
			print("Playing run animation")
		elseif not running and runTrack.IsPlaying then
			runTrack:Stop(0.1)
			print("Stopped run animation")
		end
	end
	if runRemote then
		runRemote:FireServer(running)
	end
end

-- Handle input
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		updateRunState(true)
	end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
	if gameProcessed or not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end
	if input.KeyCode == Enum.KeyCode.LeftShift or input.KeyCode == Enum.KeyCode.RightShift then
		updateRunState(false)
	end
end)

-- Handle character changes
local function onCharacterAdded(char)
	character = char
	humanoid = char:WaitForChild("Humanoid", 5)
	rootPart = char:WaitForChild("HumanoidRootPart", 5)
	if not humanoid or not rootPart then
		warn("Character missing Humanoid or RootPart for", player.Name)
		return
	end
	-- Disconnect old cleanup
	if ancestryConnection then
		ancestryConnection:Disconnect()
		ancestryConnection = nil
	end
	-- Setup new cleanup
	ancestryConnection = humanoid.AncestryChanged:Connect(function()
		if humanoid and not humanoid:IsDescendantOf(workspace) then
			if runTrack and runTrack.IsPlaying then
				runTrack:Stop(0)
			end
			isRunning = false
			if runRemote then
				runRemote:FireServer(false)
			end
			print("Reset run state for", player.Name, "on character removal")
		end
	end)
	setupAnimation()
	if isRunning then
		updateRunState(true)
	else
		humanoid.WalkSpeed = walkSpeed
	end
end

player.CharacterAdded:Connect(onCharacterAdded)
if player.Character then
	onCharacterAdded(player.Character)
end