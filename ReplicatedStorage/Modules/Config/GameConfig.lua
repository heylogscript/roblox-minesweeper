--!strict
-- GameConfig — global game settings. Pure data, no logic.

local GameConfig = {}

-- Theme
GameConfig.DefaultTheme = "DefaultTheme"
GameConfig.DefaultAnimationEnabled = true

-- Lobby
GameConfig.MinPlayers = 1
GameConfig.MaxPlayers = 1
GameConfig.RoundCountdown = 10
GameConfig.AutoRestartDelay = 4

-- Board limits
GameConfig.MaximumBoardSize = 64
GameConfig.LargeBoardThreshold = 16

-- Movement
GameConfig.BoardSpawnHeight = 3
GameConfig.RaycastLength = 10
GameConfig.CharacterTimeout = 5

-- Timing
GameConfig.RevealCooldown = 0.15
GameConfig.FlagClickThrottle = 0.2
GameConfig.PostExplosionDelay = 2
GameConfig.ResultDisplayDuration = 4

-- Explosion effects
GameConfig.BlastRadius = 20
GameConfig.BlastPressure = 100000
GameConfig.DestroyJointRadiusPercent = 1
GameConfig.ForceRangeX = 400
GameConfig.ForceRangeYMin = 300
GameConfig.ForceRangeYMax = 600
GameConfig.ForceRangeZ = 400
GameConfig.FireSize = 3
GameConfig.FireHeat = 10

-- Lighting
GameConfig.AmbientColor = Color3.fromRGB(110, 115, 135)
GameConfig.Brightness = 1.5
GameConfig.OutdoorAmbient = Color3.fromRGB(90, 100, 130)
GameConfig.FogColor = Color3.fromRGB(100, 105, 120)
GameConfig.FogEnd = 800
GameConfig.FogStart = 200

-- UI display order
GameConfig.LobbyDisplayOrder = 10
GameConfig.ResultDisplayOrder = 20
GameConfig.ResultOverlayTransparency = 0.5

-- Debug
GameConfig.DebugLogging = false

return GameConfig
