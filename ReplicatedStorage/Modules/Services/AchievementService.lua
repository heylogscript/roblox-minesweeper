--!strict
-- AchievementService — event-driven achievement system.
-- Observes gameplay events and unlocks achievements.
-- Never modifies gameplay, board, rendering, or networking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)
local AchievementEvents = require(ReplicatedStorage.Modules.Shared.Events.AchievementEvents)
local AchievementsData = require(ReplicatedStorage.Modules.Data.Achievements)

local AchievementService = {}

-- ── state ────────────────────────────────────────────────

local unlocked: { [string]: boolean } = {}

local lifetimeCounters: { [string]: number } = {
	RevealCount = 0,
	FlagCount = 0,
	WinCount = 0,
	LossCount = 0,
}

local match = {
	flagsPlaced = 0,
	cellsRevealed = 0,
	cornerRevealed = false,
	longestChain = 0,
	currentChain = 0,
	startTime = 0,
	totalNonMineCells = 0,
	boardWidth = 0,
	boardHeight = 0,
}

local connections: { any } = {}
local chainTimer: any = nil

-- Group achievements by ConditionType for O(1) lookup
local byType: { [string]: { any } } = {}
for _, a in AchievementsData do
	local g = byType[a.ConditionType]
	if not g then
		g = {}
		byType[a.ConditionType] = g
	end
	table.insert(g, a)
end

-- ── helpers ──────────────────────────────────────────────

local function isUnlocked(id: string): boolean
	return unlocked[id] == true
end

local function doUnlock(id: string): ()
	if isUnlocked(id) then return end
	unlocked[id] = true
	AchievementEvents.AchievementUnlocked:Fire(AchievementsData[id])
end

--- Check all achievements of a given ConditionType with a lazy progress function.
local function checkType(conditionType: string, getProgress: () -> number): ()
	local group = byType[conditionType]
	if not group then return end
	local progress = getProgress()
	for _, achievement in ipairs(group) do
		if not isUnlocked(achievement.Id) and progress >= achievement.TargetValue then
			doUnlock(achievement.Id)
		end
	end
end

--- Check cumulative achievements (progress = lifetimeCounter[conditionType]).
local function checkCumulative(conditionType: string): ()
	checkType(conditionType, function(): number
		return lifetimeCounters[conditionType] or 0
	end)
end

-- ── chain tracking ───────────────────────────────────────

local function closeChain(): ()
	match.currentChain = 0
	chainTimer = nil
end

local function scheduleChainClose(): ()
	if chainTimer then
		chainTimer:Cancel()
	end
	chainTimer = task.delay(0.1, closeChain)
end

-- ── match helpers ────────────────────────────────────────

local function resetMatch(): ()
	match.flagsPlaced = 0
	match.cellsRevealed = 0
	match.cornerRevealed = false
	match.longestChain = 0
	match.currentChain = 0
	match.startTime = os.clock()
	match.totalNonMineCells = 0
	match.boardWidth = 0
	match.boardHeight = 0
end

-- ── event handlers ───────────────────────────────────────

local function onRoundStarted(width: number, height: number, mines: number): ()
	resetMatch()
	match.totalNonMineCells = (width * height) - mines
	match.boardWidth = width
	match.boardHeight = height
	AchievementEvents.AchievementProgress:Fire("RoundStarted", width, height, mines)
end

local function onBoardCreated(board: any): ()
	resetMatch()
	match.boardWidth = board.Width
	match.boardHeight = board.Height
	if type(board.MineCount) == "number" then
		match.totalNonMineCells = (board.Width * board.Height) - board.MineCount
	else
		local count = 0
		for _, c in ipairs(board.Cells) do
			if c.HasMine then count += 1 end
		end
		match.totalNonMineCells = (board.Width * board.Height) - count
	end
	AchievementEvents.AchievementProgress:Fire("BoardCreated", board)
end

local function onCellRevealed(x: number, y: number): ()
	match.cellsRevealed += 1
	lifetimeCounters.RevealCount += 1
	checkCumulative("RevealCount")

	-- Corner detection — unlock immediately on reveal
	local w = match.boardWidth
	local h = match.boardHeight
	if not match.cornerRevealed then
		if (x == 0 and y == 0)
			or (x == 0 and y == h - 1)
			or (x == w - 1 and y == 0)
			or (x == w - 1 and y == h - 1)
		then
			match.cornerRevealed = true
			checkType("RevealCorner", function(): number return 1 end)
		end
	end

	-- Chain tracking for flood fill detection
	match.currentChain += 1
	if match.currentChain > match.longestChain then
		match.longestChain = match.currentChain
		checkType("FloodFillSize", function(): number return match.longestChain end)
	end
	scheduleChainClose()

	AchievementEvents.AchievementProgress:Fire("CellRevealed", x, y)
