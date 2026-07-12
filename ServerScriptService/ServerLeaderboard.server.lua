local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)

local dataStore = DataStoreService:GetDataStore("PlayerData")

local cache: { [string]: number } = {}

local function getKey(userId: number): string
	return "Wins_" .. userId
end

local function loadWins(player: Player): number
	local key = getKey(player.UserId)
	local cached = cache[key]
	if cached ~= nil then return cached end

	local ok, value = pcall(function()
		return dataStore:GetAsync(key)
	end)
	if ok and value ~= nil then
		cache[key] = value
		return value
	end
	cache[key] = 0
	return 0
end

local function saveWins(player: Player, wins: number)
	local key = getKey(player.UserId)
	cache[key] = wins
	pcall(function()
		dataStore:SetAsync(key, wins)
	end)
end

local function setupLeaderstats(player: Player)
	local wins = loadWins(player)

	local stats = Instance.new("Folder")
	stats.Name = "leaderstats"
	stats.Parent = player

	local winsValue = Instance.new("IntValue")
	winsValue.Name = "Wins"
	winsValue.Value = wins
	winsValue.Parent = stats
end

local function incrementWins(player: Player)
	local wins = loadWins(player) + 1
	saveWins(player, wins)

	local stats = player:FindFirstChild("leaderstats")
	if stats then
		local w = stats:FindFirstChild("Wins")
		if w then
			w.Value = wins
		end
	end
end

local function onPlayerRemoving(player: Player)
	local key = getKey(player.UserId)
	local cached = cache[key]
	if cached ~= nil then
		saveWins(player, cached)
	end
end

Players.PlayerAdded:Connect(setupLeaderstats)
Players.PlayerRemoving:Connect(onPlayerRemoving)

RoundEvents.RoundWon:Connect(function(player: Player)
	if player then
		incrementWins(player)
	end
end)

for _, player in ipairs(Players:GetPlayers()) do
	setupLeaderstats(player)
end
