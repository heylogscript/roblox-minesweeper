--!strict
-- SoundController — pure observer that plays audio in response to game events.
-- No gameplay references. No polling. No RenderStepped.
-- Reads sound IDs from DefaultTheme only.

local SoundService = game:GetService("SoundService")
local DefaultTheme = require(script.Parent.Parent.Parent.Rendering.Themes.DefaultTheme)
local RoundEvents = require(script.Parent.Parent.Parent.Shared.Events.RoundEvents)
local UIEvents = require(script.Parent.Parent.Parent.Shared.Events.UIEvents)

local SoundController = {}

local connections: { any } = {}
local folder: Folder? = nil
local soundInstances: { [string]: Sound } = {}

function SoundController.Create(): ()
	if folder then
		return
	end

	folder = Instance.new("Folder")
	folder.Name = "SoundController"
	folder.Parent = SoundService

	for name, soundId in pairs(DefaultTheme.Sounds) do
		local sound = Instance.new("Sound")
		sound.Name = name
		sound.SoundId = soundId
		sound.Parent = folder
		soundInstances[name] = sound
	end

	table.insert(connections, RoundEvents.CellRevealed:Connect(function()
		SoundController.Play("Reveal")
	end))
	table.insert(connections, RoundEvents.FlagPlaced:Connect(function()
		SoundController.Play("Flag")
	end))
	table.insert(connections, RoundEvents.FlagRemoved:Connect(function()
		SoundController.Play("FlagRemove")
	end))
	table.insert(connections, RoundEvents.RoundWon:Connect(function()
		SoundController.Play("Victory")
	end))
	table.insert(connections, RoundEvents.RoundLost:Connect(function()
		SoundController.Play("Explosion")
	end))
	table.insert(connections, RoundEvents.BoardCreated:Connect(function()
		SoundController.Play("Start")
	end))
	table.insert(connections, UIEvents.FaceChanged:Connect(function()
		SoundController.Play("Click")
	end))
end

function SoundController.Destroy(): ()
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	connections = {}
	soundInstances = {}
	if folder then
		folder:Destroy()
		folder = nil
	end
end

function SoundController.Play(soundName: string): ()
	local sound = soundInstances[soundName]
	if not sound then
		return
	end
	sound.TimePosition = 0
	sound:Play()
end

SoundController.Create()

return SoundController
