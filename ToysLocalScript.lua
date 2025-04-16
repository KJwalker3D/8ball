local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

task.wait(5)

local function createHovering8Ball(player)
	local central8Ball = workspace:FindFirstChild("CentralMagic8Ball")
	if not central8Ball then
		warn("CentralMagic8Ball not found in the workspace.")
		return
	end

	local character = player.Character or player.CharacterAdded:Wait()
	local humanoidRootPart = character:WaitForChild("HumanoidRootPart")

	local hovering8Ball = central8Ball:Clone()
	hovering8Ball.Parent = workspace
	hovering8Ball.Name = "Hovering8Ball"
	hovering8Ball:ScaleTo(0.01)  -- Scale to 10% of the original size

	RunService.RenderStepped:Connect(function()
		if humanoidRootPart and hovering8Ball then
			local targetPosition = humanoidRootPart.Position + Vector3.new(0, 5, 0)
			local currentCFrame = hovering8Ball:GetPivot()
			local newCFrame = CFrame.new(currentCFrame.Position:Lerp(targetPosition, 0.1))
			hovering8Ball:PivotTo(newCFrame)
		end
	end)
end

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function()
		createHovering8Ball(player)
	end)
end)

for _, player in Players:GetPlayers() do
	if player.Character then
		createHovering8Ball(player)
	else
		player.CharacterAdded:Connect(function()
			createHovering8Ball(player)
		end)
	end
end

