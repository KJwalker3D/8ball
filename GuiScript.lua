--[[
    Configuration
    All game settings and constants in one place
]]
local CONFIG = {
    -- Product IDs
    COIN_PACK_ID = 3258288474,

    -- Asset IDs
    ASSET_IDS = {
        -- Sounds
        CLICK_SOUND = "rbxassetid://9125397583",
        SELECT_SOUND = "rbxassetid://9125644905",
        
        -- Emojis
        EMOJI_ANGRY = "rbxassetid://1146879696",
        EMOJI_MYSTERIOUS = "rbxassetid://91618616311321",
        EMOJI_SWEET = "rbxassetid://15541285772",
        EMOJI_SARCASTIC = "rbxassetid://1368994399",
        EMOJI_RANDOM = "rbxassetid://17084107864"
    },

    -- UI Settings
    UI = {
        -- Colors
        BACKGROUND_COLOR = Color3.fromRGB(30, 30, 40),
        BACKGROUND_TRANSPARENCY = 0.2,
        TEXT_COLOR = Color3.fromRGB(255, 255, 255),
        COIN_COLOR = Color3.fromRGB(255, 215, 0),
        SHOP_BUTTON_COLOR = Color3.fromRGB(100, 80, 120),
        SHAKE_BUTTON_COLOR = Color3.fromRGB(150, 0, 150),
        QUESTION_BOX_COLOR = Color3.fromRGB(40, 40, 50),
        QUESTION_TEXT_COLOR = Color3.fromRGB(200, 200, 200),
        CLOSE_BUTTON_COLOR = Color3.fromRGB(200, 0, 0),
        COIN_PACK_COLOR = Color3.fromRGB(0, 150, 255),
        VIP_BUTTON_COLOR = Color3.fromRGB(255, 215, 0),
        
        -- Sizes
        COIN_FRAME_SIZE = UDim2.new(0, 140, 0, 50),
        SHOP_BUTTON_SIZE = UDim2.new(0, 100, 0, 50),
        QUESTION_FRAME_SIZE = UDim2.new(0, 400, 0, 380),
        RESPONSE_FRAME_SIZE = UDim2.new(0, 400, 0, 140),
        SHOP_FRAME_SIZE = UDim2.new(0, 480, 0, 360),
        QUESTION_BOX_SIZE = UDim2.new(0, 340, 0, 70),
        PERSONALITY_FRAME_SIZE = UDim2.new(0, 340, 0, 60),
        SHAKE_BUTTON_SIZE = UDim2.new(0, 140, 0, 60),
        RESPONSE_LABEL_SIZE = UDim2.new(0, 340, 0, 90),
        COIN_POPUP_SIZE = UDim2.new(0, 100, 0, 30),
        SHOP_TITLE_SIZE = UDim2.new(0, 420, 0, 40),
        CLOSE_BUTTON_SIZE = UDim2.new(0, 40, 0, 40),
        
        -- Corner Radius
        CORNER_RADIUS = UDim.new(0, 12),
        LARGE_CORNER_RADIUS = UDim.new(0, 20),
        MEDIUM_CORNER_RADIUS = UDim.new(0, 15),
        SMALL_CORNER_RADIUS = UDim.new(0, 8),

        -- Positions
        COIN_FRAME_POSITION = UDim2.new(0, 10, 0, 10),
        SHOP_BUTTON_POSITION = UDim2.new(0, 160, 0, 10),
        QUESTION_FRAME_POSITION = UDim2.new(0.5, -200, 0.5, -190),
        QUESTION_BOX_POSITION = UDim2.new(0.5, -170, 0, 40),
        PERSONALITY_FRAME_POSITION = UDim2.new(0.5, -170, 0, 120),
        SHAKE_BUTTON_POSITION = UDim2.new(0.5, -70, 0, 280),
        RESPONSE_FRAME_POSITION = UDim2.new(0.5, -200, 0, 100),
        RESPONSE_LABEL_POSITION = UDim2.new(0.5, -170, 0.5, -45),
        COIN_POPUP_POSITION = UDim2.new(0, 150, 0, 60),
        SHOP_FRAME_POSITION = UDim2.new(0.5, -240, 0.5, -180),
        SHOP_TITLE_POSITION = UDim2.new(0.5, -210, 0, 20),
        CLOSE_BUTTON_POSITION = UDim2.new(1, -50, 0, 10)
    },

    -- Animation Settings
    ANIMATION = {
        HOVER_DURATION = 0.2,
        CLICK_DURATION = 0.1,
        COIN_POPUP_DURATION = 2.5,
        RESPONSE_DURATION = 2,
        FADE_DURATION = 0.5
    }
}

-- Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")
local TweenService = game:GetService("TweenService")

-- Player references
local player = Players.LocalPlayer or Players.PlayerAdded:Wait()
local playerGui = player:WaitForChild("PlayerGui")

-- Events
local shakeEvent = game.ReplicatedStorage:WaitForChild("ShakeEvent")
local buyVIPEvent = game.ReplicatedStorage:WaitForChild("BuyVIPEvent")

-- Sounds
local clickSound = Instance.new("Sound")
clickSound.SoundId = CONFIG.ASSET_IDS.CLICK_SOUND
clickSound.Parent = playerGui

local selectSound = Instance.new("Sound")
selectSound.SoundId = CONFIG.ASSET_IDS.SELECT_SOUND
selectSound.Volume = 0.5
selectSound.Parent = playerGui

-- State variables
local currentBall = nil
local selectedPersonality = "Random"

-- Personalities
local PERSONALITIES = {
    {name = "Angry", color = Color3.fromRGB(255, 0, 0), emoji = CONFIG.ASSET_IDS.EMOJI_ANGRY},
    {name = "Mysterious", color = Color3.fromRGB(0, 0, 255), emoji = CONFIG.ASSET_IDS.EMOJI_MYSTERIOUS},
    {name = "Sweet", color = Color3.fromRGB(255, 105, 180), emoji = CONFIG.ASSET_IDS.EMOJI_SWEET},
    {name = "Sarcastic", color = Color3.fromRGB(0, 255, 0), emoji = CONFIG.ASSET_IDS.EMOJI_SARCASTIC},
    {name = "Random", color = Color3.fromRGB(255, 255, 255), emoji = CONFIG.ASSET_IDS.EMOJI_RANDOM}
}

--[[
    UI Creation
    Functions for creating UI elements
]]

-- Create main ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "ShakeGui"
screenGui.Parent = playerGui

-- Create coin counter
local coinFrame = Instance.new("Frame")
coinFrame.Size = CONFIG.UI.COIN_FRAME_SIZE
coinFrame.Position = CONFIG.UI.COIN_FRAME_POSITION
coinFrame.BackgroundColor3 = CONFIG.UI.BACKGROUND_COLOR
coinFrame.BackgroundTransparency = CONFIG.UI.BACKGROUND_TRANSPARENCY
coinFrame.Parent = screenGui

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = CONFIG.UI.CORNER_RADIUS
coinCorner.Parent = coinFrame

local coinGradient = Instance.new("UIGradient")
coinGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
coinGradient.Rotation = 90
coinGradient.Parent = coinFrame

local coinLabel = Instance.new("TextLabel")
coinLabel.Size = UDim2.new(1, -20, 1, 0)
coinLabel.Position = UDim2.new(0, 10, 0, 0)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "Coins: 0"
coinLabel.TextScaled = true
coinLabel.TextColor3 = CONFIG.UI.COIN_COLOR
coinLabel.Font = Enum.Font.SourceSansBold
coinLabel.Parent = coinFrame

-- Create shop button
local shopButton = Instance.new("TextButton")
shopButton.Size = CONFIG.UI.SHOP_BUTTON_SIZE
shopButton.Position = CONFIG.UI.SHOP_BUTTON_POSITION
shopButton.BackgroundColor3 = CONFIG.UI.SHOP_BUTTON_COLOR
shopButton.Text = "Shop"
shopButton.TextScaled = true
shopButton.TextColor3 = CONFIG.UI.TEXT_COLOR
shopButton.Font = Enum.Font.SourceSansBold
shopButton.Parent = screenGui

local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = CONFIG.UI.CORNER_RADIUS
shopCorner.Parent = shopButton

