--!strict
-- RevealSystem — reveals cells and flood-fills empty regions.

local BoardManager = require(script.Parent.BoardManager)

local RevealSystem = {}

function RevealSystem.Reveal(board: BoardManager.Board, x: number, y: number): (boolean, boolean)
	local startCell = BoardManager.GetCell(x, y)
	if startCell == nil then
		return false, false
	end
	if startCell.IsRevealed then
		return false, false
	end
	if startCell.HasFlag then
		return false, false
	end

	startCell.IsRevealed = true

	if startCell.HasMine then
		return true, true
	end

	if startCell.AdjacentMines > 0 then
		return true, false
	end

	local queue: { BoardManager.Cell } = { startCell }
	local index = 1
	local revealedAny = true

	while index <= #queue do
		local current = queue[index]
		index += 1

		for _, neighbor in ipairs(BoardManager.GetNeighbors(current.X, current.Y)) do
			if neighbor.IsRevealed or neighbor.HasMine or neighbor.HasFlag then
				continue
			end

			neighbor.IsRevealed = true
			revealedAny = true

			if neighbor.AdjacentMines == 0 then
				queue[#queue + 1] = neighbor
			end
		end
	end

	return revealedAny, false
end

return RevealSystem
