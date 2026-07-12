--!strict
-- PlayerManager — stores players belonging to a match.
-- Players are kept in insertion order.

local PlayerManager = {}

export type PlayerEntry = {
	Player: Player,
	JoinedAt: number,
}

local players: { PlayerEntry } = {}

function PlayerManager.AddPlayer(player: Player): ()
	for _, entry in ipairs(players) do
		if entry.Player == player then
			return
		end
	end
	players[#players + 1] = {
		Player = player,
		JoinedAt = os.clock(),
	}
end

function PlayerManager.RemovePlayer(player: Player): ()
	for i, entry in ipairs(players) do
		if entry.Player == player then
			table.remove(players, i)
			return
		end
	end
end

function PlayerManager.HasPlayer(player: Player): boolean
	for _, entry in ipairs(players) do
		if entry.Player == player then
			return true
		end
	end
	return false
end

function PlayerManager.GetPlayers(): { PlayerEntry }
	local copy: { PlayerEntry } = {}
	for _, entry in ipairs(players) do
		copy[#copy + 1] = entry
	end
	return copy
end

function PlayerManager.GetPlayerCount(): number
	return #players
end

function PlayerManager.GetPlayer(index: number): PlayerEntry?
	return players[index]
end

function PlayerManager.GetPlayerEntry(player: Player): PlayerEntry?
	for _, entry in ipairs(players) do
		if entry.Player == player then
			return entry
		end
	end
	return nil
end

function PlayerManager.GetPlayerIndex(player: Player): number?
	for i, entry in ipairs(players) do
		if entry.Player == player then
			return i
		end
	end
	return nil
end

function PlayerManager.Clear(): ()
	players = {}
end

return PlayerManager