local shopGradient = Instance.new("UIGradient")
shopGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 100, 140)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 60, 100))
}
shopGradient.Rotation = 90
shopGradient.Parent = shopButton

-- Create question frame
local questionFrame = Instance.new("Frame")
questionFrame.Size = CONFIG.UI.QUESTION_FRAME_SIZE
questionFrame.Position = CONFIG.UI.QUESTION_FRAME_POSITION
questionFrame.BackgroundColor3 = CONFIG.UI.BACKGROUND_COLOR
questionFrame.BackgroundTransparency = CONFIG.UI.BACKGROUND_TRANSPARENCY
questionFrame.BorderSizePixel = 0
questionFrame.Visible = false
questionFrame.Parent = screenGui

local qCorner = Instance.new("UICorner")
qCorner.CornerRadius = CONFIG.UI.LARGE_CORNER_RADIUS
qCorner.Parent = questionFrame

local qGradient = Instance.new("UIGradient")
qGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
qGradient.Rotation = 90
qGradient.Parent = questionFrame

-- Create question box
local questionBox = Instance.new("TextBox")
questionBox.Size = CONFIG.UI.QUESTION_BOX_SIZE
questionBox.Position = CONFIG.UI.QUESTION_BOX_POSITION
questionBox.BackgroundColor3 = CONFIG.UI.QUESTION_BOX_COLOR
questionBox.PlaceholderText = "Ask the 8 Ball..."
questionBox.Text = ""
questionBox.TextScaled = true
questionBox.TextColor3 = CONFIG.UI.QUESTION_TEXT_COLOR
questionBox.Font = Enum.Font.SourceSans
questionBox.Parent = questionFrame

local qBoxCorner = Instance.new("UICorner")
qBoxCorner.CornerRadius = CONFIG.UI.MEDIUM_CORNER_RADIUS
qBoxCorner.Parent = questionBox

-- Create personality selection frame
local personalityFrame = Instance.new("Frame")
personalityFrame.Size = CONFIG.UI.PERSONALITY_FRAME_SIZE
personalityFrame.Position = CONFIG.UI.PERSONALITY_FRAME_POSITION
personalityFrame.BackgroundTransparency = 1
personalityFrame.Parent = questionFrame

-- Create personality buttons
local personalityButtons = {}
for i, personality in ipairs(PERSONALITIES) do
    local button = Instance.new("TextButton")
    button.Size = UDim2.new(0, 60, 0, 60)
    button.Position = UDim2.new(0, (i-1) * 70, 0, 0)
    button.BackgroundColor3 = personality.color
    button.Text = ""
    button.Parent = personalityFrame

    local buttonCorner = Instance.new("UICorner")
    buttonCorner.CornerRadius = CONFIG.UI.MEDIUM_CORNER_RADIUS
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

    local emojiLabel = Instance.new("ImageLabel")
    emojiLabel.Size = UDim2.new(0, 40, 0, 40)
    emojiLabel.Position = UDim2.new(0.5, -20, 0.5, -20)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Image = personality.emoji
    emojiLabel.Parent = button

    local buttonStroke = Instance.new("UIStroke")
    buttonStroke.Thickness = 2
    buttonStroke.Color = Color3.fromRGB(255, 255, 255)
    buttonStroke.Transparency = 1
    buttonStroke.Parent = button

    personalityButtons[personality.name] = button
end

-- Set initial state for Random button
personalityButtons["Random"].BackgroundTransparency = 0
personalityButtons["Random"]:FindFirstChild("ImageLabel").ImageTransparency = 0
personalityButtons["Random"]:FindFirstChild("UIStroke").Transparency = 0

-- Create shake button
local shakeButton = Instance.new("TextButton")
shakeButton.Size = CONFIG.UI.SHAKE_BUTTON_SIZE
shakeButton.Position = CONFIG.UI.SHAKE_BUTTON_POSITION
shakeButton.BackgroundColor3 = CONFIG.UI.SHAKE_BUTTON_COLOR
shakeButton.Text = "Shake!"
shakeButton.TextScaled = true
shakeButton.TextColor3 = CONFIG.UI.TEXT_COLOR
shakeButton.Font = Enum.Font.SourceSansBold
shakeButton.Parent = questionFrame

