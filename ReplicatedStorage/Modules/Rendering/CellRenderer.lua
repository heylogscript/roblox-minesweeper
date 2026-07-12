--!strict
-- CellRenderer — sole module allowed to write visual properties.
-- Detects visual transitions and routes animations to AnimationController.

local DefaultTheme = require(script.Parent.Themes.DefaultTheme)
local CellFactory = require(script.Parent.CellFactory)
local AnimationController = require(script.Parent.AnimationController)

local CellRenderer = {}

function CellRenderer.Update(visual: CellFactory.CellVisual, cell: any): ()
	local theme = DefaultTheme

	if cell.IsRevealed then
		visual.base.Size = Vector3.new(theme.CellSize, theme.CellRevealedHeight, theme.CellSize)
		visual.base.Color = theme.RevealedColor
		visual.base.Material = theme.RevealedMaterial

		if cell.AdjacentMines > 0 then
			visual.label.Text = tostring(cell.AdjacentMines)
			visual.label.TextColor3 = theme.NumberColors[cell.AdjacentMines] or Color3.new(1, 1, 1)
			visual.gui.Enabled = true
		else
			visual.gui.Enabled = false
		end
	else
		visual.base.Size = Vector3.new(theme.CellSize, theme.CellUnrevealedHeight, theme.CellSize)
		visual.base.Color = theme.UnrevealedColor
		visual.base.Material = theme.UnrevealedMaterial
		visual.gui.Enabled = false
	end

	local hadFlag = visual._hadFlag
	local wasRevealed = visual._wasRevealed

	if hadFlag == nil then
		if cell.HasFlag then
			visual.flagModel = CellFactory.CreateFlagModel(cell.X, cell.Y)
		end
		visual._hadFlag = cell.HasFlag
	elseif cell.HasFlag and not hadFlag then
		visual.flagModel = CellFactory.CreateFlagModel(cell.X, cell.Y)
		AnimationController.Flag(visual)
		visual._hadFlag = true
	elseif not cell.HasFlag and hadFlag then
		if visual.flagModel then
			local oldModel = visual.flagModel
			visual.flagModel = nil
			AnimationController.RemoveFlag(visual, oldModel)
		end
		visual._hadFlag = false
	end

	if wasRevealed == nil then
		visual._wasRevealed = cell.IsRevealed
	elseif cell.IsRevealed and not wasRevealed then
		AnimationController.Reveal(visual)
		visual._wasRevealed = true
	end
end

function CellRenderer.SetMineRevealed(visual: CellFactory.CellVisual): ()
	local theme = DefaultTheme

	if visual.flagModel then
		visual.flagModel:Destroy()
		visual.flagModel = nil
	end

	visual.base.Color = theme.MineRevealColor
	visual.base.Size = Vector3.new(theme.CellSize, theme.CellRevealedHeight, theme.CellSize)
	visual.gui.Enabled = true
	visual.label.Text = theme.MineText
	visual.label.TextColor3 = theme.MineTextColor

	AnimationController.Mine(visual)
end

return CellRenderer
