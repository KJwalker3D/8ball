local sceneParticlesA = script.Parent:WaitForChild("SceneParticlesA")
local sceneParticlesB = script.Parent:WaitForChild("SceneParticlesB")
local sceneParticlesC = script.Parent:WaitForChild("SceneParticlesC")
local ceilingStars = script.Parent:WaitForChild("CeilingStars")



local RunService = game:GetService("RunService")

-- Lock cloud properties
sceneParticlesA.Anchored = true
sceneParticlesA.CanCollide = false
sceneParticlesB.Anchored = true
sceneParticlesB.CanCollide = false
sceneParticlesC.Anchored = true
sceneParticlesC.CanCollide = false
ceilingStars.Anchored = true
ceilingStars.CanCollide = false

-- Ensure all parts in the model are anchored and non-collidable
for _, part in pairs(script.Parent:GetDescendants()) do
	if part:IsA("BasePart") then
		part.Anchored = true
		part.CanCollide = false
	end
end

-- Hover setup
local baseCFrame = sceneParticlesA.CFrame
local baseCFrame2 = sceneParticlesB.CFrame
local baseCFrame3 = sceneParticlesC.CFrame
local baseCFrame4 = ceilingStars.CFrame


local hoverAmplitude = 15
local hoverSpeed = 0.5



-- Hover animation loop
RunService.Heartbeat:Connect(function()
	local hoverOffset = Vector3.new(0, math.sin(os.clock() * hoverSpeed) * hoverAmplitude, 0)
	sceneParticlesA.CFrame = baseCFrame + hoverOffset
	sceneParticlesB.CFrame = baseCFrame2 + hoverOffset
	sceneParticlesC.CFrame = baseCFrame3 + hoverOffset
	ceilingStars.CFrame = baseCFrame4 + hoverOffset


end)