local shakeCorner = Instance.new("UICorner")
shakeCorner.CornerRadius = CONFIG.UI.MEDIUM_CORNER_RADIUS
shakeCorner.Parent = shakeButton

local shakeGradient = Instance.new("UIGradient")
shakeGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(200, 0, 200)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(100, 0, 100))
}
shakeGradient.Rotation = 90
shakeGradient.Parent = shakeButton

-- Create response frame
local responseFrame = Instance.new("Frame")
responseFrame.Size = CONFIG.UI.RESPONSE_FRAME_SIZE
responseFrame.Position = CONFIG.UI.RESPONSE_FRAME_POSITION
responseFrame.BackgroundColor3 = CONFIG.UI.BACKGROUND_COLOR
responseFrame.BackgroundTransparency = CONFIG.UI.BACKGROUND_TRANSPARENCY
responseFrame.BorderSizePixel = 0
responseFrame.Visible = false
responseFrame.Parent = screenGui

local rCorner = Instance.new("UICorner")
rCorner.CornerRadius = CONFIG.UI.LARGE_CORNER_RADIUS
rCorner.Parent = responseFrame

local rGradient = Instance.new("UIGradient")
rGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
rGradient.Rotation = 90
rGradient.Parent = responseFrame

local responseLabel = Instance.new("TextLabel")
responseLabel.Size = CONFIG.UI.RESPONSE_LABEL_SIZE
responseLabel.Position = CONFIG.UI.RESPONSE_LABEL_POSITION
responseLabel.BackgroundTransparency = 1
responseLabel.TextScaled = true
responseLabel.TextWrapped = true
responseLabel.TextColor3 = CONFIG.UI.TEXT_COLOR
responseLabel.Font = Enum.Font.SourceSansBold
responseLabel.Parent = responseFrame

-- Create coin popup frame
local coinPopupFrame = Instance.new("Frame")
coinPopupFrame.Size = CONFIG.UI.COIN_POPUP_SIZE
coinPopupFrame.Position = CONFIG.UI.COIN_POPUP_POSITION
coinPopupFrame.BackgroundColor3 = CONFIG.UI.BACKGROUND_COLOR
coinPopupFrame.BackgroundTransparency = CONFIG.UI.BACKGROUND_TRANSPARENCY
coinPopupFrame.Visible = false
coinPopupFrame.Parent = screenGui

local coinPopupCorner = Instance.new("UICorner")
coinPopupCorner.CornerRadius = CONFIG.UI.SMALL_CORNER_RADIUS
coinPopupCorner.Parent = coinPopupFrame

local coinPopupGradient = Instance.new("UIGradient")
coinPopupGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
coinPopupGradient.Rotation = 90
coinPopupGradient.Parent = coinPopupFrame

local coinPopup = Instance.new("TextLabel")
coinPopup.Size = UDim2.new(1, -10, 1, 0)
coinPopup.Position = UDim2.new(0, 5, 0, 0)
coinPopup.BackgroundTransparency = 1
coinPopup.Text = "+5"
coinPopup.TextScaled = true
coinPopup.TextColor3 = CONFIG.UI.COIN_COLOR
coinPopup.Font = Enum.Font.SourceSansBold
coinPopup.Parent = coinPopupFrame

-- Create shop frame
local shopFrame = Instance.new("Frame")
shopFrame.Size = CONFIG.UI.SHOP_FRAME_SIZE
shopFrame.Position = CONFIG.UI.SHOP_FRAME_POSITION
shopFrame.BackgroundColor3 = CONFIG.UI.BACKGROUND_COLOR
shopFrame.BackgroundTransparency = CONFIG.UI.BACKGROUND_TRANSPARENCY
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.Parent = screenGui

local sCorner = Instance.new("UICorner")
sCorner.CornerRadius = CONFIG.UI.LARGE_CORNER_RADIUS
sCorner.Parent = shopFrame

local sGradient = Instance.new("UIGradient")
sGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
}
sGradient.Rotation = 90
sGradient.Parent = shopFrame

local shopTitle = Instance.new("TextLabel")
shopTitle.Size = CONFIG.UI.SHOP_TITLE_SIZE
shopTitle.Position = CONFIG.UI.SHOP_TITLE_POSITION
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "Shop"
shopTitle.TextScaled = true
shopTitle.TextColor3 = CONFIG.UI.TEXT_COLOR
shopTitle.Font = Enum.Font.SourceSansBold
shopTitle.Parent = shopFrame

