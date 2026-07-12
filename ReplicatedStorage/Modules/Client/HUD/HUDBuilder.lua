--!strict
-- HUDBuilder — constructs UI Instances. No logic, no gameplay.

local HUDTheme = require(script.Parent.HUDTheme)

local HUDBuilder = {}

export type HUDElements = {
	Gui: ScreenGui,
	Background: Frame,
	MinesLabel: TextLabel,
	FlagsLabel: TextLabel,
	TimerLabel: TextLabel,
}

function HUDBuilder.Build(): HUDElements
	local t = HUDTheme

	local gui = Instance.new("ScreenGui")
	gui.Name = "HUD"
	gui.ResetOnSpawn = false
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.DisplayOrder = 20

	local bg = Instance.new("Frame")
	bg.Name = "Background"
	bg.Size = UDim2.fromOffset(260, 78)
	bg.Position = UDim2.new(0, 10, 1, -88)
	bg.BackgroundColor3 = t.BgColor
	bg.BackgroundTransparency = t.BgTransparency
	bg.BorderSizePixel = 0
	bg.Parent = gui

	local function makeLabel(name: string, y: number): TextLabel
		local lbl = Instance.new("TextLabel")
		lbl.Name = name
		lbl.Size = UDim2.fromOffset(200, 20)
		lbl.Position = UDim2.fromOffset(8, y)
		lbl.BackgroundTransparency = 1
		lbl.TextColor3 = t.TextColor
		lbl.TextTransparency = t.TextTransparency
		lbl.TextSize = t.TextSize
		lbl.Font = t.Font
		lbl.TextXAlignment = Enum.TextXAlignment.Left
		lbl.TextYAlignment = Enum.TextYAlignment.Center
		lbl.Parent = bg
		return lbl
	end

	local minesLbl = makeLabel("MinesLabel", 4)
	local flagsLbl = makeLabel("FlagsLabel", 28)
	local timerLbl = makeLabel("TimerLabel", 52)

	return {
		Gui = gui,
		Background = bg,
		MinesLabel = minesLbl,
		FlagsLabel = flagsLbl,
		TimerLabel = timerLbl,
	}
end

return HUDBuilder
