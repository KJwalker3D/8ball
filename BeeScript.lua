local bee = script.Parent
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- 🐝 Sound setup
local buzz = bee:FindFirstChild("BuzzSound") or Instance.new("Sound", bee)
buzz.Name = "BuzzSound"
buzz.SoundId = "rbxassetid://9113414362" -- Use your own ID if preferred
buzz.Looped = true
buzz.Volume = 0.5
buzz:Play()

-- 🔁 Flying parameters
local flyRadius = 50
local flyHeight = 10
local basePosition = bee.Position
local baseY = bee.Position.Y

-- 📌 Function to get a random target point
local function getRandomPosition()
	local x = math.random(-flyRadius, flyRadius)
	local y = math.random(2, flyHeight)
	local z = math.random(-flyRadius, flyRadius)
	return basePosition + Vector3.new(x, y, z)
end

-- ✨ Function to rotate to face target
local function rotateTowards(targetPos)
	local direction = (targetPos - bee.Position).Unit
	local lookCFrame = CFrame.new(bee.Position, bee.Position + direction)
	bee.CFrame = CFrame.new(bee.Position) * CFrame.Angles(0, lookCFrame.LookVector:Angle(Vector3.new(0, 0, -1)), 0)
end

-- 🎯 Random flight loop
local function flyRandomly()
	while true do
		local targetPos = getRandomPosition()
		local distance = (targetPos - bee.Position).Magnitude
		local randomSpeed = math.random(8, 16) / 2 -- random speed between 0.8 and 1.6
		local duration = distance / randomSpeed

		-- Rotate toward direction before flying
		rotateTowards(targetPos)

		local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(bee, tweenInfo, {Position = targetPos})
		tween:Play()
		tween.Completed:Wait()

		wait(math.random(1, 3)) -- rest before next move
	end
end

-- 🌊 Gentle hover effect
local hoverOffset = 0.3
local hoverSpeed = 2

RunService.Heartbeat:Connect(function()
	local newY = baseY + math.sin(tick() * hoverSpeed) * hoverOffset
	local pos = bee.Position
	bee.Position = Vector3.new(pos.X, newY, pos.Z)
end)

-- 🚀 Start flying
task.spawn(flyRandomly)