local coinPackButton = Instance.new("TextButton")
coinPackButton.Size = CONFIG.UI.SHAKE_BUTTON_SIZE
coinPackButton.Position = UDim2.new(0.5, -70, 0, 160)
coinPackButton.BackgroundColor3 = CONFIG.UI.COIN_PACK_COLOR
coinPackButton.Text = "100 Coins (25R$)"
coinPackButton.TextScaled = true
coinPackButton.TextColor3 = CONFIG.UI.TEXT_COLOR
coinPackButton.Font = Enum.Font.SourceSansBold
coinPackButton.Parent = shopFrame

local coinPackCorner = Instance.new("UICorner")
coinPackCorner.CornerRadius = CONFIG.UI.MEDIUM_CORNER_RADIUS
coinPackCorner.Parent = coinPackButton

local coinPackGradient = Instance.new("UIGradient")
coinPackGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 200, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 100, 200))
}
coinPackGradient.Rotation = 90
coinPackGradient.Parent = coinPackButton

local vipButton = Instance.new("TextButton")
vipButton.Size = CONFIG.UI.SHAKE_BUTTON_SIZE
vipButton.Position = UDim2.new(0.5, -70, 0, 240)
vipButton.BackgroundColor3 = CONFIG.UI.VIP_BUTTON_COLOR
vipButton.Text = "VIP Pass (50R$)"
vipButton.TextScaled = true
vipButton.TextColor3 = CONFIG.UI.TEXT_COLOR
vipButton.Font = Enum.Font.SourceSansBold
vipButton.Parent = shopFrame

local vipCorner = Instance.new("UICorner")
vipCorner.CornerRadius = CONFIG.UI.MEDIUM_CORNER_RADIUS
vipCorner.Parent = vipButton

local vipGradient = Instance.new("UIGradient")
vipGradient.Color = ColorSequence.new{
    ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 0)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 150, 0))
}
vipGradient.Rotation = 90
vipGradient.Parent = vipButton

local closeShopButton = Instance.new("TextButton")
closeShopButton.Size = CONFIG.UI.CLOSE_BUTTON_SIZE
closeShopButton.Position = CONFIG.UI.CLOSE_BUTTON_POSITION
closeShopButton.BackgroundColor3 = CONFIG.UI.CLOSE_BUTTON_COLOR
closeShopButton.Text = "X"
closeShopButton.TextScaled = true
closeShopButton.TextColor3 = CONFIG.UI.TEXT_COLOR
closeShopButton.Font = Enum.Font.SourceSansBold
closeShopButton.Parent = shopFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = CONFIG.UI.CORNER_RADIUS
closeCorner.Parent = closeShopButton

--[[
    Utility Functions
    Helper functions for common operations
]]

-- Add hover effect to buttons
local function addHoverEffect(button)
    local originalSize = button.Size
    button.MouseEnter:Connect(function()
        TweenService:Create(button, TweenInfo.new(CONFIG.ANIMATION.HOVER_DURATION), {
            Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset + 10, originalSize.Y.Scale, originalSize.Y.Offset + 5)
        }):Play()
    end)
    button.MouseLeave:Connect(function()
        TweenService:Create(button, TweenInfo.new(CONFIG.ANIMATION.HOVER_DURATION), {
            Size = originalSize
        }):Play()
    end)
end

-- Show coin popup animation
local function showCoinPopup(amount)
    if coinPopupFrame.Visible then wait(0.1) end
    coinPopup.Text = amount >= 0 and "+" .. amount or tostring(amount)
    coinPopup.TextColor3 = amount >= 0 and CONFIG.UI.COIN_COLOR or Color3.fromRGB(255, 100, 100)
    coinPopupFrame.Visible = true
    local tween = TweenService:Create(coinPopupFrame, TweenInfo.new(CONFIG.ANIMATION.COIN_POPUP_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.new(0, 150, 0, 30),
        Transparency = 1
    })
    tween:Play()
    tween.Completed:Connect(function()
        coinPopupFrame.Visible = false
        coinPopupFrame.Transparency = 0
        coinPopupFrame.Position = CONFIG.UI.COIN_POPUP_POSITION
    end)
