-- ClientBoardSync — receives board snapshots from the server and publishes events.
-- Never calls rendering, HUD, or animation code directly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientBoardManager = require(ReplicatedStorage.Modules.Client.ClientBoardManager)
local ClientGameState = require(ReplicatedStorage.Modules.Client.ClientGameState)
local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)
local UIEvents = require(ReplicatedStorage.Modules.Shared.Events.UIEvents)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local requestBoard = remotes:WaitForChild("RequestBoard")
local boardUpdate = remotes:WaitForChild("BoardUpdate")
local gameEnded = remotes:WaitForChild("GameEnded")
local prepareForBoard = remotes:WaitForChild("PrepareForBoard")

local function onBoardReceived(clientBoard: any): ()
	if ClientGameState.IgnoreUpdates then
		return
	end

	if ClientGameState.NeedsNewGame then
		ClientGameState.NeedsNewGame = false
		RoundEvents.BoardCreated:Fire(clientBoard)
		UIEvents.GameStarted:Fire()
	end

	ClientBoardManager.SetBoard(clientBoard)
	RoundEvents.BoardUpdated:Fire(clientBoard)

	local flagCount = 0
	for _, cell in ipairs(clientBoard.Cells) do
		if cell.HasFlag then
			flagCount += 1
		end
	end

	local mineCount = if type(clientBoard.MineCount) == "number" then clientBoard.MineCount else 0
	local remainingMines = math.max(0, mineCount - flagCount)
	UIEvents.UpdateMineCounter:Fire(remainingMines)
	UIEvents.UpdateFlagCounter:Fire(flagCount)
end

gameEnded.OnClientEvent:Connect(function(result: string, minePositions: { { x: number, y: number } }?)
	ClientGameState.IgnoreUpdates = true
	ClientGameState.NeedsNewGame = true
	if result == "lost" then
		UIEvents.ShowDefeat:Fire(minePositions)
	else
		UIEvents.ShowVictory:Fire(minePositions)
	end
end)

requestBoard.OnClientEvent:Connect(onBoardReceived)
boardUpdate.OnClientEvent:Connect(onBoardReceived)

prepareForBoard.OnClientEvent:Connect(function()
	ClientGameState.IgnoreUpdates = false
	ClientGameState.NeedsNewGame = true
end)

requestBoard:FireServer()
