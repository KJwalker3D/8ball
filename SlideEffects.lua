-- local script in starter player scripts

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local slideEvent = ReplicatedStorage:WaitForChild("SlideEffectEvent")
local camera = workspace.CurrentCamera

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "SlideEffectsGui"
screenGui.IgnoreGuiInset = true
screenGui.ResetOnSpawn = false
screenGui.Parent = player.PlayerGui

-- Create speed lines ImageLabel
local speedLines = Instance.new("ImageLabel")
speedLines.Name = "SpeedLines"
speedLines.Image = "rbxassetid://11030033771" -- White radial streaks
speedLines.Size = UDim2.new(1, 0, 1, 0) -- Full screen
speedLines.Position = UDim2.new(0, 0, 0, 0)
speedLines.BackgroundTransparency = 1
speedLines.ImageTransparency = 1 -- Hidden by default
speedLines.Parent = screenGui



-- Handle slide event
local particleEmitter = nil
local cameraConn = nil
slideEvent.OnClientEvent:Connect(function(isSliding, speed)
	if isSliding then
		print("Speed lines enabled")
		-- Show speed lines
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.In)
		local tween = TweenService:Create(speedLines, tweenInfo, {ImageTransparency = 0.3})
		tween:Play()

		-- Camera
		camera.CameraType = Enum.CameraType.Scriptable
		cameraConn = RunService.RenderStepped:Connect(function()
			local character = player.Character
			if not character or not character:FindFirstChild("HumanoidRootPart") then return end
			local pos = character.HumanoidRootPart.Position
			camera.CFrame = CFrame.new(pos + Vector3.new(0, 3, 6), pos)
		end)

	
	else
		print("Speed lines disabled")
		-- Hide speed lines
		local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out)
		local tween = TweenService:Create(speedLines, tweenInfo, {ImageTransparency = 1})
		tween:Play()

		-- Restore camera
		if cameraConn then
			cameraConn:Disconnect()
			cameraConn = nil
		end
		camera.CameraType = Enum.CameraType.Custom

	
	end
end)