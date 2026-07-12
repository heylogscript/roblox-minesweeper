-- RemoteSetup — creates RemoteEvents for Minesweeper if they don't exist.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not remotes then
	remotes = Instance.new("Folder")
	remotes.Name = "Remotes"
	remotes.Parent = ReplicatedStorage
end

local eventNames = { "RevealCell", "ToggleFlag", "RequestBoard", "BoardUpdate", "StartGame", "GameEnded", "LeaveGame", "PrepareForBoard" }
for _, name in ipairs(eventNames) do
	if remotes:FindFirstChild(name) then
		continue
	end
	local event = Instance.new("RemoteEvent")
	event.Name = name
	event.Parent = remotes
end
