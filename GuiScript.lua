local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShakeGui"
screenGui.Parent = playerGui

-- Coin Counter
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0, 100, 0, 30)
coinFrame.Position = UDim2.new(0, 10, 0, 10)
coinFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 0)
coinFrame.BackgroundTransparency = 0.5
coinFrame.Parent = screenGui

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, 0, 1, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"
coinLabel.TextScaled = true
coinLabel.TextColor3 = Color3.fromRGB(0, 0, 0)
coinLabel.Parent = coinFrame

-- Question Frame
local questionFrame = Instance.new("Frame")
questionFrame.Size = UDim2.new(0, 300, 0, 200)
questionFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
questionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
questionFrame.BackgroundTransparency = 0.2
questionFrame.BorderSizePixel = 0
questionFrame.Visible = false
questionFrame.Parent = screenGui

local questionBox = Instance.new("TextBox")
questionBox.Size = UDim2.new(0, 260, 0, 50)
questionBox.Position = UDim2.new(0.5, -130, 0, 20)
questionBox.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
questionBox.PlaceholderText = "Ask away!"
questionBox.Text = ""
questionBox.Parent = questionFrame

local shakeButton = Instance.new("TextButton")
shakeButton.Size = UDim2.new(0, 100, 0, 40)
shakeButton.Position = UDim2.new(0.5, -50, 0, 120)
shakeButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
shakeButton.Text = "Shake!"
shakeButton.TextScaled = true
shakeButton.Parent = questionFrame

-- Response Frame
local responseFrame = Instance.new("Frame")
responseFrame.Size = UDim2.new(0, 300, 0, 100)
responseFrame.Position = UDim2.new(0.5, -150, 0.5, -50)
responseFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
responseFrame.BackgroundTransparency = 0.2
responseFrame.BorderSizePixel = 0
responseFrame.Visible = false
responseFrame.Parent = screenGui

local responseLabel = Instance.new("TextLabel")
responseLabel.Size = UDim2.new(0, 260, 0, 60)
responseLabel.Position = UDim2.new(0.5, -130, 0.5, -30)
responseLabel.BackgroundTransparency = 1
responseLabel.TextScaled = true
responseLabel.TextWrapped = true
responseLabel.Parent = responseFrame

-- Coin Logic (client-side display, server will manage actual value)
local coins = 0
coinLabel.Text = "Coins: " .. coins

-- Handle 8 Ball click
local ball = game.Workspace:WaitForChild("Magic8Ball")
local clickDetector = ball:WaitForChild("ClickDetector")

clickDetector.MouseClick:Connect(function()
	questionFrame.Visible = true
	responseFrame.Visible = false
end)

-- Handle shake button
shakeButton.MouseButton1Click:Connect(function()
	questionFrame.Visible = false
	-- No need to trigger shake here; server handles it via ClickDetector
end)

-- Handle server response
shakeEvent.OnClientEvent:Connect(function(final)
	coins = coins + 5 -- Add 5 coins per question (server will sync later)
	coinLabel.Text = "Coins: " .. coins
	responseLabel.Text = final.responses[math.random(1, #final.responses)]
	responseLabel.TextColor3 = final.color
	responseLabel.Font = final.font
	responseFrame.Visible = true
end)