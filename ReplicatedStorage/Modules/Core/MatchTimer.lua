--!strict
-- MatchTimer — measures elapsed time using os.clock().
-- Accumulates time across multiple start/stop cycles.

local MatchTimer = {}

local running: boolean = false
local accumulated: number = 0
local startTime: number = 0

function MatchTimer.Start(): ()
	if running then
		return
	end
	running = true
	startTime = os.clock()
end

function MatchTimer.Stop(): ()
	if not running then
		return
	end
	accumulated += os.clock() - startTime
	running = false
end

function MatchTimer.Reset(): ()
	if running then
		running = false
	end
	accumulated = 0
	startTime = 0
end

function MatchTimer.IsRunning(): boolean
	return running
end

function MatchTimer.GetElapsed(): number
	if running then
		return accumulated + (os.clock() - startTime)
	end
	return accumulated
end

return MatchTimer
