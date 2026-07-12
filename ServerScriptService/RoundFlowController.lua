--!strict
-- RoundFlowController — orchestrates the complete match lifecycle.
-- Single coordinator that owns all round transitions.
-- Delegates gameplay to GameRoundManager, state to MatchManager,
-- and communicates progress via RoundEvents / RemoteEvents.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MatchManager = require(ReplicatedStorage.Modules.Core.MatchManager)
local GameRoundManager = require(ReplicatedStorage.Modules.Core.GameRoundManager)
local RoundService = require(ReplicatedStorage.Modules.Core.RoundService)
local BoardManager = require(ReplicatedStorage.Modules.Core.BoardManager)
local BoardSerializer = require(ReplicatedStorage.Modules.Core.BoardSerializer)
local Difficulties = require(ReplicatedStorage.Modules.Config.Difficulties)
local MatchTimer = require(ReplicatedStorage.Modules.Core.MatchTimer)
local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local boardUpdate = remotes:WaitForChild("BoardUpdate")
local gameEnded = remotes:WaitForChild("GameEnded")

local RoundFlowController = {}

local function sendBoardToPlayer(player: Player): ()
	local board = GameRoundManager.GetBoard()
	if board == nil then
		return
	end
	local clientBoard = BoardSerializer.Serialize(board)
	boardUpdate:FireClient(player, clientBoard)
end

local function sendBoardToAll(): ()
	local board = GameRoundManager.GetBoard()
	if board == nil then
		return
	end
	local clientBoard = BoardSerializer.Serialize(board)
	for _, player in ipairs(Players:GetPlayers()) do
		boardUpdate:FireClient(player, clientBoard)
	end
end

function RoundFlowController.StartRound(difficultyName: string): ()
	if MatchManager.HasMatch() then
		RoundFlowController.Cleanup()
	end

	local config = Difficulties[difficultyName]
	if config == nil then
		return
	end

	MatchManager.CreateMatch(difficultyName)
	RoundService.SetDifficulty(config.Width, config.Height, config.Mines)

	MatchManager.SetState("Countdown")
	MatchTimer.Reset()

	MatchManager.SetState("Playing")
	MatchTimer.Start()

	GameRoundManager.Start(config.Width, config.Height, config.Mines)
	RoundEvents.RoundStarted:Fire(config.Width, config.Height, config.Mines)
	RoundEvents.BoardCreated:Fire(GameRoundManager.GetBoard())
	RoundService.SetActive(true)

	sendBoardToAll()
end

function RoundFlowController.RevealCell(player: Player, x: number, y: number): ()
	if not RoundService.IsRoundActive() then
		return
	end

	local _, hitMine, won = GameRoundManager.Reveal(x, y)
	sendBoardToPlayer(player)

	if hitMine then
		RoundFlowController.EndRound("lost", player)
	elseif won then
		RoundFlowController.EndRound("won", player)
	end
end

function RoundFlowController.ToggleFlag(player: Player, x: number, y: number): ()
	if not RoundService.IsRoundActive() then
		return
	end

	GameRoundManager.ToggleFlag(x, y)
	sendBoardToPlayer(player)
end

function RoundFlowController.RequestBoard(player: Player): ()
	if not RoundService.IsRoundActive() then
		return
	end
	sendBoardToPlayer(player)
end

function RoundFlowController.EndRound(result: string, player: Player): ()
	MatchManager.SetState("Finished")
	MatchTimer.Stop()
	RoundService.SetActive(false)

	if result == "lost" then
		local board = GameRoundManager.GetBoard()
		local minePositions = {}
		if board then
			for _, cell in ipairs(board.Cells) do
				if cell.HasMine then
					table.insert(minePositions, { x = cell.X, y = cell.Y })
				end
			end
		end
		gameEnded:FireClient(player, "lost", minePositions)
		RoundEvents.RoundLost:Fire()
	else
		local board = GameRoundManager.GetBoard()
		local minePositions = {}
		if board then
			for _, cell in ipairs(board.Cells) do
				if cell.HasMine then
					table.insert(minePositions, { x = cell.X, y = cell.Y })
				end
			end
		end
		gameEnded:FireClient(player, "won", minePositions)
		RoundEvents.RoundWon:Fire(player)
	end
end

function RoundFlowController.Cleanup(): ()
	if not MatchManager.HasMatch() then
		return
	end

	MatchTimer.Stop()
	MatchTimer.Reset()
	RoundService.SetActive(false)
	RoundService.Reset()
	BoardManager.DestroyBoard()
	GameRoundManager.Reset()
	MatchManager.DestroyMatch()
	RoundEvents.BoardDestroyed:Fire()
end

return RoundFlowController
