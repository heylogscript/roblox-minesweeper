--!strict
-- DebugOverlay — developer debug panel. Displays live engine state.
-- Pure observer. Never modifies gameplay, rendering, or networking.
-- Disabled by default. Toggle with F1. No RenderStepped when hidden.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local ClientBoardManager = require(ReplicatedStorage.Modules.Client.ClientBoardManager)
local DefaultTheme = require(ReplicatedStorage.Modules.Rendering.Themes.DefaultTheme)
local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)
local UIEvents = require(ReplicatedStorage.Modules.Shared.Events.UIEvents)
local RenderEvents = require(ReplicatedStorage.Modules.Shared.Events.RenderEvents)

local DebugOverlay = {}

local MAX_LOG: number = 20
local COL_BG = Color3.fromRGB(20, 20, 30)
local COL_TEXT = Color3.fromRGB(0, 220, 100)
local COL_DIM = Color3.fromRGB(100, 180, 130)

local visible: boolean = false
local showPerf: boolean = true
local gui: ScreenGui? = nil
local container: ScrollingFrame? = nil
local labels: { [string]: TextLabel } = {}
local eventLines: { string } = {}
local logLabel: TextLabel? = nil
local connections: { any } = {}
local renderConnection: RBXScriptConnection? = nil

local matchState: string = "Idle"
local boardWidth: number = 0
local boardHeight: number = 0
local mineCount: number = 0
local roundTime: number = 0
local roundStart: number = 0
local roundRunning: boolean = false
local fps: number = 0
local frameTimeMs: number = 0
local mouseX: number = 0
local mouseY: number = 0
local animEnabled: boolean = true

local statsWinRate: number = 0
local statsDuration: number = 0
local statsFloodFill: number = 0
local statsAccuracy: number = 0

local function timestamp(): string
	return os.date("%H:%M:%S")
end

local function createLabel(parent: Instance, text: string): TextLabel
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 0, 18)
	label.BackgroundTransparency = 1
	label.Text = text
	label.TextColor3 = COL_TEXT
	label.Font = Enum.Font.Code
	label.TextSize = 13
	label.TextXAlignment = Enum.TextXAlignment.Left
	label.Parent = parent
	return label
end

local function updateCanvas(): ()
	if not container then
		return
	end
	local layout = container:FindFirstChildOfClass("UIListLayout")
	if layout then
		container.CanvasSize = UDim2.fromOffset(0, layout.AbsoluteContentSize.Y + 20)
	end
end

