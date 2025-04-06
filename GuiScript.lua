-- this script must be a local script in starterGui
print("GuiScript running for player")

local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")


-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShakeGui"
screenGui.Parent = playerGui
print("ScreenGui created")

-- Question Frame (just for testing, simplified)
local questionFrame = Instance.new("Frame")
questionFrame.Size = UDim2.new(0, 300, 0, 200)
questionFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
questionFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
questionFrame.BackgroundTransparency = 0.2
questionFrame.BorderSizePixel = 0
questionFrame.Visible = false
questionFrame.Parent = screenGui

local testLabel = Instance.new("TextLabel")
testLabel.Size = UDim2.new(0, 260, 0, 50)
testLabel.Position = UDim2.new(0.5, -130, 0.5, -25)
testLabel.Text = "GUI Test"
testLabel.TextScaled = true
testLabel.Parent = questionFrame

-- Test visibility
local ball = game.Workspace:WaitForChild("Magic8Ball") -- Adjust if named differently
local clickDetector = ball:WaitForChild("ClickDetector")

clickDetector.MouseClick:Connect(function()
	print("Client detected click!")
	questionFrame.Visible = true
end)

shakeEvent.OnClientEvent:Connect(function(final)
	print("Received shake event: " .. final.type)
	questionFrame.Visible = true -- Reuse frame for now
	testLabel.Text = final.responses[math.random(1, #final.responses)]
	testLabel.TextColor3 = final.color
	testLabel.Font = final.font
end)