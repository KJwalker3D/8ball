local Players = game:GetService("Players")
local ball = workspace:WaitForChild("Magic8Ball"):WaitForChild("ball")

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		-- Wait for character to load
		wait(0.1)
		local humanoidRootPart = character:WaitForChild("HumanoidRootPart")
		local spawnPos = workspace:WaitForChild("SpawnLocation").Position
		-- Direction from spawn to ball
		local lookDirection = Vector3.new(5, 0, 10)
		-- Set CFrame: position at spawn, facing ball
		humanoidRootPart.CFrame = CFrame.new(spawnPos) * CFrame.lookAt(Vector3.new(0, 0, 0), lookDirection)
		print("Spawned facing ball at " .. tostring(ball.Position))
	end)
end)