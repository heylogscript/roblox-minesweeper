-- ServerRoundController — bridges player RemoteEvents to RoundFlowController.
-- No win detection, no game ending, no cleanup, no UI decisions.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFlowController = require(script.Parent:WaitForChild("RoundFlowController"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local revealCell = remotes:WaitForChild("RevealCell")
local toggleFlag = remotes:WaitForChild("ToggleFlag")
local requestBoard = remotes:WaitForChild("RequestBoard")

revealCell.OnServerEvent:Connect(function(player: Player, x: number, y: number)
	RoundFlowController.RevealCell(player, x, y)
end)

toggleFlag.OnServerEvent:Connect(function(player: Player, x: number, y: number)
	RoundFlowController.ToggleFlag(player, x, y)
end)

requestBoard.OnServerEvent:Connect(function(player: Player)
	RoundFlowController.RequestBoard(player)
end)
