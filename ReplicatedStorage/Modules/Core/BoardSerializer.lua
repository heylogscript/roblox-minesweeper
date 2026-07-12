--!strict
-- BoardSerializer — converts server board data into safe client data.

local BoardManager = require(script.Parent.BoardManager)

local BoardSerializer = {}

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

function BoardSerializer.Serialize(board: BoardManager.Board): ClientBoard
	local cells: { ClientCell } = {}
	for _, cell in ipairs(board.Cells) do
		cells[#cells + 1] = {
			X = cell.X,
			Y = cell.Y,
			IsRevealed = cell.IsRevealed,
			HasFlag = cell.HasFlag,
			AdjacentMines = cell.AdjacentMines,
		}
	end

	return {
		Width = board.Width,
		Height = board.Height,
		MineCount = board.MineCount,
		Cells = cells,
	}
end

return BoardSerializer
