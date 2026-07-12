--!strict
-- NumberCalculator — calculates AdjacentMines for every cell.

local BoardManager = require(script.Parent.BoardManager)

local NumberCalculator = {}

function NumberCalculator.Calculate(board: BoardManager.Board): ()
	for _, cell in ipairs(board.Cells) do
		cell.AdjacentMines = 0
		if cell.HasMine then
			continue
		end
		local count = 0
		for _, neighbor in ipairs(BoardManager.GetNeighbors(cell.X, cell.Y)) do
			if neighbor.HasMine then
				count += 1
			end
		end
		cell.AdjacentMines = count
	end
end

return NumberCalculator
