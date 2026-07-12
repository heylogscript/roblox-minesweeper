--!strict
-- AnimationController — sole module responsible for creating and playing animations.
-- Stateless utility. Receives CellVisual references only.

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local DefaultTheme = require(script.Parent.Themes.DefaultTheme)

local AnimationController = {}

function AnimationController.Reveal(cellVisual: any): ()
	if not DefaultTheme.Animation.Enabled then
		return
	end

	local base = cellVisual.base
	local theme = DefaultTheme.Animation
	local originalSize = base.Size
	local targetSize = originalSize * theme.RevealScale

	local tween = TweenService:Create(base, TweenInfo.new(
		theme.RevealDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0,
		true
	), {
		Size = targetSize,
		Transparency = 0.25,
	})
	tween:Play()
end

function AnimationController.Flag(cellVisual: any): ()
	if not DefaultTheme.Animation.Enabled then
		return
	end

	local model = cellVisual.flagModel
	if not model then
		return
	end

	local theme = DefaultTheme.Animation

	local parts: { BasePart } = {}
	local originalSizes: { Vector3 } = {}
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
			table.insert(originalSizes, child.Size)
			child.Size = child.Size * theme.FlagPopScale
		end
	end

	if #parts == 0 then
		return
	end

	for i, part in ipairs(parts) do
		local tween = TweenService:Create(part, TweenInfo.new(
			theme.FlagPopDuration,
			Enum.EasingStyle.Back,
			Enum.EasingDirection.Out
		), {
			Size = originalSizes[i],
		})
		tween:Play()
	end
end

function AnimationController.RemoveFlag(cellVisual: any, flagModel: Model): ()
	if not DefaultTheme.Animation.Enabled then
		flagModel:Destroy()
		return
	end

	local theme = DefaultTheme.Animation

	local parts: { BasePart } = {}
	for _, child in ipairs(flagModel:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end

	if #parts == 0 then
		flagModel:Destroy()
		return
	end

	local remaining = #parts
	for _, part in ipairs(parts) do
		local tween = TweenService:Create(part, TweenInfo.new(
			theme.FlagRemoveDuration,
			Enum.EasingStyle.Quad,
			Enum.EasingDirection.In
		), {
			Size = part.Size * 0.01,
			Transparency = 1,
		})
		tween.Completed:Once(function()
			if not part or not part.Parent then
				return
			end
			remaining -= 1
			if remaining <= 0 then
				flagModel:Destroy()
			end
		end)
		tween:Play()
	end
end

function AnimationController.Mine(cellVisual: any): ()
	if not DefaultTheme.Animation.Enabled then
		return
	end

	local base = cellVisual.base
	local theme = DefaultTheme.Animation
	local currentSize = base.Size

	local tween = TweenService:Create(base, TweenInfo.new(
		theme.MineDuration,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out,
		0,
		true
	), {
		Size = currentSize * theme.MinePulseScale,
		Color = theme.MineFlashColor,
	})
	tween:Play()
end

function AnimationController.FlagPop(cellVisual: any): ()
	local model = cellVisual.flagModel
	if not model then return end

	local parts: { BasePart } = {}
	for _, child in ipairs(model:GetDescendants()) do
		if child:IsA("BasePart") then
			table.insert(parts, child)
		end
	end
	if #parts == 0 then return end

	-- Calculate model center and store relative data
	local center = Vector3.new()
	for _, part in ipairs(parts) do
		center += part.Position
	end
	center /= #parts

	local relativePos = table.create(#parts)
	local origRot = table.create(#parts)
	for i, part in ipairs(parts) do
		relativePos[i] = part.Position - center
		origRot[i] = part.CFrame.Rotation
	end

	-- Lift flags off the ground
	local LIFT_HEIGHT = 2.5
	for _, part in ipairs(parts) do
		TweenService:Create(part, TweenInfo.new(0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = part.Position + Vector3.new(0, LIFT_HEIGHT, 0),
		}):Play()
	end

	-- Continuous bob + group spin
	task.delay(0.3, function()
		if not model or not model.Parent then return end

		local startTime = os.clock()
		local rotationAngle = 0
		local conn: RBXScriptConnection
		conn = RunService.Heartbeat:Connect(function(dt: number)
			if not model or not model.Parent then
				conn:Disconnect()
				return
			end

			local elapsed = os.clock() - startTime
			local bobY = math.sin(elapsed * 3) * 0.8
			rotationAngle += math.rad(36) * dt

			local groupRot = CFrame.Angles(0, rotationAngle, 0)

			for i, part in ipairs(parts) do
				local rel = relativePos[i]
				local rotatedRel = groupRot * rel
				local pos = Vector3.new(
					center.X + rotatedRel.X,
					center.Y + LIFT_HEIGHT + bobY + rotatedRel.Y,
					center.Z + rotatedRel.Z
				)
				part.CFrame = CFrame.new(pos) * (groupRot * origRot[i])
			end
		end)
	end)
end

function AnimationController.GreenReveal(cellVisual: any, delay: number): ()
	task.delay(delay, function()
		if not cellVisual or not cellVisual.base then return end
		local base = cellVisual.base
		local og = base.Color
		base.Color = Color3.fromRGB(30, 30, 35)
		local tween = TweenService:Create(base, TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), { Color = Color3.fromRGB(60, 220, 80) })
		tween:Play()
	end)
end

return AnimationController
