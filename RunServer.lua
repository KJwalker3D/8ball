local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local runRemote = ReplicatedStorage:WaitForChild("RunToggle")
local walkSpeed = 16
local runSpeed = 32
local maxSpeed = 32

runRemote.OnServerEvent:Connect(function(player, isRunning)
	local character = player.Character
	local humanoid = character and character:FindFirstChildOfClass("Humanoid")
	if not humanoid or humanoid:GetState() == Enum.HumanoidStateType.Dead then
		return
	end
	local targetSpeed = isRunning and runSpeed or walkSpeed
	if targetSpeed <= maxSpeed then
		humanoid.WalkSpeed = targetSpeed
		print(player.Name, isRunning and "started running" or "stopped running", "WalkSpeed:", targetSpeed)
	else
		warn("Invalid speed attempt by", player.Name, ":", targetSpeed)
	end
end)

Players.PlayerAdded:Connect(function(player)
	player.CharacterAdded:Connect(function(character)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.WalkSpeed = walkSpeed
	end)
end)