--!strict
-- RenderEvents — reusable signals for rendering system. Reserved for future use.

local Signal = require(script.Parent.Signal)

local RenderEvents = {}

RenderEvents.ThemeChanged = Signal.new()
RenderEvents.AnimationsEnabledChanged = Signal.new()
RenderEvents.BoardRebuilt = Signal.new()
RenderEvents.StatsUpdated = Signal.new()

return RenderEvents
