local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HUDController = require(ReplicatedStorage.Modules.Client.HUD.HUDController)

local player = game:GetService("Players").LocalPlayer
player:WaitForChild("PlayerGui")

HUDController.Create()
