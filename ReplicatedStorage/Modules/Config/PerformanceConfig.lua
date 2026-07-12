--!strict
-- PerformanceConfig — client-side rendering thresholds. Pure data, no logic.

local PerformanceConfig = {}

PerformanceConfig.DisableAnimationsAbove = 16
PerformanceConfig.MaximumVisibleCells = 1024
PerformanceConfig.TargetFPS = 60
PerformanceConfig.EnableObjectPooling = false
PerformanceConfig.EnableLOD = false

return PerformanceConfig
