local COIN_PACK_ID = 3258288474
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local buyVIPEvent = game.ReplicatedStorage:WaitForChild("BuyVIPEvent")

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShakeGui"
screenGui.Parent = playerGui

local clickSound = Instance.new("Sound")
clickSound.SoundId = "rbxassetid://9125397583"
clickSound.Parent = playerGui

-- Selection sound for personality buttons
local selectSound = Instance.new("Sound")
selectSound.SoundId = "rbxassetid://9125644905" -- Using existing DAILY_BONUS_SOUND for a pleasant chime
selectSound.Volume = 0.5
selectSound.Parent = playerGui

local currentBall = nil

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
coinGradient.Rotation = 90
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
shopButton.BackgroundColor3 = Color3.fromRGB(100, 80, 120) -- Muted purple
shopButton.Text = "Shop"
shopButton.TextScaled = true
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.Font = Enum.Font.SourceSansBold
shopButton.Parent = screenGui
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopButton
local shopGradient = Instance.new("UIGradient")
shopGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 100, 140)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 60, 100))} -- Purple gradient
shopGradient.Rotation = 90
shopGradient.Parent = shopButton

-- Question Frame
local questionFrame = Instance.new("Frame")
questionFrame.Size = UDim2.new(0, 400, 0, 380) -- Increased height to accommodate personality selection
questionFrame.Position = UDim2.new(0.5, -200, 0.5, -190)
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
qGradient.Rotation = 90
qGradient.Parent = questionFrame

-- Question Box
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

-- Personality Selection Frame
local personalityFrame = Instance.new("Frame")
personalityFrame.Size = UDim2.new(0, 340, 0, 60)
personalityFrame.Position = UDim2.new(0.5, -170, 0, 120)
personalityFrame.BackgroundTransparency = 1
personalityFrame.Parent = questionFrame

-- Hover effect function
local function addHoverEffect(button)
	local originalSize = button.Size
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 10, originalSize.Y.Scale, originalSize.Y.Offset + 5)}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {Size = originalSize}):Play()
	end)
end

-- Personality Buttons with Emojis
local personalities = {
	{name = "Angry", color = Color3.fromRGB(255, 0, 0), emoji = "rbxassetid://10724815587"}, -- 😣
	{name = "Mysterious", color = Color3.fromRGB(0, 0, 255), emoji = "rbxassetid://9730549605"}, -- 🪐
	{name = "Sweet", color = Color3.fromRGB(255, 105, 180), emoji = "rbxassetid://10724815282"}, -- 💗
	{name = "Sarcastic", color = Color3.fromRGB(0, 255, 0), emoji = "rbxassetid://10724815692"}, -- 😏
	{name = "Random", color = Color3.fromRGB(255, 255, 255), emoji = "rbxassetid://10724815036"} -- 🎲
}

local selectedPersonality = "Random"
local personalityButtons = {}

