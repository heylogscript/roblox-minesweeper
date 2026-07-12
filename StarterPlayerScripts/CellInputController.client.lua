-- CellInputController — walk to reveal, click to flag.

local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local remotes = ReplicatedStorage:WaitForChild("Remotes")
local revealRemote = remotes:WaitForChild("RevealCell")
local toggleRemote = remotes:WaitForChild("ToggleFlag")
local ClientGameState = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Client"):WaitForChild("ClientGameState"))
local GameConfig = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("Config"):WaitForChild("GameConfig"))

print("CellInputController Loaded", script:GetFullName())

local lastCellX: number = -1
local lastCellY: number = -1
local debounce: boolean = false

local player = Players.LocalPlayer
local mouse = player:GetMouse()

local function getCellCoordsFromPart(part: BasePart): (number, number)
	local name = part.Name
	local _, _, xStr, yStr = name:find("Cell_(%d+)_(%d+)")
	if xStr and yStr then
		return tonumber(xStr) :: number, tonumber(yStr) :: number
	end
	local parent = part.Parent
	if parent and parent:IsA("Model") then
		_, _, xStr, yStr = parent.Name:find("Flag_(%d+)_(%d+)")
		if xStr and yStr then
			return tonumber(xStr) :: number, tonumber(yStr) :: number
		end
	end
	return 0, 0
end

-- Walk to reveal
RunService.Heartbeat:Connect(function()
	local character = player.Character
	if not character then return end
	local root = character:FindFirstChild("HumanoidRootPart")
	if not root then return end

	local origin = root.Position
	local rayDir = Vector3.new(0, -10, 0)
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	local filterList = { character }
	local flagsFolder = Workspace:FindFirstChild("MinesweeperFlags")
	if flagsFolder then
		filterList[#filterList + 1] = flagsFolder
	end
	params.FilterDescendantsInstances = filterList

	local result = Workspace:Raycast(origin, rayDir, params)
	if not result then return end
	if not result.Instance:IsA("BasePart") then return end

	local cx, cy = getCellCoordsFromPart(result.Instance)
	if cx < 1 or cy < 1 then return end

	if cx ~= lastCellX or cy ~= lastCellY then
		lastCellX = cx
		lastCellY = cy

		if not debounce then
			debounce = true
			revealRemote:FireServer(cx, cy)
			task.delay(GameConfig.RevealCooldown, function()
				debounce = false
			end)
		end
	end
end)

-- Left click to flag
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then
		return
	end

	if input.UserInputType ~= Enum.UserInputType.MouseButton1 then
		return
	end

	local now = os.clock()
	if now - ClientGameState.FlagClickTimestamp < GameConfig.FlagClickThrottle then
		return
	end
	ClientGameState.FlagClickTimestamp = now

	local target = mouse.Target
	if target and target:IsA("BasePart") then
		local cx, cy = getCellCoordsFromPart(target)
		if cx >= 1 and cy >= 1 then
			print("INPUTBEGAN", cx, cy)
			toggleRemote:FireServer(cx, cy)
		end
	end
end)

player.CharacterAdded:Connect(function()
	lastCellX = -1
	lastCellY = -1
end)

if player.Character then
	lastCellX = -1
	lastCellY = -1
end