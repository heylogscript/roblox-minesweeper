--!strict
-- ClientGameState — shared flags between client scripts.

local ClientGameState = {}

ClientGameState.NeedsNewGame = true
ClientGameState.IgnoreUpdates = false
ClientGameState.FlagClickTimestamp = 0

return ClientGameState
