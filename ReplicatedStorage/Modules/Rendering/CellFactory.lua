--!strict
-- CellFactory — owns Instance creation and destruction. Knows nothing about gameplay.

local Workspace = game:GetService("Workspace")
local DefaultTheme = require(script.Parent.Themes.DefaultTheme)

local CellFactory = {}

export type CellVisual = {
	base: Part,
	gui: SurfaceGui,
	label: TextLabel,
	flagModel: Model?,
	_wasRevealed: boolean?,
	_hadFlag: boolean?,
}

local flagsFolder: Folder? = nil

local function ensureFlagsFolder(): Folder
	if flagsFolder == nil then
		flagsFolder = Instance.new("Folder")
		flagsFolder.Name = "MinesweeperFlags"
		flagsFolder.Parent = Workspace
	end
	return flagsFolder
end

function CellFactory.CreateCellVisual(x: number, y: number): CellVisual
	local posX = (x - 1) * DefaultTheme.Spacing
	local posZ = (y - 1) * DefaultTheme.Spacing

	local part = Instance.new("Part")
	part.Name = string.format("Cell_%d_%d", x, y)
	part.Anchored = true
	part.CanCollide = true
	part.Position = Vector3.new(posX, 0, posZ)

	local gui = Instance.new("SurfaceGui")
	gui.Face = Enum.NormalId.Top
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = DefaultTheme.PixelsPerStud
	gui.AlwaysOnTop = false
	gui.Enabled = false
	gui.Parent = part

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 1)
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextSize = 20
	label.Font = DefaultTheme.Font
	label.Text = ""
	label.TextColor3 = Color3.new(1, 1, 1)
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = gui

	return {
		base = part,
		gui = gui,
		label = label,
		flagModel = nil,
	}
end

function CellFactory.CreateBackground(boardWidth: number, boardHeight: number): Part
	local totalWidth = (boardWidth - 1) * DefaultTheme.Spacing + DefaultTheme.CellSize
	local totalDepth = (boardHeight - 1) * DefaultTheme.Spacing + DefaultTheme.CellSize

	local bg = Instance.new("Part")
	bg.Name = "Background"
	bg.Anchored = true
	bg.CanCollide = false
	bg.Size = Vector3.new(totalWidth + 2, DefaultTheme.BoardBgHeight, totalDepth + 2)
	bg.Position = Vector3.new(
		totalWidth / 2 - DefaultTheme.Spacing / 2,
		-DefaultTheme.BoardBgHeight / 2,
		totalDepth / 2 - DefaultTheme.Spacing / 2
	)
	bg.Color = DefaultTheme.BoardBgColor
	bg.Material = DefaultTheme.BoardBgMaterial
	return bg
end

function CellFactory.CreateFlagModel(cellX: number, cellY: number): Model
	local posX = (cellX - 1) * DefaultTheme.Spacing
	local posZ = (cellY - 1) * DefaultTheme.Spacing
	local baseY = DefaultTheme.BaseY

	local template = DefaultTheme.FlagTemplate
	local model = template:Clone()
	model.Name = string.format("Flag_%d_%d", cellX, cellY)
	model.Parent = ensureFlagsFolder()

	local minY = math.huge
	local sumX, sumZ, count = 0, 0, 0
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			minY = math.min(minY, child.Position.Y)
			sumX += child.Position.X
			sumZ += child.Position.Z
			count += 1
		end
	end

	local centerX = count > 0 and sumX / count or 0
	local centerZ = count > 0 and sumZ / count or 0
	local offset = Vector3.new(posX - centerX, baseY - minY, posZ - centerZ)
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			child.Anchored = true
			child.CanCollide = false
			child.Position += offset
		end
	end

	return model
end

function CellFactory.DestroyCellVisual(visual: CellVisual): ()
	if visual.flagModel then
		visual.flagModel:Destroy()
		visual.flagModel = nil
	end
	visual.label:Destroy()
	visual.gui:Destroy()
	visual.base:Destroy()
end

function CellFactory.DestroyAll(): ()
	local folder = flagsFolder
	if folder then
		for _, v in ipairs(folder:GetChildren()) do
			v:Destroy()
		end
		folder:Destroy()
		flagsFolder = nil
	end
end

return CellFactory
