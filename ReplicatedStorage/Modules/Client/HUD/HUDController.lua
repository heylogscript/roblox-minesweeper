--!strict
-- HUDController — owns HUD lifecycle. Consumes data, never modifies game state.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local HUDBuilder = require(script.Parent.HUDBuilder)
local UIEvents = require(script.Parent.Parent.Parent.Shared.Events.UIEvents)

local HUDController = {}

local elements: HUDBuilder.HUDElements? = nil
local connections: { any } = {}
local timerRunning = false
local timerStart = 0

-- ── public API ───────────────────────────────────────────

function HUDController.SetRemainingMines(count: number): ()
	if not elements then return end
	elements.MinesLabel.Text = string.format("Mines: %d", count)
end

function HUDController.SetFlags(count: number): ()
	if not elements then return end
	elements.FlagsLabel.Text = string.format("Flags: %d", count)
end

function HUDController.SetTimer(seconds: number): ()
	if not elements then return end
	local whole = math.floor(seconds)
	local frac = math.floor((seconds - whole) * 100)
	elements.TimerLabel.Text = string.format("Timer: %d.%02ds", whole, frac)
end

function HUDController.SetFace(_state: string): () end

function HUDController.ShowVictory(): ()
	if not elements then return end
	elements.MinesLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
	elements.FlagsLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
	elements.TimerLabel.TextColor3 = Color3.fromRGB(100, 255, 120)
end

function HUDController.ShowDefeat(): ()
	if not elements then return end
	elements.MinesLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	elements.FlagsLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
	elements.TimerLabel.TextColor3 = Color3.fromRGB(255, 80, 80)
end

-- ── timer tick ───────────────────────────────────────────

local function onHeartbeat()
	if not timerRunning or not elements then return end
	local elapsed = os.clock() - timerStart
	HUDController.SetTimer(elapsed)
end

local heartbeatConn = nil

local function startTimer()
	timerStart = os.clock()
	timerRunning = true
	if not heartbeatConn then
		heartbeatConn = RunService.Heartbeat:Connect(onHeartbeat)
	end
end

local function stopTimer()
	timerRunning = false
end

-- ── lifecycle ────────────────────────────────────────────

function HUDController.Create(): ()
	if elements then
		HUDController.Destroy()
	end

	elements = HUDBuilder.Build()

	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:WaitForChild("PlayerGui")
	elements.Gui.Parent = playerGui

	HUDController.SetRemainingMines(0)
	HUDController.SetFlags(0)
	HUDController.SetTimer(0)

	table.insert(connections, UIEvents.ShowVictory:Connect(function()
		HUDController.ShowVictory()
		stopTimer()
	end))
	table.insert(connections, UIEvents.ShowDefeat:Connect(function()
		HUDController.ShowDefeat()
		stopTimer()
	end))
	table.insert(connections, UIEvents.UpdateMineCounter:Connect(function(count: number)
		HUDController.SetRemainingMines(count)
	end))
	table.insert(connections, UIEvents.UpdateFlagCounter:Connect(function(count: number)
		HUDController.SetFlags(count)
	end))
	table.insert(connections, UIEvents.UpdateTimer:Connect(function(seconds: number)
		HUDController.SetTimer(seconds)
	end))
	table.insert(connections, UIEvents.GameStarted:Connect(function()
		startTimer()
	end))

	startTimer()
end

function HUDController.Destroy(): ()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
	timerRunning = false
	if heartbeatConn then
		heartbeatConn:Disconnect()
		heartbeatConn = nil
	end
	if elements then
		elements.Gui:Destroy()
		elements = nil
	end
end

function HUDController.Reset(): ()
	if not elements then return end
	HUDController.SetRemainingMines(0)
	HUDController.SetFlags(0)
	HUDController.SetTimer(0)
	startTimer()
end

return HUDController
