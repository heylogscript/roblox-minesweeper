--!strict
-- RoundEvents — reusable signals for gameplay lifecycle. Fired by server code.

local Signal = require(script.Parent.Signal)

local RoundEvents = {}

RoundEvents.RoundStarted = Signal.new()
RoundEvents.RoundEnded = Signal.new()
RoundEvents.RoundWon = Signal.new()
RoundEvents.RoundLost = Signal.new()
RoundEvents.CellRevealed = Signal.new()
RoundEvents.FlagPlaced = Signal.new()
RoundEvents.FlagRemoved = Signal.new()
RoundEvents.BoardCreated = Signal.new()
RoundEvents.BoardUpdated = Signal.new()
RoundEvents.BoardDestroyed = Signal.new()

return RoundEvents
