local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local screenGui = playerGui:WaitForChild("ShakeGui")
local coinLabel = screenGui:WaitForChild("Frame"):WaitForChild("TextLabel")

-- Cache the last update time to prevent rapid updates
local lastUpdateTime = 0
local UPDATE_COOLDOWN = 0.1 -- Minimum time between updates in seconds

-- Function to update coin display with animation
local function updateCoinDisplay(newValue, rewardAmount)
    local currentTime = tick()
    if currentTime - lastUpdateTime < UPDATE_COOLDOWN then
        return -- Skip if too soon since last update
    end
    lastUpdateTime = currentTime

    -- Update the coin label with animation
    local oldValue = tonumber(coinLabel.Text:match("%d+")) or 0
    coinLabel.Text = "Coins: " .. newValue

    -- Create and show reward popup if there's a reward
    if rewardAmount and rewardAmount > 0 then
        local popup = Instance.new("Frame")
        popup.Name = "CoinPopup"
        popup.Size = UDim2.new(0, 100, 0, 30)
        popup.Position = UDim2.new(0, 150, 0, 60)
        popup.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        popup.BackgroundTransparency = 0.2
        popup.Parent = screenGui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = popup

        local gradient = Instance.new("UIGradient")
        gradient.Color = ColorSequence.new{
            ColorSequenceKeypoint.new(0, Color3.fromRGB(50, 50, 70)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 20, 30))
        }
        gradient.Rotation = 90
        gradient.Parent = popup

        local textLabel = Instance.new("TextLabel")
        textLabel.Size = UDim2.new(1, -10, 1, 0)
        textLabel.Position = UDim2.new(0, 5, 0, 0)
        textLabel.BackgroundTransparency = 1
        textLabel.Text = "+" .. rewardAmount
        textLabel.TextScaled = true
        textLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        textLabel.Font = Enum.Font.SourceSansBold
        textLabel.Parent = popup

        -- Animate the popup
        local tween = TweenService:Create(popup, TweenInfo.new(2.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = UDim2.new(0, 150, 0, 30),
            BackgroundTransparency = 1
        })
        tween:Play()
        tween.Completed:Connect(function()
            popup:Destroy()
        end)
    end
end

-- Connect to the coin update event
ReplicatedStorage:WaitForChild("CoinUpdateEvent").OnClientEvent:Connect(updateCoinDisplay)

print("[CoinUpdateClient] Initialized") 