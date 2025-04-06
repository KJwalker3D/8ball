local COIN_PACK_ID = 3258288474 -- Replace with your Product ID


local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local rerollEvent = game.ReplicatedStorage:WaitForChild("RerollEvent")


-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShakeGui"
screenGui.Parent = playerGui

local clickSound = Instance.new("Sound") -- Add click sound
clickSound.SoundId = "rbxassetid://9125397583"
clickSound.Parent = playerGui

-- Coin Counter
local coinFrame = Instance.new("Frame")
coinFrame.Size = UDim2.new(0, 140, 0, 50)
coinFrame.Position = UDim2.new(0, 10, 0, 10)
coinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
coinFrame.BackgroundTransparency = 0.2
coinFrame.Parent = screenGui
local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 12)
coinCorner.Parent = coinFrame
local coinGradient = Instance.new("UIGradient")
coinGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))}
coinGradient.Rotation = 90 -- Vertical gradient
coinGradient.Parent = coinFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -20, 1, 0)
coinLabel.Position = UDim2.new(0, 10, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"
coinLabel.TextScaled = true
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.Font = Enum.Font.SourceSansBold
coinLabel.Parent = coinFrame

-- Shop Button
local shopButton = Instance.new("TextButton")
shopButton.Size = UDim2.new(0, 100, 0, 50)
shopButton.Position = UDim2.new(0, 160, 0, 10)
shopButton.BackgroundColor3 = Color3.fromRGB(0, 150, 150)
shopButton.Text = "Shop"
shopButton.TextScaled = true
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.Font = Enum.Font.SourceSansBold
shopButton.Parent = screenGui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopButton
local shopGradient = Instance.new("UIGradient")
shopGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 100))}
shopGradient.Rotation = 90 -- Vertical gradient
shopGradient.Parent = shopButton

-- Question Frame
local questionFrame = Instance.new("Frame")
questionFrame.Size = UDim2.new(0, 400, 0, 280)
questionFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
questionFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
questionFrame.BackgroundTransparency = 0.2
questionFrame.BorderSizePixel = 0
questionFrame.Visible = false
questionFrame.Parent = screenGui
local qCorner = Instance.new("UICorner")
qCorner.CornerRadius = UDim.new(0, 20)
qCorner.Parent = questionFrame
local qGradient = Instance.new("UIGradient")
qGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))}
qGradient.Rotation = 90 -- Vertical gradient
qGradient.Parent = questionFrame

local questionBox = Instance.new("TextBox")
questionBox.Size = UDim2.new(0, 340, 0, 70)
questionBox.Position = UDim2.new(0.5, -170, 0, 40)
questionBox.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
questionBox.PlaceholderText = "Ask the 8 Ball..."
questionBox.Text = ""
questionBox.TextScaled = true
questionBox.TextColor3 = Color3.fromRGB(200, 200, 200)
questionBox.Font = Enum.Font.SourceSans
questionBox.Parent = questionFrame
local qBoxCorner = Instance.new("UICorner")
qBoxCorner.CornerRadius = UDim.new(0, 15)
qBoxCorner.Parent = questionBox

local shakeButton = Instance.new("TextButton")
shakeButton.Size = UDim2.new(0, 140, 0, 60)
shakeButton.Position = UDim2.new(0.5, -70, 0, 180)
shakeButton.BackgroundColor3 = Color3.fromRGB(150, 0, 150)
shakeButton.Text = "Shake!"
shakeButton.TextScaled = true
shakeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shakeButton.Font = Enum.Font.SourceSansBold
shakeButton.Parent = questionFrame
local shakeCorner = Instance.new("UICorner")
shakeCorner.CornerRadius = UDim.new(0, 15)
shakeCorner.Parent = shakeButton
local shakeGradient = Instance.new("UIGradient")
shakeGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 200)), ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 100))}
shakeGradient.Rotation = 90 -- Vertical gradient
shakeGradient.Parent = shakeButton

-- Response Frame
local responseFrame = Instance.new("Frame")
responseFrame.Size = UDim2.new(0, 400, 0, 140)
responseFrame.Position = UDim2.new(0.5, -200, 0, 100)
responseFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
responseFrame.BackgroundTransparency = 0.2
responseFrame.BorderSizePixel = 0
responseFrame.Visible = false
responseFrame.Parent = screenGui
local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = UDim.new(0, 20)
rCorner.Parent = responseFrame
local rGradient = Instance.new("UIGradient")
rGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))}
rGradient.Rotation = 90 -- Vertical gradient
rGradient.Parent = responseFrame

local responseLabel = Instance.new("TextLabel")
responseLabel.Size = UDim2.new(0, 340, 0, 90)
responseLabel.Position = UDim2.new(0.5, -170, 0.5, -45)
responseLabel.BackgroundTransparency = 1
responseLabel.TextScaled = true
responseLabel.TextWrapped = true
responseLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
responseLabel.Font = Enum.Font.SourceSansBold
responseLabel.Parent = responseFrame

-- Coin Gain Popup
local coinPopup = Instance.new("TextLabel")
coinPopup.Size = UDim2.new(0, 100, 0, 30)
coinPopup.Position = UDim2.new(0, 150, 0, 60)
coinPopup.BackgroundTransparency = 1
coinPopup.Text = "+5"
coinPopup.TextScaled = true
coinPopup.TextColor3 = Color3.fromRGB(255, 215, 0)
coinPopup.Font = Enum.Font.SourceSansBold
coinPopup.Visible = false
coinPopup.Parent = screenGui