end

local function onFlagPlaced(x: number, y: number): ()
	match.flagsPlaced += 1
	lifetimeCounters.FlagCount += 1
	match.currentChain = 0
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	checkCumulative("FlagCount")
	AchievementEvents.AchievementProgress:Fire("FlagPlaced", x, y)
end

local function onFlagRemoved(x: number, y: number): ()
	match.currentChain = 0
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	AchievementEvents.AchievementProgress:Fire("FlagRemoved", x, y)
end

local function finalizeMatch(result: string): ()
	local duration = os.clock() - match.startTime

	-- Finalise chain
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	if match.currentChain > match.longestChain then
		match.longestChain = match.currentChain
	end
	match.currentChain = 0

	if result == "Win" then
		lifetimeCounters.WinCount += 1
		checkCumulative("WinCount")

		checkType("WinInSeconds", function(): number return duration end)
		checkType("WinWithoutFlags", function(): number return if match.flagsPlaced == 0 then 1 else 0 end)
		checkType("PerfectGame", function(): number return if match.cellsRevealed >= match.totalNonMineCells then 1 else 0 end)
		checkType("FloodFillSize", function(): number return match.longestChain end)

	elseif result == "Loss" then
		lifetimeCounters.LossCount += 1
		checkCumulative("LossCount")
	end

	AchievementEvents.AchievementProgress:Fire("RoundEnd", result, duration)
end

local function onRoundWon(): ()
	finalizeMatch("Win")
end

local function onRoundLost(): ()
	finalizeMatch("Loss")
end

local function onBoardDestroyed(): ()
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	resetMatch()
	AchievementEvents.AchievementProgress:Fire("BoardDestroyed")
end

-- ── public API ───────────────────────────────────────────

function AchievementService.Create(): ()
	if #connections > 0 then return end
	table.insert(connections, RoundEvents.RoundStarted:Connect(onRoundStarted))
	table.insert(connections, RoundEvents.BoardCreated:Connect(onBoardCreated))
	table.insert(connections, RoundEvents.CellRevealed:Connect(onCellRevealed))
	table.insert(connections, RoundEvents.FlagPlaced:Connect(onFlagPlaced))
	table.insert(connections, RoundEvents.FlagRemoved:Connect(onFlagRemoved))
	table.insert(connections, RoundEvents.RoundWon:Connect(onRoundWon))
	table.insert(connections, RoundEvents.RoundLost:Connect(onRoundLost))
	table.insert(connections, RoundEvents.BoardDestroyed:Connect(onBoardDestroyed))
end

function AchievementService.Destroy(): ()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
end

function AchievementService.HasAchievement(id: string): boolean
	return isUnlocked(id)
end

function AchievementService.GetAchievement(id: string): any
	return AchievementsData[id]
end

function AchievementService.GetUnlocked(): { string }
	local result: { string } = {}
	for id in unlocked do
		table.insert(result, id)
	end
	return result
end

function AchievementService.GetProgress(id: string): number
	local achievement = AchievementsData[id]
	if not achievement then return 0 end
	if isUnlocked(id) then return achievement.TargetValue end

	if achievement.ConditionType == "RevealCount"
		or achievement.ConditionType == "FlagCount"
		or achievement.ConditionType == "WinCount"
		or achievement.ConditionType == "LossCount"
	then
		return lifetimeCounters[achievement.ConditionType] or 0
	end

	return 0
end

function AchievementService.UnlockAchievement(id: string): ()
	doUnlock(id)
end

function AchievementService.ResetProgress(): ()
	lifetimeCounters.RevealCount = 0
	lifetimeCounters.FlagCount = 0
	lifetimeCounters.WinCount = 0
	lifetimeCounters.LossCount = 0
	resetMatch()
end

function AchievementService.ResetAll(): ()
	lifetimeCounters.RevealCount = 0
	lifetimeCounters.FlagCount = 0
	lifetimeCounters.WinCount = 0
	lifetimeCounters.LossCount = 0
	unlocked = {}
	resetMatch()
end

-- ── auto-init ────────────────────────────────────────────

AchievementService.Create()

return AchievementService
