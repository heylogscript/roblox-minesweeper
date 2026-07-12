--!strict
-- StatisticsService — pure observer gameplay analytics.
-- Collects per-match and lifetime statistics by subscribing to events.
-- Never modifies gameplay, board, rendering, or networking.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)
local UIEvents = require(ReplicatedStorage.Modules.Shared.Events.UIEvents)
local RenderEvents = require(ReplicatedStorage.Modules.Shared.Events.RenderEvents)

local StatisticsService = {}

-- Per-match accumulator
local match = {
	startTime = 0,
	endTime = 0,
	duration = 0,
	difficulty = "",
	boardWidth = 0,
	boardHeight = 0,
	mineCount = 0,
	result = "",
	cellsRevealed = 0,
	flagsPlaced = 0,
	flagsRemoved = 0,
	incorrectFlags = 0,
	totalClicks = 0,
	revealClicks = 0,
	flagClicks = 0,
	longestRevealChain = 0,
	currentChain = 0,
	largestFloodFill = 0,
	clickTimestamps = {},
}

-- Lifetime accumulator
local lifetime = {
	totalMatches = 0,
	wins = 0,
	losses = 0,
	fastestWin = math.huge,
	totalTime = 0,
	totalCellsRevealed = 0,
	totalFlagsPlaced = 0,
	winStreak = 0,
	bestWinStreak = 0,
}

local matchActive = false
local connections = {}
local chainTimer = nil

-- ── helpers ────────────────────────────────────────────────

local function snapshotMatch(): {}
	local dur = if match.endTime > 0 then match.duration elseif matchActive then os.clock() - match.startTime else 0
	return {
		startTime = match.startTime,
		endTime = match.endTime,
		duration = dur,
		difficulty = match.difficulty,
		boardWidth = match.boardWidth,
		boardHeight = match.boardHeight,
		mineCount = match.mineCount,
		result = match.result,
		cellsRevealed = match.cellsRevealed,
		flagsPlaced = match.flagsPlaced,
		flagsRemoved = match.flagsRemoved,
		incorrectFlags = match.incorrectFlags,
		totalClicks = match.totalClicks,
		revealClicks = match.revealClicks,
		flagClicks = match.flagClicks,
		longestRevealChain = match.longestRevealChain,
		largestFloodFill = match.largestFloodFill,
	}
end

local function snapshotLifetime(): {}
	local fastestWin = if lifetime.fastestWin == math.huge then 0 else lifetime.fastestWin
	return {
		totalMatches = lifetime.totalMatches,
		wins = lifetime.wins,
		losses = lifetime.losses,
		winRate = lifetime.totalMatches > 0 and lifetime.wins / lifetime.totalMatches or 0,
		fastestWin = fastestWin,
		averageWinTime = lifetime.wins > 0 and lifetime.totalTime / lifetime.wins or 0,
		averageLossTime = lifetime.losses > 0 and lifetime.totalTime / lifetime.losses or 0,
		totalCellsRevealed = lifetime.totalCellsRevealed,
		totalFlagsPlaced = lifetime.totalFlagsPlaced,
		totalPlayTime = lifetime.totalTime,
		winStreak = lifetime.winStreak,
		bestWinStreak = lifetime.bestWinStreak,
	}
end

local function computeAccuracy(): number
	if match.revealClicks == 0 then return 0 end
	return match.cellsRevealed / match.revealClicks
end

local function computeCompletion(): number
	local total = (match.boardWidth * match.boardHeight) - match.mineCount
	if total <= 0 then return 0 end
	return math.min(match.cellsRevealed / total, 1)
end

local function computeAvgClickInterval(): number
	local n = #match.clickTimestamps
	if n < 2 then return 0 end
	local elapsed = match.clickTimestamps[n] - match.clickTimestamps[1]
	if elapsed <= 0 then return 0 end
	return elapsed / (n - 1)
end

local function emitStats(): ()
	local now = os.clock()
	RenderEvents.StatsUpdated:Fire({
		match = snapshotMatch(),
		lifetime = snapshotLifetime(),
		liveAccuracy = computeAccuracy(),
		liveCompletion = computeCompletion(),
		liveAvgInterval = computeAvgClickInterval(),
		liveDuration = if matchActive then now - match.startTime else match.duration,
	})
end

-- ── chain detection ───────────────────────────────────────

local function closeChain(): ()
	if match.currentChain > match.largestFloodFill then
		match.largestFloodFill = match.currentChain
	end
	match.currentChain = 0
	chainTimer = nil
end

local function scheduleChainClose(): ()
	if chainTimer then
		chainTimer:Cancel()
	end
	chainTimer = task.delay(0.1, closeChain)
end

-- ── event handlers ────────────────────────────────────────

