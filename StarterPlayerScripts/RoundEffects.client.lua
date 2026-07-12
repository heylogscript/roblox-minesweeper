-- RoundEffects — subscribes to game events and applies non-rendering, non-HUD side effects.
-- Handles void lighting, camera teleport, character explosion, and result overlay UI.

local Workspace = game:GetService("Workspace")
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ClientGameState = require(ReplicatedStorage.Modules.Client.ClientGameState)
local BoardRenderer = require(ReplicatedStorage.Modules.Client.BoardRenderer)
local RoundEvents = require(ReplicatedStorage.Modules.Shared.Events.RoundEvents)
local UIEvents = require(ReplicatedStorage.Modules.Shared.Events.UIEvents)
local GameConfig = require(ReplicatedStorage.Modules.Config.GameConfig)
local DefaultTheme = require(ReplicatedStorage.Modules.Rendering.Themes.DefaultTheme)

local SPACING = DefaultTheme.Spacing
local hasTeleported: boolean = false

local function setupVoid(boardWidth: number, boardHeight: number): ()
	Lighting.Ambient = GameConfig.AmbientColor
	Lighting.Brightness = GameConfig.Brightness
	Lighting.OutdoorAmbient = GameConfig.OutdoorAmbient
	Lighting.ClockTime = 12
	Lighting.GlobalShadows = false
	Lighting.FogColor = GameConfig.FogColor
	Lighting.FogEnd = GameConfig.FogEnd
	Lighting.FogStart = GameConfig.FogStart

	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		sky:Destroy()
	end
end

local function teleportAboveBoard(board: any): ()
	if hasTeleported then
		return
	end
	hasTeleported = true

	setupVoid(board.Width, board.Height)

	local spawnCellX = math.random(1, board.Width)
	local spawnCellZ = math.random(1, board.Height)
	local centerX = (spawnCellX - 1) * SPACING
	local centerZ = (spawnCellZ - 1) * SPACING

	local camera = Workspace.CurrentCamera
	if not camera then
		camera = Workspace:WaitForChild("Camera") :: Camera
	end
	camera.CameraType = Enum.CameraType.Custom
	camera.CameraSubject = nil

	local player = Players.LocalPlayer
	if not player then return end
	local character = player.Character or player.CharacterAdded:Wait()
	local humanoid = character:WaitForChild("Humanoid", GameConfig.CharacterTimeout) :: Humanoid
	if humanoid then
		camera.CameraSubject = humanoid
	end
	local root = character:WaitForChild("HumanoidRootPart", GameConfig.CharacterTimeout)
	if root then
		root.CFrame = CFrame.new(centerX, GameConfig.BoardSpawnHeight, centerZ)
	end
end

local function explodeCharacter(): ()
	local player = Players.LocalPlayer
	if not player then return end
	local character = player.Character
	if not character then return end

	-- Ragdoll: disable animations, let physics take over
	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.PlatformStand = true
	end

	-- Launch upward with spin
	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.new(0, 400, 0)
		root.AssemblyAngularVelocity = Vector3.new(12, 0, 8)
	end

	-- Lock camera at current position
	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Scriptable
	end

	-- Visual explosion (no joint breaking)
	local rootPos = root and root.Position or Vector3.new(0, GameConfig.BoardSpawnHeight, 0)
	local explosion = Instance.new("Explosion")
	explosion.Position = rootPos
	explosion.BlastRadius = GameConfig.BlastRadius
	explosion.BlastPressure = GameConfig.BlastPressure
	explosion.DestroyJointRadiusPercent = 0
	explosion.ExplosionType = Enum.ExplosionType.NoCraters
	explosion.Parent = Workspace
end

local function showResult(text: string, color: Color3): ()
	local player = Players.LocalPlayer
	if not player then return end
	local playerGui = player:WaitForChild("PlayerGui")

	local gui = Instance.new("ScreenGui")
	gui.Name = "ResultGUI"
	gui.DisplayOrder = GameConfig.ResultDisplayOrder
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local overlay = Instance.new("Frame")
	overlay.Size = UDim2.fromScale(1, 1)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = GameConfig.ResultOverlayTransparency
	overlay.BorderSizePixel = 0
	overlay.Parent = gui

	local label = Instance.new("TextLabel")
	label.Size = UDim2.fromScale(1, 0.2)
	label.Position = UDim2.fromScale(0, 0.4)
	label.Text = text
	label.Font = Enum.Font.GothamBold
	label.TextColor3 = color
	label.BackgroundTransparency = 1
	label.TextScaled = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.Parent = gui

	task.delay(GameConfig.ResultDisplayDuration, function()
		gui:Destroy()
		local lobbyGui = playerGui:FindFirstChild("LobbyGUI")
		if lobbyGui then
			lobbyGui.Enabled = true
		end
	end)
end

RoundEvents.BoardCreated:Connect(function(board: any)
	hasTeleported = false
	teleportAboveBoard(board)
end)

local function teleportToLobby(): ()
	task.wait(3)

	local player = Players.LocalPlayer
	if not player then return end
	local character = player.Character
	if not character then return end

	local humanoid = character:FindFirstChild("Humanoid")
	if humanoid then
		humanoid.PlatformStand = false
	end

	local root = character:FindFirstChild("HumanoidRootPart")
	if root then
		root.AssemblyLinearVelocity = Vector3.new()
		root.AssemblyAngularVelocity = Vector3.new()

		local lobby = Workspace:FindFirstChild("Lobby")
		if lobby then
			local cf = lobby:GetAttribute("SpawnCFrame")
			if cf then
				root.CFrame = CFrame.new(cf)
			elseif lobby:IsA("BasePart") or lobby:IsA("Model") then
				local boxCF = lobby:GetBoundingBox()
				root.CFrame = CFrame.new(boxCF.X, boxCF.Y + 3, boxCF.Z)
			else
				local parts = lobby:GetDescendants()
				local sum, count = Vector3.new(), 0
				for _, v in ipairs(parts) do
					if v:IsA("BasePart") then
						sum += v.Position
						count += 1
					end
				end
				if count > 0 then
					root.CFrame = CFrame.new(sum / count + Vector3.new(0, 3, 0))
				end
			end
		end
	end

	local camera = Workspace.CurrentCamera
	if camera then
		camera.CameraType = Enum.CameraType.Custom
		camera.CameraSubject = humanoid
	end

	local pGui = player and player:FindFirstChild("PlayerGui")
	if pGui then
		local lobbyGui = pGui:FindFirstChild("LobbyGUI")
		if lobbyGui then
			local lbl = lobbyGui:FindFirstChild("Countdown", true)
			if lbl then
				lbl.Visible = false
			end
			local sub = lobbyGui:FindFirstChild("CountdownSub", true)
			if sub then
				sub.Visible = false
			end
			lobbyGui.Enabled = true
		end
	end
end

UIEvents.ShowDefeat:Connect(function(minePositions: { { x: number, y: number } }?)
	BoardRenderer.RevealAllMines(minePositions or {})
	task.spawn(explodeCharacter)
	task.spawn(teleportToLobby)
end)

UIEvents.ShowVictory:Connect(function(minePositions: { { x: number, y: number } }?)
	BoardRenderer.PlayWinEffect(minePositions or {})
	task.spawn(function()
		task.wait(8)
		teleportToLobby()
	end)
end)
