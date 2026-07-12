--!strict
-- RoundService — parameter storage and active-state tracking for the current round.
-- Pure data. Decision-making lives in RoundFlowController.

local Difficulties = require(script.Parent.Parent.Config.Difficulties)

local RoundService = {}

local CurrentRoundStarted: boolean = false
local PendingWidth: number = Difficulties.Normal.Width
local PendingHeight: number = Difficulties.Normal.Height
local PendingMineCount: number = Difficulties.Normal.Mines

function RoundService.SetDifficulty(width: number, height: number, mineCount: number): ()
	PendingWidth = width
	PendingHeight = height
	PendingMineCount = mineCount
end

function RoundService.GetDifficulty(): (number, number, number)
	return PendingWidth, PendingHeight, PendingMineCount
end

function RoundService.IsRoundActive(): boolean
	return CurrentRoundStarted
end

function RoundService.SetActive(active: boolean): ()
	CurrentRoundStarted = active
end

function RoundService.Reset(): ()
	CurrentRoundStarted = false
	PendingWidth = Difficulties.Normal.Width
	PendingHeight = Difficulties.Normal.Height
	PendingMineCount = Difficulties.Normal.Mines
end

return RoundService
