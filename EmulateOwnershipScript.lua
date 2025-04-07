local VIP_PASS_ID = 3259877070 -- Provided VIP Pass ID

-- Function to emulate the player having the VIP pass developer product
local function emulateVIPPassOwnership(player)
    -- Set a custom attribute to simulate VIP pass ownership
    player:SetAttribute("HasVIPPassDevProduct", true)
end

-- Connect to PlayerAdded event to handle new players
game.Players.PlayerAdded:Connect(function(player)
    emulateVIPPassOwnership(player)
    print("VIP Pass Dev Product?", player:GetAttribute("HasVIPPassDevProduct"))
end)

-- Iterate through all existing players and set the VIP pass attribute
for _, player in game.Players:GetPlayers() do
    emulateVIPPassOwnership(player)
    print("VIP Pass Dev Product?", player:GetAttribute("HasVIPPassDevProduct"))
end