local function refreshLabels(): ()
	if not container then
		return
	end

	local board = ClientBoardManager.GetBoard()
	local totalCells = boardWidth * boardHeight
	if totalCells == 0 and board then
		totalCells = board.Width * board.Height
	end

	local flagsOnBoard = 0
	local revealedOnBoard = 0
	if board then
		for _, cell in ipairs(board.Cells) do
			if cell.HasFlag then
				flagsOnBoard += 1
			end
			if cell.IsRevealed then
				revealedOnBoard += 1
			end
		end
	end

	if roundRunning then
		roundTime = os.clock() - roundStart
	end

	labels.State.Text = string.format("State: %s", matchState)
	labels.Board.Text = string.format("Board: %dx%d | Mines: %d", boardWidth, boardHeight, mineCount)
	labels.Flags.Text = string.format("Flags: %d / %d", flagsOnBoard, mineCount)
	labels.Revealed.Text = string.format("Revealed: %d / %d", revealedOnBoard, totalCells)
	labels.Timer.Text = string.format("Timer: %.1fs", roundTime)
	labels.Anim.Text = string.format("Anim: %s", if animEnabled then "On" else "Off")
	labels.Theme.Text = "Theme: Default"
	labels.MouseInfo.Text = string.format("Mouse Cell: (%d, %d)", mouseX, mouseY)

	labels.WinRate.Text = string.format("Win Rate: %.1f%%", statsWinRate * 100)
	labels.Duration.Text = string.format("Duration: %.1fs", statsDuration)
	labels.FloodFill.Text = string.format("Flood Fill: %d", statsFloodFill)
	labels.Accuracy.Text = string.format("Accuracy: %.2f", statsAccuracy)

	labels.FPS.Visible = showPerf
	labels.FPS.Text = string.format("FPS: %.0f", fps)
	labels.FrameTime.Visible = showPerf
	labels.FrameTime.Text = string.format("Frame: %.2fms", frameTimeMs)

	if logLabel then
		local lines = {}
		local start = math.max(1, #eventLines - MAX_LOG + 1)
		for i = start, #eventLines do
			lines[#lines + 1] = eventLines[i]
		end
		logLabel.Text = table.concat(lines, "\n")
	end
end

local function onRenderStepped(dt: number): ()
	frameTimeMs = dt * 1000
	fps = 1 / math.max(dt, 0.0001)

	local player = Players.LocalPlayer
	if player then
		local m = player:GetMouse()
		if m and m.Target and m.Target:IsA("BasePart") then
			local _, _, xs, ys = m.Target.Name:find("Cell_(%d+)_(%d+)")
			if xs and ys then
				mouseX = tonumber(xs) :: number
				mouseY = tonumber(ys) :: number
			end
		end
	end

	refreshLabels()
end

local function logEvent(name: string, detail: string): ()
	local line = string.format("[%s] %s %s", timestamp(), name, detail)
	table.insert(eventLines, line)
	if #eventLines > MAX_LOG * 2 then
		for _ = 1, #eventLines - MAX_LOG do
			table.remove(eventLines, 1)
		end
	end
	if visible then
		refreshLabels()
	end
end

local function onToggle(): ()
	visible = not visible
	if gui then
		gui.Enabled = visible
	end
	if visible then
		renderConnection = RunService.RenderStepped:Connect(onRenderStepped)
		refreshLabels()
		updateCanvas()
	else
		if renderConnection then
			renderConnection:Disconnect()
			renderConnection = nil
		end
	end
end

function DebugOverlay.Create(): ()
	if gui then
		return
	end

	local player = Players.LocalPlayer
	if not player then
		return
	end
	local playerGui = player:WaitForChild("PlayerGui")

	gui = Instance.new("ScreenGui")
	gui.Name = "DebugOverlay"
	gui.DisplayOrder = 9999
	gui.ResetOnSpawn = false
	gui.Enabled = false
	gui.Parent = playerGui

	local bg = Instance.new("Frame")
	bg.Size = UDim2.fromOffset(420, 560)
	bg.Position = UDim2.fromOffset(12, 12)
	bg.BackgroundColor3 = COL_BG
	bg.BackgroundTransparency = 0.08
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local title = Instance.new("TextLabel")
	title.Size = UDim2.new(1, -20, 0, 26)
	title.Position = UDim2.fromOffset(10, 6)
	title.BackgroundTransparency = 1
	title.Text = "DEBUG OVERLAY"
	title.TextColor3 = COL_TEXT
	title.Font = Enum.Font.Code
	title.TextSize = 16
	title.TextXAlignment = Enum.TextXAlignment.Left
	title.Parent = bg

	local separator = Instance.new("Frame")
	separator.Size = UDim2.new(1, -20, 0, 1)
	separator.Position = UDim2.fromOffset(10, 34)
	separator.BackgroundColor3 = COL_DIM
	separator.BackgroundTransparency = 0.5
	separator.BorderSizePixel = 0
	separator.Parent = bg

	container = Instance.new("ScrollingFrame")
	container.Size = UDim2.new(1, -20, 1, -50)
	container.Position = UDim2.fromOffset(10, 40)
	container.BackgroundTransparency = 1
	container.BorderSizePixel = 0
	container.ScrollBarThickness = 6
	container.ScrollBarImageColor3 = COL_DIM
	container.Parent = bg

	local layout = Instance.new("UIListLayout")
	layout.Padding = UDim.new(0, 2)
	layout.Parent = container

	labels.State = createLabel(container, "State: --")
	labels.Board = createLabel(container, "Board: --")
	labels.Flags = createLabel(container, "Flags: --")
	labels.Revealed = createLabel(container, "Revealed: --")
	labels.Timer = createLabel(container, "Timer: --")
	labels.Anim = createLabel(container, "Anim: --")
	labels.Theme = createLabel(container, "Theme: Default")
	labels.MouseInfo = createLabel(container, "Mouse Cell: --")

	local sepStats = Instance.new("Frame")
	sepStats.Size = UDim2.new(1, 0, 0, 1)
	sepStats.BackgroundColor3 = COL_DIM
	sepStats.BackgroundTransparency = 0.5
	sepStats.BorderSizePixel = 0
	sepStats.Parent = container

	createLabel(container, "Statistics:")

	labels.WinRate = createLabel(container, "Win Rate: --")
	labels.Duration = createLabel(container, "Duration: --")
	labels.FloodFill = createLabel(container, "Flood Fill: --")
	labels.Accuracy = createLabel(container, "Accuracy: --")

	local sep2 = Instance.new("Frame")
	sep2.Size = UDim2.new(1, 0, 0, 1)
	sep2.BackgroundColor3 = COL_DIM
	sep2.BackgroundTransparency = 0.5
	sep2.BorderSizePixel = 0
	sep2.Parent = container

	labels.FPS = createLabel(container, "FPS: --")
	labels.FrameTime = createLabel(container, "Frame: --")
	labels.FPS.Visible = showPerf
	labels.FrameTime.Visible = showPerf

	local sep3 = Instance.new("Frame")
	sep3.Size = UDim2.new(1, 0, 0, 1)
	sep3.BackgroundColor3 = COL_DIM
	sep3.BackgroundTransparency = 0.5
	sep3.BorderSizePixel = 0
	sep3.Parent = container

	createLabel(container, "Event Log:")

	logLabel = Instance.new("TextLabel")
	logLabel.Size = UDim2.new(1, 0, 0, 20 * MAX_LOG)
	logLabel.BackgroundTransparency = 1
	logLabel.Text = ""
	logLabel.TextColor3 = COL_DIM
	logLabel.Font = Enum.Font.Code
	logLabel.TextSize = 11
	logLabel.TextXAlignment = Enum.TextXAlignment.Left
	logLabel.TextYAlignment = Enum.TextYAlignment.Top
	logLabel.Parent = container

	updateCanvas()

	local function onRoundStarted(width: number, height: number, mines: number): ()
		matchState = "Playing"
		boardWidth = width
		boardHeight = height
		mineCount = mines
		roundStart = os.clock()
		roundRunning = true
		roundTime = 0
		mouseX = 0
		mouseY = 0
		logEvent("RoundStarted", string.format("(%dx%d, %d mines)", width, height, mines))
	end

	local function onCellRevealed(x: number, y: number): ()
		logEvent("CellRevealed", string.format("(%d,%d)", x, y))
	end

	local function onFlagPlaced(x: number, y: number): ()
		logEvent("FlagPlaced", string.format("(%d,%d)", x, y))
	end

	local function onFlagRemoved(x: number, y: number): ()
		logEvent("FlagRemoved", string.format("(%d,%d)", x, y))
	end

	local function onRoundWon(): ()
		matchState = "Victory"
		roundRunning = false
		logEvent("RoundWon", "")
	end

	local function onRoundLost(): ()
		matchState = "Defeat"
		roundRunning = false
		logEvent("RoundLost", "")
	end

	local function onBoardCreated(board: any): ()
		boardWidth = board.Width
		boardHeight = board.Height
		mineCount = mineCount
		roundStart = os.clock()
		roundRunning = true
		logEvent("BoardCreated", string.format("(%dx%d)", board.Width, board.Height))
	end

	local function onBoardDestroyed(): ()
		matchState = "Idle"
		boardWidth = 0
		boardHeight = 0
		mineCount = 0
		roundRunning = false
		roundTime = 0
		eventLines = {}
		logEvent("BoardDestroyed", "")
	end

	local function onShowVictory(): ()
		logEvent("ShowVictory", "")
	end

	local function onShowDefeat(): ()
		logEvent("ShowDefeat", "")
	end

	local function onFaceChanged(state: string): ()
		logEvent("FaceChanged", state)
	end

	local function onThemeChanged(): ()
		logEvent("ThemeChanged", "")
	end

	local function onAnimChanged(enabled: boolean): ()
		animEnabled = enabled
		logEvent("AnimChanged", tostring(enabled))
	end

	local function onStatsUpdated(data: any): ()
		local m = data.match
		local lt = data.lifetime
		statsWinRate = lt.winRate
		statsDuration = data.liveDuration
		statsFloodFill = m.largestFloodFill
		statsAccuracy = data.liveAccuracy
		if visible then
			refreshLabels()
		end
	end

	table.insert(connections, RoundEvents.RoundStarted:Connect(onRoundStarted))
	table.insert(connections, RoundEvents.CellRevealed:Connect(onCellRevealed))
	table.insert(connections, RoundEvents.FlagPlaced:Connect(onFlagPlaced))
	table.insert(connections, RoundEvents.FlagRemoved:Connect(onFlagRemoved))
	table.insert(connections, RoundEvents.RoundWon:Connect(onRoundWon))
	table.insert(connections, RoundEvents.RoundLost:Connect(onRoundLost))
	table.insert(connections, RoundEvents.BoardCreated:Connect(onBoardCreated))
	table.insert(connections, RoundEvents.BoardDestroyed:Connect(onBoardDestroyed))
	table.insert(connections, UIEvents.ShowVictory:Connect(onShowVictory))
	table.insert(connections, UIEvents.ShowDefeat:Connect(onShowDefeat))
	table.insert(connections, UIEvents.FaceChanged:Connect(onFaceChanged))
	table.insert(connections, RenderEvents.ThemeChanged:Connect(onThemeChanged))
	table.insert(connections, RenderEvents.AnimationsEnabledChanged:Connect(onAnimChanged))
	table.insert(connections, RenderEvents.StatsUpdated:Connect(onStatsUpdated))

	table.insert(connections, UserInputService.InputBegan:Connect(function(input: InputObject, gameProcessed: boolean)
		if gameProcessed then
			return
		end
		if input.KeyCode == Enum.KeyCode.F1 then
			onToggle()
		elseif input.KeyCode == Enum.KeyCode.F2 then
			eventLines = {}
			if visible then
				refreshLabels()
			end
		elseif input.KeyCode == Enum.KeyCode.F3 then
			showPerf = not showPerf
			if visible then
				refreshLabels()
			end
		end
	end))

end

function DebugOverlay.Destroy(): ()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
	if renderConnection then
		renderConnection:Disconnect()
		renderConnection = nil
	end
	if gui then
		gui:Destroy()
		gui = nil
	end
	container = nil
	labels = {}
	eventLines = {}
	logLabel = nil
end

DebugOverlay.Create()

return DebugOverlay
