--!strict
-- MineGenerator — places mines on a Board.

local BoardManager = require(script.Parent.BoardManager)

local MineGenerator = {}

function MineGenerator.Generate(board: BoardManager.Board, mineCount: number): number
	if mineCount <= 0 then
		error("mineCount must be greater than 0", 2)
	end
	local totalCells = board.Width * board.Height
	if mineCount > totalCells then
		error("mineCount exceeds total cell count", 2)
	end

	local placed = 0
	while placed < mineCount do
		local x = math.random(1, board.Width)
		local y = math.random(1, board.Height)
		local cell = board.Cells[(y - 1) * board.Width + x]
		if not cell.HasMine then
			cell.HasMine = true
			placed += 1
		end
	end

	return placed
end

local function cellIndex(board: BoardManager.Board, x: number, y: number): number
	return (y - 1) * board.Width + x
end

function MineGenerator.GenerateAvoiding(board: BoardManager.Board, mineCount: number, safeX: number, safeY: number): number
	if mineCount <= 0 then
		error("mineCount must be greater than 0", 2)
	end

	local avoid: { [number]: boolean } = {}
	local function mark(x: number, y: number): ()
		if x < 1 or x > board.Width or y < 1 or y > board.Height then
			return
		end
		avoid[cellIndex(board, x, y)] = true
	end

	-- avoid the clicked cell and all its neighbors
	mark(safeX, safeY)
	for dx = -1, 1 do
		for dy = -1, 1 do
			mark(safeX + dx, safeY + dy)
		end
	end

	local validIndices: { number } = {}
	for idx = 1, #board.Cells do
		if not avoid[idx] then
			validIndices[#validIndices + 1] = idx
		end
	end

	if mineCount > #validIndices then
		error("mineCount exceeds available valid positions", 2)
	end

	-- Fisher-Yates shuffle, pick first mineCount
	for i = #validIndices, 2, -1 do
		local j = math.random(1, i)
		validIndices[i], validIndices[j] = validIndices[j], validIndices[i]
	end

	for i = 1, mineCount do
		board.Cells[validIndices[i]].HasMine = true
	end

	return mineCount
end

return MineGenerator
