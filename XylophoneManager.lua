local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("XylophoneManager started")

-- Configuration
local NOTES = {"C4", "D4", "E4", "F4", "G4", "A4", "B4", "C5", "D5"} -- 9 bars
local SOUND_ID = "rbxassetid://7157832561" -- Single xylophone note
local PITCHES = {1.0, 1.122, 1.26, 1.335, 1.498, 1.682, 1.888, 2.0, 2.244} -- C4 to D5
local DEBOUNCE_TIME = 1 -- Prevent sound spam
local DIP_DISTANCE = 0.5 -- Studs to dip (optional)
local DIP_TIME = 0.2 -- Seconds for dip animation

-- Track state
local barStates = {} -- [bar] = {lastPlayed, tween}
local xylophone = nil

-- Play sound and animate
local function playBar(bar, noteIndex)
	local state = barStates[bar]
	if state.lastPlayed and tick() - state.lastPlayed < DEBOUNCE_TIME then
		return
	end
	state.lastPlayed = tick()
	print("Playing note", NOTES[noteIndex], "on", bar.Name)

	-- Play sound
	local sound = bar:FindFirstChild("XylophoneSound")
	if not sound then
		sound = Instance.new("Sound")
		sound.Name = "XylophoneSound"
		sound.SoundId = SOUND_ID
		sound.Volume = 0.7
		sound.Parent = bar
		print("Created sound for", bar.Name)
	end
	sound.PlaybackSpeed = PITCHES[noteIndex]
	sound:Play()

	-- Animate (optional)
	if DIP_DISTANCE > 0 then
		if state.tween then
			state.tween:Cancel()
		end
		local originalY = bar.Position.Y
		local targetY = originalY - DIP_DISTANCE
		local tweenInfo = TweenInfo.new(DIP_TIME, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
		local tweenDown = TweenService:Create(bar, tweenInfo, {CFrame = CFrame.new(bar.Position.X, targetY, bar.Position.Z) * bar.CFrame.Rotation})
		local tweenUp = TweenService:Create(bar, tweenInfo, {CFrame = bar.CFrame})
		state.tween = tweenDown
		tweenDown:Play()
		tweenDown.Completed:Connect(function()
			if state.tween == tweenDown then
				state.tween = tweenUp
				tweenUp:Play()
				tweenUp.Completed:Connect(function()
					if state.tween == tweenUp then
						state.tween = nil
					end
				end)
			end
		end)
	end
end

-- Setup bar
local function setupBar(bar, index)
	if not bar:IsA("BasePart") then
		print("Invalid bar:", bar.Name, "is", bar.ClassName)
		return
	end
	barStates[bar] = {lastPlayed = 0, tween = nil}
	print("Setting up", bar.Name, "as", NOTES[index])

	-- Connect touch
	local touchConn = bar.Touched:Connect(function(hit)
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if player and hit.Name == "HumanoidRootPart" then
			local posY = hit.Position.Y
			print("Player", player.Name, "touched", bar.Name, "at Y =", posY)
			playBar(bar, index)
		end
	end)
	barStates[bar].touchConn = touchConn
end

-- Setup xylophone
local function setupXylophone()
	xylophone = workspace:FindFirstChild("Xylophone")
	if not xylophone then
		print("No Xylophone model found in Workspace")
		return
	end
	local bars = {}
	for i = 1, #NOTES do
		local bar = xylophone:FindFirstChild("Bar" .. i)
		if bar then
			table.insert(bars, bar)
		end
	end
	if #bars ~= #NOTES then
		print("Warning: Found", #bars, "bars, expected", #NOTES)
	end
	for i, bar in ipairs(bars) do
		setupBar(bar, i)
	end
end

setupXylophone()

-- Handle new xylophone
workspace.ChildAdded:Connect(function(child)
	if child.Name == "Xylophone" and child:IsA("Model") then
		print("New Xylophone added")
		setupXylophone()
	end
end)

-- Cleanup
workspace.ChildRemoved:Connect(function(child)
	if child == xylophone then
		for bar, state in pairs(barStates) do
			if state.touchConn then
				state.touchConn:Disconnect()
			end
			if state.tween then
				state.tween:Cancel()
			end
		end
		barStates = {}
		xylophone = nil
		print("Xylophone removed, cleaned up")
		setupXylophone()
	end
end)