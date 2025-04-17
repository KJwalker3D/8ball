local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local NotifyEvent = ReplicatedStorage:WaitForChild("NotifyEvent")
local shakeEvent = ReplicatedStorage:WaitForChild("ShakeEvent")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ShakeGui")
local coinPopupFrame = screenGui:WaitForChild("Frame")

local function showNotification(message, isError)
	local popup = coinPopupFrame:Clone()
	popup.Name = "NotificationPopup"
	popup.TextLabel.Text = message
	popup.TextLabel.TextColor3 = isError and Color3.fromRGB(255, 100, 100) or Color3.fromRGB(255, 215, 0)
	popup.Visible = true
	popup.Parent = screenGui

	local tween = TweenService:Create(popup, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0, 150, 0, 30),
		Transparency = 1
	})
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

NotifyEvent.OnClientEvent:Connect(function(data)
	if data.type == "Success" then
		showNotification(data.message, false)
	elseif data.type == "Error" then
		showNotification(data.message, true)
	end
end)

shakeEvent.OnClientEvent:Connect(function(data, coins)
	if data.type == "Init" or data.type == "Response" then
		local coinLabel = screenGui:WaitForChild("Frame"):WaitForChild("TextLabel")
		coinLabel.Text = "Coins: " .. coins
	end
end)

print("[EquipModelClient] Initialized")