end

-- Show response with animation
local function showResponse(data, coins, rewardAmount)
    responseFrame.Visible = false
    responseFrame.BackgroundTransparency = CONFIG.UI.BACKGROUND_TRANSPARENCY
    responseFrame.Position = CONFIG.UI.RESPONSE_FRAME_POSITION
    responseLabel.Text = data.response
    responseLabel.TextColor3 = data.personality.color
    responseLabel.Font = data.personality.font
    coinLabel.Text = "Coins: " .. coins
    questionFrame.Visible = false
    responseFrame.Visible = true
    print("Client received reward: +" .. rewardAmount .. " coins, new total: " .. coins)
    showCoinPopup(rewardAmount)
    wait(CONFIG.ANIMATION.RESPONSE_DURATION)
    TweenService:Create(responseFrame, TweenInfo.new(CONFIG.ANIMATION.FADE_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1,
        Position = UDim2.new(0.5, -200, 0, 80)
    }):Play()
    wait(CONFIG.ANIMATION.FADE_DURATION)
    responseFrame.Visible = false
    game.ReplicatedStorage:WaitForChild("PromptEnableEvent"):FireServer(data.ball)
end

--[[
    Event Handlers
    Functions that handle various game events
]]

-- Add hover effects to buttons
addHoverEffect(shopButton)
addHoverEffect(shakeButton)
addHoverEffect(coinPackButton)
addHoverEffect(vipButton)
addHoverEffect(closeShopButton)

-- Handle personality button clicks
for name, button in pairs(personalityButtons) do
    button.MouseButton1Click:Connect(function()
        selectSound:Play()
        selectedPersonality = name

        -- Scale animation for click feedback
        local originalSize = button.Size
        TweenService:Create(button, TweenInfo.new(CONFIG.ANIMATION.CLICK_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.new(0, originalSize.X.Offset + 10, 0, originalSize.Y.Offset + 10)
        }):Play()
        wait(CONFIG.ANIMATION.CLICK_DURATION)
        TweenService:Create(button, TweenInfo.new(CONFIG.ANIMATION.CLICK_DURATION, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = originalSize
        }):Play()

        -- Update all buttons' appearance
        for btnName, btn in pairs(personalityButtons) do
            if btnName == selectedPersonality then
                btn.BackgroundTransparency = 0
                btn:FindFirstChild("ImageLabel").ImageTransparency = 0
                btn:FindFirstChild("UIStroke").Transparency = 0
            else
                btn.BackgroundTransparency = 0.5
                btn:FindFirstChild("ImageLabel").ImageTransparency = 0.5
                btn:FindFirstChild("UIStroke").Transparency = 1
            end
        end
    end)
end

-- Handle shake button click
shakeButton.MouseButton1Click:Connect(function()
    if currentBall then
        clickSound:Play()
        questionFrame.Visible = false
        currentBall.ShakeSound:Play()
        shakeEvent:FireServer(currentBall, questionBox.Text, selectedPersonality)
    end
end)

-- Handle shop button click
shopButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    shopFrame.Visible = true
    questionFrame.Visible = false
    responseFrame.Visible = false
end)

-- Handle coin pack button click
coinPackButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    MarketplaceService:PromptProductPurchase(player, CONFIG.COIN_PACK_ID)
end)

-- Handle VIP button click
vipButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    buyVIPEvent:FireServer()
end)

-- Handle close shop button click
closeShopButton.MouseButton1Click:Connect(function()
    clickSound:Play()
    shopFrame.Visible = false
end)

-- Handle shake event
shakeEvent.OnClientEvent:Connect(function(data, coins)
    if data.type == "Init" then
        coinLabel.Text = "Coins: " .. coins
    elseif data.type == "ShowQuestion" then
        currentBall = data.ball
        questionFrame.Visible = true
        coinLabel.Text = "Coins: " .. coins
    elseif data.type == "Response" then
        showResponse(data, coins, data.rewardAmount or 0)
    elseif data.type == "Busy" then
        questionFrame.Visible = false
    end
end)