-- ServerLeaveGame — bridges LeaveGame remote to RoundFlowController cleanup.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFlowController = require(script.Parent:WaitForChild("RoundFlowController"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local leaveGame = remotes:WaitForChild("LeaveGame")

leaveGame.OnServerEvent:Connect(function()
	RoundFlowController.Cleanup()
end)
