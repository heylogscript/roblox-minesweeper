--!strict
-- BoardRenderer — orchestration layer. Delegates Instance creation to CellFactory
-- and visual updates to CellRenderer. Never writes visual properties directly.
-- Subscribes to RoundEvents so it never needs to know where the board came from.

local Workspace = game:GetService("Workspace")
local ClientBoardManager = require(script.Parent.Parent.Client.ClientBoardManager)
local CellFactory = require(script.Parent.CellFactory)
local CellRenderer = require(script.Parent.CellRenderer)
local AnimationController = require(script.Parent.AnimationController)
local DefaultTheme = require(script.Parent.Themes.DefaultTheme)
local RoundEvents = require(script.Parent.Parent.Shared.Events.RoundEvents)

local BoardRenderer = {}

local FOLDER_NAME = "MinesweeperBoard"

local folder: Folder? = nil
local cellVisuals: { [string]: CellFactory.CellVisual } = {}
local initialized: boolean = false
local connections: { any } = {}

local function cellKey(x: number, y: number): string
	return x .. "_" .. y
end

function BoardRenderer.Create(): ()
	if initialized then
		return
	end
	initialized = true

	table.insert(connections, RoundEvents.BoardCreated:Connect(function(board: any)
		BoardRenderer.Clear()

		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = Workspace

		local bg = CellFactory.CreateBackground(board.Width, board.Height)
		bg.Parent = folder

		for _, cell in ipairs(board.Cells) do
			local key = cellKey(cell.X, cell.Y)
			local visual = CellFactory.CreateCellVisual(cell.X, cell.Y)
			visual.base.Parent = folder
			cellVisuals[key] = visual
		end
	end))

	table.insert(connections, RoundEvents.BoardUpdated:Connect(function(board: any)
		local updated: { [string]: boolean } = {}
		for _, cell in ipairs(board.Cells) do
			local key = cellKey(cell.X, cell.Y)
			updated[key] = true

			local visual = cellVisuals[key]
			if visual then
				CellRenderer.Update(visual, cell)
			end
		end

		for key, visual in pairs(cellVisuals) do
			if not updated[key] then
				CellFactory.DestroyCellVisual(visual)
				cellVisuals[key] = nil
			end
		end
	end))

	table.insert(connections, RoundEvents.BoardDestroyed:Connect(function()
		BoardRenderer.Clear()
	end))
end

function BoardRenderer.Render(): ()
	local board = ClientBoardManager.GetBoard()
	if board == nil then
		return
	end

	if folder == nil then
		folder = Instance.new("Folder")
		folder.Name = FOLDER_NAME
		folder.Parent = Workspace

		local bg = CellFactory.CreateBackground(board.Width, board.Height)
		bg.Parent = folder
	end

	local updated: { [string]: boolean } = {}
	for _, cell in ipairs(board.Cells) do
		local key = cellKey(cell.X, cell.Y)
		updated[key] = true

		local visual = cellVisuals[key]
		if visual == nil then
			visual = CellFactory.CreateCellVisual(cell.X, cell.Y)
			visual.base.Parent = folder
			cellVisuals[key] = visual
		end

		CellRenderer.Update(visual, cell)
	end

	for key, visual in pairs(cellVisuals) do
		if not updated[key] then
			CellFactory.DestroyCellVisual(visual)
			cellVisuals[key] = nil
		end
	end
end

function BoardRenderer.RevealAllMines(minePositions: { { x: number, y: number } }): ()
	for _, pos in ipairs(minePositions) do
		local key = cellKey(pos.x, pos.y)
		local visual = cellVisuals[key]
		if visual then
			CellRenderer.SetMineRevealed(visual)
		end
	end
end

function BoardRenderer.PlayWinEffect(minePositions: { { x: number, y: number } }): ()
	-- Pop all flags
	for _, visual in pairs(cellVisuals) do
		if visual.flagModel then
			AnimationController.FlagPop(visual)
		end
	end

	-- Reveal mines green one by one
	for i, pos in ipairs(minePositions) do
		local key = cellKey(pos.x, pos.y)
		local visual = cellVisuals[key]
		if visual then
			AnimationController.GreenReveal(visual, (i - 1) * 0.12)
		end
	end
end

function BoardRenderer.Clear(): ()
	for _, visual in pairs(cellVisuals) do
		CellFactory.DestroyCellVisual(visual)
	end
	cellVisuals = {}

	if folder then
		folder:Destroy()
		folder = nil
	end

	CellFactory.DestroyAll()
end

BoardRenderer.Create()

return BoardRenderer
