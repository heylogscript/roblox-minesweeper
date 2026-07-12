--!strict
-- FlagSystem — manages placing and removing flags on cells.

local BoardManager = require(script.Parent.BoardManager)

local FlagSystem = {}

function FlagSystem.ToggleFlag(board: BoardManager.Board, x: number, y: number): boolean
	local cell = BoardManager.GetCell(x, y)
	if cell == nil or cell.IsRevealed then
		return false
	end
	cell.HasFlag = not cell.HasFlag
	return true
end

function FlagSystem.SetFlag(board: BoardManager.Board, x: number, y: number): boolean
	local cell = BoardManager.GetCell(x, y)
	if cell == nil or cell.IsRevealed or cell.HasFlag then
		return false
	end
	cell.HasFlag = true
	return true
end

function FlagSystem.RemoveFlag(board: BoardManager.Board, x: number, y: number): boolean
	local cell = BoardManager.GetCell(x, y)
	if cell == nil or not cell.HasFlag then
		return false
	end
	cell.HasFlag = false
	return true
end

function FlagSystem.GetFlagCount(board: BoardManager.Board): number
	local count = 0
	for _, cell in ipairs(board.Cells) do
		if cell.HasFlag then
			count += 1
		end
	end
	return count
end

return FlagSystem
