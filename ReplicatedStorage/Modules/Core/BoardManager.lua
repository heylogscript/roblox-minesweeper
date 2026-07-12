--!strict
-- BoardManager — owns the current Minesweeper board data.
-- No mine generation, reveal, or flag logic.

local BoardManager = {}

export type Cell = {
	X: number,
	Y: number,
	HasMine: boolean,
	IsRevealed: boolean,
	HasFlag: boolean,
	AdjacentMines: number,
}

export type Board = {
	Width: number,
	Height: number,
	Cells: { Cell },
	MineCount: number?,
}

local CurrentBoard: Board? = nil

function BoardManager.CreateBoard(width: number, height: number): Board
	if width <= 0 then
		error("Width must be greater than 0", 2)
	end
	if height <= 0 then
		error("Height must be greater than 0", 2)
	end

	local cells: { Cell } = {}
	for y = 1, height do
		for x = 1, width do
			cells[#cells + 1] = {
				X = x,
				Y = y,
				HasMine = false,
				IsRevealed = false,
				HasFlag = false,
				AdjacentMines = 0,
			}
		end
	end

	local board: Board = {
		Width = width,
		Height = height,
		Cells = cells,
	}

	CurrentBoard = board
	return board
end

function BoardManager.GetCell(x: number, y: number): Cell?
	if CurrentBoard == nil then
		return nil
	end
	if x < 1 or x > CurrentBoard.Width or y < 1 or y > CurrentBoard.Height then
		return nil
	end
	return CurrentBoard.Cells[(y - 1) * CurrentBoard.Width + x]
end

function BoardManager.IsInsideBoard(x: number, y: number): boolean
	if CurrentBoard == nil then
		return false
	end
	return x >= 1 and x <= CurrentBoard.Width and y >= 1 and y <= CurrentBoard.Height
end

function BoardManager.DestroyBoard(): ()
	CurrentBoard = nil
end

function BoardManager.GetBoard(): Board?
	return CurrentBoard
end

function BoardManager.HasBoard(): boolean
	return CurrentBoard ~= nil
end

local OFFSETS = {
	{ -1, -1 }, { 0, -1 }, { 1, -1 },
	{ -1, 0 },  { 1, 0 },
	{ -1, 1 },  { 0, 1 },  { 1, 1 },
}

function BoardManager.GetNeighbors(x: number, y: number): { Cell }
	if CurrentBoard == nil then
		return {}
	end
	local neighbors: { Cell } = {}
	for _, offset in ipairs(OFFSETS) do
		local cell = BoardManager.GetCell(x + offset[1], y + offset[2])
		if cell ~= nil then
			neighbors[#neighbors + 1] = cell
		end
	end
	return neighbors
end

return BoardManager