for i, personality in ipairs(personalities) do
	local button = Instance.new("TextButton")
	button.Size = UDim2.new(0, 60, 0, 60)
	button.Position = UDim2.new(0, (i-1) * 70, 0, 0)
	button.BackgroundColor3 = personality.color
	button.Text = "" -- No text, using emoji instead
	button.Parent = personalityFrame

	local buttonCorner = Instance.new("UICorner")
	buttonCorner.CornerRadius = UDim.new(0, 15)
	buttonCorner.Parent = button

	local buttonGradient = Instance.new("UIGradient")
	buttonGradient.Color = ColorSequence.new{
		ColorSequenceKeypoint.new(0, personality.color),
		ColorSequenceKeypoint.new(1, Color3.new(
			personality.color.R * 0.7,
			personality.color.G * 0.7,
			personality.color.B * 0.7
			))
	}
	buttonGradient.Rotation = 90
	buttonGradient.Parent = button

	-- Add emoji ImageLabel
	local emojiLabel = Instance.new("ImageLabel")
	emojiLabel.Size = UDim2.new(0, 40, 0, 40)
	emojiLabel.Position = UDim2.new(0.5, -20, 0.5, -20)
	emojiLabel.BackgroundTransparency = 1
	emojiLabel.Image = personality.emoji
	emojiLabel.Parent = button

	-- Add UIStroke for persistent outline on selection
	local buttonStroke = Instance.new("UIStroke")
	buttonStroke.Thickness = 2
	buttonStroke.Color = Color3.fromRGB(255, 255, 255)
	buttonStroke.Transparency = 1 -- Hidden by default
	buttonStroke.Parent = button

	-- Add hover effect
	addHoverEffect(button)

	-- Store button reference
	personalityButtons[personality.name] = button

	-- Handle selection
	button.MouseButton1Click:Connect(function()
		selectSound:Play()
		selectedPersonality = personality.name

		-- Scale animation for click feedback
		local originalSize = button.Size
		TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(0, originalSize.X.Offset + 10, 0, originalSize.Y.Offset + 10)
		}):Play()
		wait(0.1)
		TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
			Size = originalSize
		}):Play()

		-- Update all buttons' appearance
		for name, btn in pairs(personalityButtons) do
			if name == selectedPersonality then
				btn.BackgroundTransparency = 0
				btn:FindFirstChild("ImageLabel").ImageTransparency = 0
				btn:FindFirstChild("UIStroke").Transparency = 0 -- Show outline
			else
				btn.BackgroundTransparency = 0.5 -- More pronounced transparency
				btn:FindFirstChild("ImageLabel").ImageTransparency = 0.5
				btn:FindFirstChild("UIStroke").Transparency = 1 -- Hide outline
			end
		end
	end)
end

-- Set initial state for Random button
personalityButtons["Random"].BackgroundTransparency = 0
personalityButtons["Random"]:FindFirstChild("ImageLabel").ImageTransparency = 0
personalityButtons["Random"]:FindFirstChild("UIStroke").Transparency = 0

-- Shake Button
local shakeButton = Instance.new("TextButton")
shakeButton.Size = UDim2.new(0, 140, 0, 60)
shakeButton.Position = UDim2.new(0.5, -70, 0, 280)
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
shakeGradient.Rotation = 90
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
rGradient.Rotation = 90
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

-- Coin Popup Frame
local coinPopupFrame = Instance.new("Frame")
coinPopupFrame.Size = UDim2.new(0, 100, 0, 30)
coinPopupFrame.Position = UDim2.new(0, 150, 0, 60)
coinPopupFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
coinPopupFrame.BackgroundTransparency = 0.2
coinPopupFrame.Visible = false
coinPopupFrame.Parent = screenGui
local coinPopupCorner = Instance.new("UICorner")
coinPopupCorner.CornerRadius = UDim.new(0, 8)
coinPopupCorner.Parent = coinPopupFrame
local coinPopupGradient = Instance.new("UIGradient")
coinPopupGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))}
coinPopupGradient.Rotation = 90
coinPopupGradient.Parent = coinPopupFrame

local coinPopup = Instance.new("TextLabel")
coinPopup.Size = UDim2.new(1, -10, 1, 0)
coinPopup.Position = UDim2.new(0, 5, 0, 0)
coinPopup.BackgroundTransparency = 1
coinPopup.Text = "+5"
coinPopup.TextScaled = true
coinPopup.TextColor3 = Color3.fromRGB(255, 215, 0)
coinPopup.Font = Enum.Font.SourceSansBold
coinPopup.Parent = coinPopupFrame

-- Shop Frame
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 480, 0, 360)
shopFrame.Position = UDim2.new(0.5, -240, 0.5, -180)
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
sGradient.Rotation = 90
sGradient.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(0, 420, 0, 40)
shopTitle.Position = UDim2.new(0.5, -210, 0, 20)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "Shop"
shopTitle.TextScaled = true
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.Font = Enum.Font.SourceSansBold
shopTitle.Parent = shopFrame

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
coinPackGradient.Rotation = 90
coinPackGradient.Parent = coinPackButton

