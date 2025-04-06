-- This script should be local


print("preloading assets")
local ContentProvider = game:GetService("ContentProvider")
local assets = {
	"rbxassetid://17279854976", -- Skybox
	"rbxassetid://14500233914", -- Sparkles
	"rbxassetid://7709167392", -- Wisps
	"rbxassetid://12905962634", -- Question particles
	"rbxassetid://12905962634", -- Question mark decal
	"rbxassetid://18769017543" -- Shake Sound
}
ContentProvider:PreloadAsync(assets)
print("Assets preloaded:", #assets)