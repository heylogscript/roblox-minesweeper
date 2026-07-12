--!strict
-- WinChecker — checks if all non-mine cells are revealed.

local BoardManager = require(script.Parent.BoardManager)

local WinChecker = {}

function WinChecker.Check(board: BoardManager.Board): boolean
	for _, cell in ipairs(board.Cells) do
		if not cell.HasMine and not cell.IsRevealed then
			return false
		end
	end
	return true
end

return WinChecker