local vipButton = Instance.new("TextButton")
vipButton.Size = UDim2.new(0, 140, 0, 60)
vipButton.Position = UDim2.new(0.5, -70, 0, 240)
vipButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
vipButton.Text = "VIP Pass (50R$)"
vipButton.TextScaled = true
vipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
vipButton.Font = Enum.Font.SourceSansBold
vipButton.Parent = shopFrame
local vipCorner = Instance.new("UICorner")
vipCorner.CornerRadius = UDim.new(0, 15)
vipCorner.Parent = vipButton
local vipGradient = Instance.new("UIGradient")
vipGradient.Color = ColorSequence.new{ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)), ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 0))}
vipGradient.Rotation = 90
vipGradient.Parent = vipButton

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

addHoverEffect(shopButton)
addHoverEffect(shakeButton)
addHoverEffect(coinPackButton)
addHoverEffect(vipButton)
addHoverEffect(closeShopButton)

shakeButton.MouseButton1Click:Connect(function()
	if currentBall then
		clickSound:Play()
		questionFrame.Visible = false
		currentBall.ShakeSound:Play()
		shakeEvent:FireServer(currentBall, questionBox.Text, selectedPersonality)
	end
end)

shopButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	shopFrame.Visible = true
	questionFrame.Visible = false
	responseFrame.Visible = false
end)

coinPackButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	MarketplaceService:PromptProductPurchase(player, COIN_PACK_ID)
end)

vipButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	buyVIPEvent:FireServer()
end)

closeShopButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	shopFrame.Visible = false
end)

local function showCoinPopup(amount)
	if coinPopupFrame.Visible then wait(0.1) end
	coinPopup.Text = amount >= 0 and "+" .. amount or tostring(amount)
	coinPopup.TextColor3 = amount >= 0 and Color3.fromRGB(255, 215, 0) or Color3.fromRGB(255, 100, 100) -- Gold for gain, soft red for loss
	coinPopupFrame.Visible = true
	local tween = TweenService:Create(coinPopupFrame, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {Position = UDim2.new(0, 150, 0, 30), Transparency = 1})
	tween:Play()
	tween.Completed:Connect(function()
		coinPopupFrame.Visible = false
		coinPopupFrame.Transparency = 0
		coinPopupFrame.Position = UDim2.new(0, 150, 0, 60)
	end)
end

local function showResponse(data, coins, coinAmount)
	responseFrame.Visible = false
	responseFrame.BackgroundTransparency = 0.2
	responseFrame.Position = UDim2.new(0.5, -200, 0, 100)
	responseLabel.Text = data.response
	responseLabel.TextColor3 = data.personality.color
	responseLabel.Font = data.personality.font
	coinLabel.Text = "Coins: " .. coins
	questionFrame.Visible = false
	responseFrame.Visible = true
	showCoinPopup(coinAmount)
	wait(2)
	TweenService:Create(responseFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {BackgroundTransparency = 1, Position = UDim2.new(0.5, -200, 0, 80)}):Play()
	wait(0.5)
	responseFrame.Visible = false
	game.ReplicatedStorage:WaitForChild("PromptEnableEvent"):FireServer(data.ball)
end

shakeEvent.OnClientEvent:Connect(function(data, coins)
	if data.type == "Init" then
		coinLabel.Text = "Coins: " .. coins
	elseif data.type == "ShowQuestion" then
		currentBall = data.ball
		questionFrame.Visible = true
		coinLabel.Text = "Coins: " .. coins
	elseif data.type == "Response" then
		showResponse(data, coins, player:WaitForChild("VIP").Value and 10 or 5)
	elseif data.type == "Busy" then
		questionFrame.Visible = false
	end
end)