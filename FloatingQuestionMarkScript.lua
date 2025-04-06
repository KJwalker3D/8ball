local part = script.Parent
while true do
	part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(1), 0)
	part.Position = part.Position + Vector3.new(0, math.sin(os.time()) * 0.05, 0)
	wait(0.01)
end