local cloud = script.Parent:WaitForChild("CloudPart")
local cloud2 = script.Parent:WaitForChild("CloudPart2")

local RunService = game:GetService("RunService")

-- Lock cloud properties
cloud.Anchored = true
cloud.CanCollide = false
cloud2.Anchored = true
cloud2.CanCollide = false

-- Ensure all parts in the model are anchored and non-collidable
for _, part in pairs(script.Parent:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = true
		part.CanCollide = false
	end
end

-- Hover setup
local baseCFrame = cloud.CFrame
local baseCFrame2 = cloud2.CFrame
local hoverAmplitude = 3
local hoverSpeed = 0.5

-- Hover animation loop
RunService.Heartbeat:Connect(function()
	local hoverOffset = Vector3.new(0, math.sin(os.clock() * hoverSpeed) * hoverAmplitude, 0)
	cloud.CFrame = baseCFrame + hoverOffset
	cloud2.CFrame = baseCFrame2 + hoverOffset
end)
