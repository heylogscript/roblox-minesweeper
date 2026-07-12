local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFlowController = require(script.Parent:WaitForChild("RoundFlowController"))
local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local prepareForBoard = remotes:WaitForChild("PrepareForBoard")

local Difficulty = "Easy"

local function startRound()
	prepareForBoard:FireAllClients()
	task.wait()
	RoundFlowController.StartRound(Difficulty)
end

local function scheduleNextRound(delay: number)
	task.wait(delay)
	startRound()
end

Players.PlayerAdded:Connect(function()
	task.wait(5)
	startRound()
end)

RoundEvents.RoundLost:Connect(function()
	scheduleNextRound(11)
end)

RoundEvents.RoundWon:Connect(function()
	scheduleNextRound(16)
end)

if #Players:GetPlayers() > 0 then
	task.wait(5)
	startRound()
end
