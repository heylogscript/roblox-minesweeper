--!strict
-- GameRoundManager — pure gameplay logic for a Minesweeper round.
-- No lifecycle orchestration, no round decisions. Returns results only.

local BoardManager = require(script.Parent.BoardManager)
local MineGenerator = require(script.Parent.MineGenerator)
local NumberCalculator = require(script.Parent.NumberCalculator)
local RevealSystem = require(script.Parent.RevealSystem)
local FlagSystem = require(script.Parent.FlagSystem)
local WinChecker = require(script.Parent.WinChecker)
local RoundEvents = require(script.Parent.Parent.Shared.Events.RoundEvents)

local GameRoundManager = {}

local CurrentWidth: number? = nil
local CurrentHeight: number? = nil
local CurrentMineCount: number? = nil
local FirstRevealDone: boolean = false

function GameRoundManager.Start(width: number, height: number, mineCount: number): BoardManager.Board
	CurrentWidth = width
	CurrentHeight = height
	CurrentMineCount = mineCount
	FirstRevealDone = false

	local board = BoardManager.CreateBoard(width, height)
	board.MineCount = mineCount
	return board
end

function GameRoundManager.Reveal(x: number, y: number): (boolean, boolean, boolean)
	local board = BoardManager.GetBoard()
	if board == nil then
		return false, false, false
	end

	if not FirstRevealDone and CurrentMineCount ~= nil then
		FirstRevealDone = true
		MineGenerator.GenerateAvoiding(board, CurrentMineCount, x, y)
		NumberCalculator.Calculate(board)
	end

	local revealedAny, hitMine = RevealSystem.Reveal(board, x, y)
	RoundEvents.CellRevealed:Fire(x, y)

	local won = false
	if not hitMine then
		won = WinChecker.Check(board)
	end

	return revealedAny, hitMine, won
end

function GameRoundManager.ToggleFlag(x: number, y: number): boolean
	local board = BoardManager.GetBoard()
	if board == nil then
		return false
	end
	local cell = board.Cells[(y - 1) * board.Width + x]
	local hadFlag = cell and cell.HasFlag
	local success = FlagSystem.ToggleFlag(board, x, y)
	if success then
		if hadFlag then
			RoundEvents.FlagRemoved:Fire(x, y)
		else
			RoundEvents.FlagPlaced:Fire(x, y)
		end
	end
	return success
end

function GameRoundManager.GetBoard(): BoardManager.Board?
	return BoardManager.GetBoard()
end

function GameRoundManager.CheckWin(): boolean
	local board = BoardManager.GetBoard()
	if board == nil then
		return false
	end
	return WinChecker.Check(board)
end

function GameRoundManager.Reset(): ()
	CurrentWidth = nil
	CurrentHeight = nil
	CurrentMineCount = nil
	FirstRevealDone = false
end

return GameRoundManager
