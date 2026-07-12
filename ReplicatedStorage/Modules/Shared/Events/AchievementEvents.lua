--!strict
-- AchievementEvents — reusable signals for achievement system updates.

local Signal = require(script.Parent.Signal)

local AchievementEvents = {}

AchievementEvents.AchievementUnlocked = Signal.new()
AchievementEvents.AchievementProgress = Signal.new()

return AchievementEvents
