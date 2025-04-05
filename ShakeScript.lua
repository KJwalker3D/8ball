local ball = script.Parent -- The 8 Ball part
local clickDetector = ball:WaitForChild("ClickDetector")

local personalities = {
    {color = Color3.fromRGB(255, 0, 0), type = "Angry", responses = {
        "YES, YOU FOOL!", "NO, STOP WASTING MY TIME!", "MAYBE, IF YOU SHUT UP!",
        "YES, NOW GO AWAY!", "NO, YOU DON’T DESERVE IT!", "ASK AGAIN, I DARE YOU!",
        "YES, AND I HATE YOU FOR IT!", "NO, YOU’RE TOO DUMB!", "MAYBE, STOP BUGGING ME!",
        "YES, GRRRR!"
    }},
    {color = Color3.fromRGB(0, 0, 255), type = "Mysterious", responses = {
        "The stars say… yes.", "Shadows whisper… no.", "The void ponders… maybe.",
        "Fate aligns… yes.", "The cosmos denies… no.", "A riddle says… maybe.",
        "Eternity nods… yes.", "Darkness shrugs… no.", "The unknown hints… maybe.",
        "Destiny hums… yes."
    }},
    {color = Color3.fromRGB(255, 105, 180), type = "Sweet", responses = {
        "Oh sweetie, yes, so lovely!", "No, but you’re still amazing!", "Maybe, isn’t that fun?",
        "Yes, darling, perfect!", "No, cutie, try again!", "Maybe, you precious thing!",
        "Yes, oh how wonderful!", "No, but you’re adorable!", "Maybe, so exciting!",
        "Yes, my little star!"
    }},
    {color = Color3.fromRGB(0, 255, 0), type = "Sarcastic", responses = {
        "Yes, genius, obviously.", "No, shocker, huh?", "Maybe, if you’re lucky, dimwit.",
        "Yes, you finally got one right!", "No, what a surprise.", "Maybe, don’t hold your breath.",
        "Yes, wow, you’re a prodigy.", "No, try harder, loser.", "Maybe, who even cares?",
        "Yes, clap for yourself, moron."
    }}
}

local function shakeBall()
    for i = 1, 15 do -- 3-second cycle
        local rand = personalities[math.random(1, #personalities)]
        ball.Color = rand.color
        wait(0.2 - (i * 0.01)) -- Slows down
    end
    local final = personalities[math.random(1, #personalities)]
    ball.Color = final.color
    ball:SetAttribute("Personality", final.type)
    return final.responses[math.random(1, #final.responses)]
end

clickDetector.MouseClick:Connect(function(player)
    local response = shakeBall()
    print(response) -- Placeholder; we’ll add GUI later
end)