--!strict
-- ClientBoardManager — stores the received board snapshot on the client.

local ClientBoardManager = {}

export type ClientCell = {
	X: number,
	Y: number,
	IsRevealed: boolean,
	HasFlag: boolean,
	AdjacentMines: number,
}

export type ClientBoard = {
	Width: number,
	Height: number,
	Cells: { ClientCell },
	MineCount: number?,
}

local CurrentBoard: ClientBoard? = nil

function ClientBoardManager.SetBoard(board: ClientBoard): ()
	CurrentBoard = board
end

function ClientBoardManager.GetBoard(): ClientBoard?
	return CurrentBoard
end

function ClientBoardManager.Clear(): ()
	CurrentBoard = nil
end

function ClientBoardManager.HasBoard(): boolean
	return CurrentBoard ~= nil
end

function ClientBoardManager.GetCell(x: number, y: number): ClientCell?
	if CurrentBoard == nil then
		return nil
	end
	if x < 1 or x > CurrentBoard.Width or y < 1 or y > CurrentBoard.Height then
		return nil
	end
	return CurrentBoard.Cells[(y - 1) * CurrentBoard.Width + x]
end

return ClientBoardManager
