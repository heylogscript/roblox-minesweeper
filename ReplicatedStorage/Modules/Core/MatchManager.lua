--!strict
-- MatchManager — manages match data and state transitions.
-- Pure data layer. No orchestration, no timer management.

local HttpService = game:GetService("HttpService")
local PlayerManager = require(script.Parent.PlayerManager)

local MatchManager = {}

export type MatchState = "Waiting" | "Countdown" | "Playing" | "Finished"

export type Match = {
	Id: string,
	State: MatchState,
	Difficulty: string,
	CreatedAt: number,
}

local CurrentMatch: Match? = nil

-- Internal Signal implementation
type Signal = { _opaque: boolean }

local function createSignal(): Signal
	local connections: { (...any) -> () } = {}
	local signal = { _opaque = true }
	function signal.Connect(_: any, callback: (...any) -> ()): () -> ()
		table.insert(connections, callback)
		return function()
			for i, conn in ipairs(connections) do
				if conn == callback then
					table.remove(connections, i)
					break
				end
			end
		end
	end
	function signal.Fire(_: any, ...: any): ()
		for _, callback in ipairs(connections) do
			callback(...)
		end
	end
	return signal :: Signal
end

local MatchCreatedSignal: Signal = createSignal()
local MatchDestroyedSignal: Signal = createSignal()
local StateChangedSignal: Signal = createSignal()

local VALID_STATES: { [string]: boolean } = {
	Waiting = true,
	Countdown = true,
	Playing = true,
	Finished = true,
}

local AllowedTransitions: { [string]: { [string]: boolean } } = {
	Waiting = { Countdown = true },
	Countdown = { Playing = true },
	Playing = { Finished = true },
	Finished = { Waiting = true },
}

function MatchManager.GetCurrentMatch(): Match?
	return CurrentMatch
end

function MatchManager.GetMatchCreatedSignal(): any
	return MatchCreatedSignal
end

function MatchManager.GetMatchDestroyedSignal(): any
	return MatchDestroyedSignal
end

function MatchManager.GetStateChangedSignal(): any
	return StateChangedSignal
end

function MatchManager.HasMatch(): boolean
	return CurrentMatch ~= nil
end

function MatchManager.AddPlayer(player: Player): ()
	PlayerManager.AddPlayer(player)
end

function MatchManager.RemovePlayer(player: Player): ()
	PlayerManager.RemovePlayer(player)
end

function MatchManager.GetPlayers(): { PlayerManager.PlayerEntry }
	return PlayerManager.GetPlayers()
end

function MatchManager.GetPlayerCount(): number
	return PlayerManager.GetPlayerCount()
end

function MatchManager.CreateMatch(difficulty: string): Match
	PlayerManager.Clear()
	if CurrentMatch ~= nil then
		error("A match is already active", 2)
	end
	if difficulty == "" then
		error("Difficulty cannot be empty", 2)
	end

	local match: Match = {
		Id = HttpService:GenerateGUID(false),
		State = "Waiting",
		Difficulty = difficulty,
		CreatedAt = os.clock(),
	}

	CurrentMatch = match
	MatchCreatedSignal:Fire(match)
	return match
end

function MatchManager.DestroyMatch(): ()
	if CurrentMatch ~= nil then
		local match = CurrentMatch
		CurrentMatch = nil
		PlayerManager.Clear()
		MatchDestroyedSignal:Fire(match)
	end
end

function MatchManager.IsWaiting(): boolean
	return CurrentMatch ~= nil and CurrentMatch.State == "Waiting"
end

function MatchManager.IsCountdown(): boolean
	return CurrentMatch ~= nil and CurrentMatch.State == "Countdown"
end

function MatchManager.IsPlaying(): boolean
	return CurrentMatch ~= nil and CurrentMatch.State == "Playing"
end

function MatchManager.IsFinished(): boolean
	return CurrentMatch ~= nil and CurrentMatch.State == "Finished"
end

function MatchManager.GetState(): MatchState?
	if CurrentMatch == nil then
		return nil
	end
	return CurrentMatch.State
end

function MatchManager.SetState(newState: MatchState): ()
	if CurrentMatch == nil then
		error("No active match to set state on", 2)
	end
	if not VALID_STATES[newState] then
		error(string.format("Invalid state '%s'", tostring(newState)), 2)
	end
	local oldState = CurrentMatch.State
	if not AllowedTransitions[oldState] or not AllowedTransitions[oldState][newState] then
		error(string.format("Invalid transition from '%s' to '%s'", oldState, newState), 2)
	end
	CurrentMatch.State = newState
	StateChangedSignal:Fire(CurrentMatch, oldState, newState)
end

return MatchManager
