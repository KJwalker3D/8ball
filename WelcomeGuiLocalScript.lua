local gui = script.Parent
local frame = gui:WaitForChild("Frame")
wait(2) -- Delay to cover load
frame:TweenSize(UDim2.new(0, 0, 1, 0), "Out", "Quad", 0.5, true)
wait(0.5)
gui.Enabled = false