local function onRoundStarted(width: number, height: number, mines: number): ()
	matchActive = true
	match.startTime = os.clock()
	match.endTime = 0
	match.duration = 0
	match.difficulty = ""
	match.boardWidth = width
	match.boardHeight = height
	match.mineCount = mines
	match.result = ""
	match.cellsRevealed = 0
	match.flagsPlaced = 0
	match.flagsRemoved = 0
	match.incorrectFlags = 0
	match.totalClicks = 0
	match.revealClicks = 0
	match.flagClicks = 0
	match.longestRevealChain = 0
	match.currentChain = 0
	match.largestFloodFill = 0
	match.clickTimestamps = {}
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	emitStats()
end

local function onBoardCreated(board: any): ()
	matchActive = true
	match.boardWidth = board.Width
	match.boardHeight = board.Height
	match.startTime = os.clock()
	if type(board.MineCount) == "number" then
		match.mineCount = board.MineCount
	else
		local count = 0
		for _, c in ipairs(board.Cells) do
			if c.HasMine then count += 1 end
		end
		match.mineCount = count
	end
	emitStats()
end

local function onCellRevealed(x: number, y: number): ()
	if not matchActive then return end
	match.cellsRevealed += 1
	match.totalClicks += 1
	match.revealClicks += 1
	match.currentChain += 1
	if match.currentChain > match.longestRevealChain then
		match.longestRevealChain = match.currentChain
	end
	table.insert(match.clickTimestamps, os.clock())
	scheduleChainClose()
	emitStats()
end

local function onFlagPlaced(x: number, y: number): ()
	if not matchActive then return end
	match.flagsPlaced += 1
	match.totalClicks += 1
	match.flagClicks += 1
	match.currentChain = 0
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	table.insert(match.clickTimestamps, os.clock())
	emitStats()
end

local function onFlagRemoved(x: number, y: number): ()
	if not matchActive then return end
	match.flagsRemoved += 1
	match.currentChain = 0
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	emitStats()
end

local function finalizeMatch(result: string): ()
	if not matchActive then return end
	matchActive = false
	match.endTime = os.clock()
	match.duration = match.endTime - match.startTime
	match.result = result

	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	if match.currentChain > match.largestFloodFill then
		match.largestFloodFill = match.currentChain
	end
	match.currentChain = 0

	lifetime.totalMatches += 1
	if result == "Win" then
		lifetime.wins += 1
		lifetime.winStreak += 1
		if lifetime.winStreak > lifetime.bestWinStreak then
			lifetime.bestWinStreak = lifetime.winStreak
		end
		if match.duration < lifetime.fastestWin then
			lifetime.fastestWin = match.duration
		end
	elseif result == "Loss" then
		lifetime.losses += 1
		lifetime.winStreak = 0
	end

	lifetime.totalTime += match.duration
	lifetime.totalCellsRevealed += match.cellsRevealed
	lifetime.totalFlagsPlaced += match.flagsPlaced

	emitStats()
end

local function onRoundWon(): ()
	finalizeMatch("Win")
end

local function onRoundLost(): ()
	finalizeMatch("Loss")
end

local function onBoardDestroyed(): ()
	if matchActive then
		finalizeMatch("Interrupted")
	end
end

-- ── public API ────────────────────────────────────────────

function StatisticsService.GetCurrentMatchStats(): {}
	return snapshotMatch()
end

function StatisticsService.GetLifetimeStats(): {}
	return snapshotLifetime()
end

function StatisticsService.ResetCurrentMatch(): ()
	matchActive = false
	match.startTime = 0
	match.endTime = 0
	match.duration = 0
	match.difficulty = ""
	match.boardWidth = 0
	match.boardHeight = 0
	match.mineCount = 0
	match.result = ""
	match.cellsRevealed = 0
	match.flagsPlaced = 0
	match.flagsRemoved = 0
	match.incorrectFlags = 0
	match.totalClicks = 0
	match.revealClicks = 0
	match.flagClicks = 0
	match.longestRevealChain = 0
	match.currentChain = 0
	match.largestFloodFill = 0
	match.clickTimestamps = {}
	if chainTimer then
		chainTimer:Cancel()
		chainTimer = nil
	end
	emitStats()
end

function StatisticsService.ResetLifetime(): ()
	lifetime.totalMatches = 0
	lifetime.wins = 0
	lifetime.losses = 0
	lifetime.fastestWin = math.huge
	lifetime.totalTime = 0
	lifetime.totalCellsRevealed = 0
	lifetime.totalFlagsPlaced = 0
	lifetime.winStreak = 0
	lifetime.bestWinStreak = 0
	emitStats()
end

function StatisticsService.ExportCurrentMatch(): {}
	local s = snapshotMatch()
	s.completionPercent = computeCompletion()
	s.revealAccuracy = computeAccuracy()
	s.avgClickInterval = computeAvgClickInterval()
	return s
end

-- ── initialization ────────────────────────────────────────

local function Create(): ()
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

Create()

return StatisticsService
