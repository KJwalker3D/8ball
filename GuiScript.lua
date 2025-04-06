local Players = game:GetService("Players")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")

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

-- Shop Button
local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.new(0, 60, 0, 30)
shopButton.Position = UDim2.new(0, 120, 0, 10)
shopButton.BackgroundColor3 = Color3.fromRGB(0, 255, 0)
shopButton.Text = "Shop"
shopButton.TextScaled = true
shopButton.Parent = screenGui

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

-- Shop Frame
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 300, 0, 200)
shopFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
shopFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
shopFrame.BackgroundTransparency = 0.2
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local rerollButton = Instance.new("TextButton")
rerollButton.Size = UDim2.new(0, 100, 0, 40)
rerollButton.Position = UDim2.new(0.5, -50, 0, 20)
rerollButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
rerollButton.Text = "Reroll (100)"
rerollButton.TextScaled = true
rerollButton.Parent = shopFrame

local coinPackButton = Instance.new("TextButton")
coinPackButton.Size = UDim2.new(0, 100, 0, 40)
coinPackButton.Position = UDim2.new(0.5, -50, 0, 70)
coinPackButton.BackgroundColor3 = Color3.fromRGB(0, 255, 255)
coinPackButton.Text = "100 Coins (25R$)"
coinPackButton.TextScaled = true
coinPackButton.Parent = shopFrame

local closeShopButton = Instance.new("TextButton")
closeShopButton.Size = UDim2.new(0, 40, 0, 40)
closeShopButton.Position = UDim2.new(1, -50, 0, 10)
closeShopButton.BackgroundColor3 = Color3.fromRGB(255, 0, 0)
closeShopButton.Text = "X"
closeShopButton.TextScaled = true
closeShopButton.Parent = shopFrame

-- Handle 8 Ball click (client-side)
local ball = game.Workspace:WaitForChild("Magic8Ball")
local clickDetector = ball:WaitForChild("ClickDetector")

clickDetector.MouseClick:Connect(function()
	-- Handled by server via shakeEvent
end)

-- Handle shake button
shakeButton.MouseButton1Click:Connect(function()
	questionFrame.Visible = false
	shakeEvent:FireServer()
end)

-- Handle shop button
shopButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = true
	questionFrame.Visible = false
	responseFrame.Visible = false
end)

-- Handle reroll
rerollButton.MouseButton1Click:Connect(function()
	rerollEvent:FireServer()
	shopFrame.Visible = false
end)

-- Handle coin pack (placeholder)
coinPackButton.MouseButton1Click:Connect(function()
	print("Coin pack purchase placeholder - requires Marketplace setup")
end)

-- Handle close shop
closeShopButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

-- Update coins and response from server
shakeEvent.OnClientEvent:Connect(function(final, coinValue)
	coinLabel.Text = "Coins: " .. coinValue
	if final.type == "ShowQuestion" then
		questionFrame.Visible = true
		responseFrame.Visible = false
		shopFrame.Visible = false
	elseif final.type ~= "Init" then
		responseLabel.Text = final.responses[math.random(1, #final.responses)]
		responseLabel.TextColor3 = final.color
		responseLabel.Font = final.font
		responseFrame.Visible = true
	end
end)