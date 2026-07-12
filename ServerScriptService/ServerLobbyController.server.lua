-- ServerLobbyController — bridges StartGame remote to RoundFlowController.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundFlowController = require(script.Parent:WaitForChild("RoundFlowController"))

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local startGame = remotes:WaitForChild("StartGame")

startGame.OnServerEvent:Connect(function(_player: Player, difficultyName: string)
	RoundFlowController.StartRound(difficultyName)
end)