-- Shop Frame
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 400, 0, 280)
shopFrame.Position = UDim2.new(0.5, -200, 0.5, -140)
shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
shopFrame.BackgroundTransparency = 0.2
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui
local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = UDim.new(0, 20)
sCorner.Parent = shopFrame
local sGradient = Instance.new("UIGradient")
sGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))}
sGradient.Rotation = 90 -- Vertical gradient
sGradient.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(0, 340, 0, 40)
shopTitle.Position = UDim2.new(0.5, -170, 0, 20)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "Shop"
shopTitle.TextScaled = true
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.Font = Enum.Font.SourceSansBold
shopTitle.Parent = shopFrame

local rerollButton = Instance.new("TextButton")
rerollButton.Size = UDim2.new(0, 140, 0, 60)
rerollButton.Position = UDim2.new(0.5, -70, 0, 80)
rerollButton.BackgroundColor3 = Color3.fromRGB(255, 165, 0)
rerollButton.Text = "Reroll (100)"
rerollButton.TextScaled = true
rerollButton.TextColor3 = Color3.fromRGB(255, 255, 255)
rerollButton.Font = Enum.Font.SourceSansBold
rerollButton.Parent = shopFrame
local rerollCorner = Instance.new("UICorner")
rerollCorner.CornerRadius = UDim.new(0, 15)
rerollCorner.Parent = rerollButton
local rerollGradient = Instance.new("UIGradient")
rerollGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 100, 0))}
rerollGradient.Rotation = 90 -- Vertical gradient
rerollGradient.Parent = rerollButton

local coinPackButton = Instance.new("TextButton")
coinPackButton.Size = UDim2.new(0, 140, 0, 60)
coinPackButton.Position = UDim2.new(0.5, -70, 0, 160)
coinPackButton.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
coinPackButton.Text = "100 Coins (25R$)"
coinPackButton.TextScaled = true
coinPackButton.TextColor3 = Color3.fromRGB(255, 255, 255)
coinPackButton.Font = Enum.Font.SourceSansBold
coinPackButton.Parent = shopFrame
local coinPackCorner = Instance.new("UICorner")
coinPackCorner.CornerRadius = UDim.new(0, 15)
coinPackCorner.Parent = coinPackButton
local coinPackGradient = Instance.new("UIGradient")
coinPackGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)), ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200))}
coinPackGradient.Rotation = 90 -- Vertical gradient
coinPackGradient.Parent = coinPackButton

local closeShopButton = Instance.new("TextButton")
closeShopButton.Size = UDim2.new(0, 40, 0, 40)
closeShopButton.Position = UDim2.new(1, -50, 0, 10)
closeShopButton.BackgroundColor3 = Color3.fromRGB(200, 0, 0)
closeShopButton.Text = "X"
closeShopButton.TextScaled = true
closeShopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeShopButton.Font = Enum.Font.SourceSansBold
closeShopButton.Parent = shopFrame
local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 12)
closeCorner.Parent = closeShopButton

-- Sound
local shakeSound = Instance.new("Sound")
shakeSound.SoundId = "rbxassetid://18769017543" -- Spray can rattle sound by NayMecou
shakeSound.Parent = game.Workspace.Magic8Ball

-- Button Hover Effects
local function addHoverEffect(button)
	local originalSize = button.Size
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 10, originalSize.Y.Scale, originalSize.Y.Offset + 5)}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = originalSize}):Play()
	end)
end

addHoverEffect(shopButton)
addHoverEffect(shakeButton)
addHoverEffect(rerollButton)
addHoverEffect(coinPackButton)
addHoverEffect(closeShopButton)

-- Handle 8 Ball click
local ball = game.Workspace:WaitForChild("Magic8Ball")
local clickDetector = ball:WaitForChild("ClickDetector")

clickDetector.MouseClick:Connect(function()
	-- Handled by server
end)

-- Handle shake button
shakeButton.MouseButton1Click:Connect(function()
	clickSound:Play() -- Play on click
	questionFrame.Visible = false
	shakeSound:Play()
	shakeEvent:FireServer()
end)

-- Handle shop button
shopButton.MouseButton1Click:Connect(function()
	clickSound:Play() -- Play on click
	shopFrame.Visible = true
	questionFrame.Visible = false
	responseFrame.Visible = false
end)

-- Handle reroll
rerollButton.MouseButton1Click:Connect(function()
	clickSound:Play() -- Play on click
	rerollEvent:FireServer()
	shopFrame.Visible = false
end)

-- Handle coin pack
coinPackButton.MouseButton1Click:Connect(function()
	clickSound:Play() -- Play on click
	MarketplaceService:PromptProductPurchase(player, COIN_PACK_ID)
end)

-- Handle close shop
closeShopButton.MouseButton1Click:Connect(function()
	clickSound:Play() -- Play on click
	shopFrame.Visible = false
end)

-- Coin Popup Animation
local function showCoinPopup(amount)
	coinPopup.Text = "+" .. amount
	coinPopup.Visible = true
	local tween = TweenService:Create(coinPopup, TweenInfo.new(1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 150, 0, 30), Transparency = 1})
	tween:Play()
	tween.Completed:Connect(function()
		coinPopup.Visible = false
		coinPopup.Transparency = 0
		coinPopup.Position = UDim2.new(0, 150, 0, 60)
	end)
end

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
		showCoinPopup(5)
	end
end)