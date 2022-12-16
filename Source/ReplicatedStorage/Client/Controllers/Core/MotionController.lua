local CollectionService = game:GetService("CollectionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SEE_MOTION_DISTANCE = 200

local SPIN_TAG = "Spin"
local SPIN_AXIS_ATTRIBUTE = "SpinAxis"
local SPIN_DIRECTION_ATTRIBUTE = "SpinDirection"
local SPIN_SPEED_ATTRIBUTE = "SpinSpeed"

local HOVER_TAG = "Hover"
local HOVER_AXIS_ATTRIBUTE = "HoverAxis"
local HOVER_HEIGHT_ATTRIBUTE = "HoverHeight"
local HOVER_SPEED_ATTRIBUTE = "HoverSpeed"

local DEFAULT_HOVER_AXIS = "Y"
local DEFAULT_HOVER_HEIGHT = 2
local DEFAULT_HOVER_SPEED = 0.05

local DEFAULT_SPIN_AXIS = "X"
local DEFAULT_SPIN_DIRECTION = true
local DEFAULT_SPIN_SPEED = 0.01

local TAU = math.pi * 2

local localPlayer = Players.LocalPlayer

local MotionController = Knit.CreateController {
	Name = "MotionController",
	_motionHeartbeat = nil,
	_spinningParts = {},
	_hoveringParts = {},
}

function MotionController:KnitStart()
	local spinParts = CollectionService:GetTagged(SPIN_TAG)
	for _, part in pairs(spinParts) do
		if not part:IsA("BasePart") then
			print("Spin part", part)
			error("Spin tag is not on a BasePart")
		end

		local spinAxis = part:GetAttribute(SPIN_AXIS_ATTRIBUTE)
		local spinDirection = part:GetAttribute(SPIN_DIRECTION_ATTRIBUTE)
		local spinSpeed = part:GetAttribute(SPIN_SPEED_ATTRIBUTE)

		if spinDirection == nil then
			spinDirection = DEFAULT_SPIN_DIRECTION
		end

		if spinSpeed == nil then
			spinSpeed = DEFAULT_SPIN_SPEED
		end

		if spinAxis == nil then
			spinAxis = DEFAULT_SPIN_AXIS
		end

		table.insert(self._spinningParts, {
			part = part,
			spinAxis = spinAxis,
			spinDirection = spinDirection,
			spinSpeed = spinSpeed,
			originalCFrame = part:GetPivot(),
			animationTime = 0,
		})
	end

	local hoverParts = CollectionService:GetTagged(HOVER_TAG)
	for _, part in pairs(hoverParts) do
		if not part:IsA("BasePart") then
			print("Hover part", part)
			error("Hover tag is not on a BasePart")
		end

		local hoverAxis = part:GetAttribute(HOVER_AXIS_ATTRIBUTE)
		local hoverHeight = part:GetAttribute(HOVER_HEIGHT_ATTRIBUTE)
		local hoverSpeed = part:GetAttribute(HOVER_SPEED_ATTRIBUTE)

		if hoverAxis == nil then
			hoverAxis = DEFAULT_HOVER_AXIS
		end

		if hoverHeight == nil then
			hoverHeight = DEFAULT_HOVER_HEIGHT
		end

		if hoverSpeed == nil then
			hoverSpeed = DEFAULT_HOVER_SPEED
		end

		table.insert(self._hoveringParts, {
			part = part,
			hoverAxis = hoverAxis,
			hoverHeight = hoverHeight,
			hoverSpeed = hoverSpeed,
			originalCFrame = part:GetPivot(),
			animationTime = 0,
		})
	end

	self:startMotionHeartbeat()
end

function MotionController:startMotionHeartbeat()
	self._motionHeartbeat = RunService.Heartbeat:Connect(function(deltaTime)
		local currentPosition = localPlayer.Character and localPlayer.Character.PrimaryPart.Position or Vector3.new(0, 0, 0)
		for _, spinData in pairs(self._spinningParts) do
			if (spinData.part.Position - currentPosition).Magnitude > SEE_MOTION_DISTANCE then
				continue
			end

			spinData.animationTime += deltaTime * spinData.spinSpeed * (spinData.spinDirection and 1 or -1) * TAU * 2
			if spinData.animationTime >= TAU then
				spinData.animationTime -= TAU
			end

			local spinAngle = spinData.animationTime * spinData.spinSpeed
			local spinCFrame = CFrame.Angles(
				spinData.spinAxis == "X" and spinAngle or 0,
				spinData.spinAxis == "Y" and spinAngle or 0,
				spinData.spinAxis == "Z" and spinAngle or 0
			)

			spinData.part:PivotTo(spinData.originalCFrame * spinCFrame)
		end

		for _, hoverData in pairs(self._hoveringParts) do
			if (hoverData.part.Position - currentPosition).Magnitude > SEE_MOTION_DISTANCE then
				continue
			end

			hoverData.animationTime += deltaTime * hoverData.hoverSpeed * TAU * 2
			if hoverData.animationTime >= TAU then
				hoverData.animationTime -= TAU
			end

			local hoverAngle = math.sin(hoverData.animationTime) * hoverData.hoverHeight
			local hoverCFrame = CFrame.new(
				hoverData.hoverAxis == "X" and hoverAngle or 0,
				hoverData.hoverAxis == "Y" and hoverAngle or 0,
				hoverData.hoverAxis == "Z" and hoverAngle or 0
			)

			hoverData.part:PivotTo(hoverData.originalCFrame * hoverCFrame)
		end
	end)
end

return MotionController