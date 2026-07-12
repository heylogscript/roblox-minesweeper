--!strict
-- Signal — lightweight custom signal class. No BindableEvent, no Instance allocation.

export type Connection = {
	Connected: boolean,
	Disconnect: (self: Connection) -> (),
}

export type Signal = {
	Connect: (self: Signal, callback: (...any) -> ()) -> Connection,
	Fire: (self: Signal, ...any) -> (),
	Destroy: (self: Signal) -> (),
}

local Signal = {}
Signal.__index = Signal

function Signal.new(): Signal
	return setmetatable({
		_connections = {},
		_destroyed = false,
	}, Signal)
end

function Signal:Connect(callback: (...any) -> ()): Connection
	if self._destroyed then
		error("Cannot connect to a destroyed signal", 2)
	end

	local entry = { callback = callback }
	table.insert(self._connections, entry)

	local connection: Connection = {
		Connected = true,
	}
	connection.Disconnect = function()
		if not connection.Connected then
			return
		end
		connection.Connected = false
		for i, e in ipairs(self._connections) do
			if e == entry then
				table.remove(self._connections, i)
				return
			end
		end
	end
	return connection
end

function Signal:Fire(...: any): ()
	if self._destroyed then
		return
	end

	local snapshot = {}
	for _, entry in ipairs(self._connections) do
		table.insert(snapshot, entry)
	end

	for _, entry in ipairs(snapshot) do
		entry.callback(...)
	end
end

function Signal:Destroy(): ()
	self._destroyed = true
	self._connections = {}
end

return Signal
