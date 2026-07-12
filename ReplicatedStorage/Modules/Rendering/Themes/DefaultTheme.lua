--!strict
-- DefaultTheme — owns every configurable visual value.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local DefaultTheme = {}

DefaultTheme.CellSize = 6
DefaultTheme.CellGap = 0.3
DefaultTheme.Spacing = DefaultTheme.CellSize + DefaultTheme.CellGap

DefaultTheme.CellRevealedHeight = 0.5
DefaultTheme.CellUnrevealedHeight = 1.2

DefaultTheme.BaseY = 0.6

DefaultTheme.UnrevealedColor = Color3.fromRGB(162, 162, 162)
DefaultTheme.RevealedColor = Color3.fromRGB(212, 212, 212)
DefaultTheme.BoardBgColor = Color3.fromRGB(128, 128, 128)
DefaultTheme.BoardBgHeight = 0.5

DefaultTheme.UnrevealedMaterial = Enum.Material.SmoothPlastic
DefaultTheme.RevealedMaterial = Enum.Material.SmoothPlastic
DefaultTheme.BoardBgMaterial = Enum.Material.Plastic

DefaultTheme.NumberColors = {
	[1] = Color3.fromRGB(0, 0, 255),
	[2] = Color3.fromRGB(0, 128, 0),
	[3] = Color3.fromRGB(255, 0, 0),
	[4] = Color3.fromRGB(0, 0, 128),
	[5] = Color3.fromRGB(128, 0, 0),
	[6] = Color3.fromRGB(0, 128, 128),
	[7] = Color3.fromRGB(0, 0, 0),
	[8] = Color3.fromRGB(128, 128, 128),
}

DefaultTheme.Font = Enum.Font.GothamBold
DefaultTheme.PixelsPerStud = 50

DefaultTheme.MineRevealColor = Color3.fromRGB(200, 50, 50)
DefaultTheme.MineText = "💣"
DefaultTheme.MineTextColor = Color3.fromRGB(255, 255, 255)

DefaultTheme.FlagTemplate = ReplicatedStorage:WaitForChild("FlagModel")

DefaultTheme.Animation = {
	Enabled = true,
	RevealDuration = 0.08,
	RevealScale = 0.9,
	FlagPopDuration = 0.12,
	FlagRemoveDuration = 0.1,
	FlagPopScale = 0.3,
	MineDuration = 0.18,
	MinePulseScale = 1.2,
	MineFlashColor = Color3.fromRGB(255, 50, 50),
}

DefaultTheme.Sounds = {
	Reveal = "rbxassetid://0",
	Flag = "rbxassetid://0",
	FlagRemove = "rbxassetid://0",
	Victory = "rbxassetid://0",
	Explosion = "rbxassetid://0",
	Start = "rbxassetid://0",
	Click = "rbxassetid://0",
}

return DefaultTheme
