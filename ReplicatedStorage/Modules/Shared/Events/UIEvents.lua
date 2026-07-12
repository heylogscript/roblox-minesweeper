--!strict
-- UIEvents — reusable signals for UI updates. Fired by client code, consumed by HUD.

local Signal = require(script.Parent.Signal)

local UIEvents = {}

UIEvents.ShowVictory = Signal.new()
UIEvents.ShowDefeat = Signal.new()
UIEvents.UpdateMineCounter = Signal.new()
UIEvents.UpdateTimer = Signal.new()
UIEvents.FaceChanged = Signal.new()
UIEvents.UpdateFlagCounter = Signal.new()
UIEvents.GameStarted = Signal.new()

return UIEvents
