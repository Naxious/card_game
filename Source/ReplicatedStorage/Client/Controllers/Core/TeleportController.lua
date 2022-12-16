local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AudioData = require(ReplicatedStorage.Data.AudioData)

local TELEPORT_TAG = "Teleport"
local TELEPORT_DIRECTION_ATTRIBUTE = "TeleportDirection"
local TELEPORT_DEBOUNCE_DELAY = 3

local audioController

local localPlayer = Players.LocalPlayer
local teleportDebounce

local function teleportPlayer(character: Model, teleportPart: BasePart)
	character:PivotTo(teleportPart:GetPivot())

	audioController:playSound(AudioData.Effects.Teleport)

	task.delay(TELEPORT_DEBOUNCE_DELAY, function()
		teleportDebounce = false
	end)
end

local function setupTeleport(teleport: Model)
	local teleportParts = teleport:GetDescendants()

	local function setupTouchEvent(enterPart: BasePart, exitPart: BasePart, bidirectional: boolean)
		if not enterPart:IsA("BasePart") or not exitPart:IsA("BasePart") then
			error("Passed improper teleport Enter/Exit parts")
		end

		enterPart.Touched:Connect(function(hit)
			if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") then
				if teleportDebounce then
					return
				end
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player ~= localPlayer then
					return
				end
				teleportDebounce = true

				teleportPlayer(character, exitPart)
			end
		end)

		if not bidirectional then
			return
		end

		exitPart.Touched:Connect(function(hit)
			if hit.Parent and hit.Parent:FindFirstChildOfClass("Humanoid") then
				if teleportDebounce then
					return
				end
				local character = hit.Parent
				local player = Players:GetPlayerFromCharacter(character)
				if player ~= localPlayer then
					return
				end
				teleportDebounce = true

				teleportPlayer(character, enterPart)
			end
		end)
	end

	local teleportEnter, teleportExit
	for _, part in ipairs(teleportParts) do
		if not part:IsA("BasePart") then
			continue
		end

		if part.Name == "Enter" then
			teleportEnter = part
			continue
		elseif part.Name == "Exit" then
			teleportExit = part
			continue
		end
	end

	if not teleportEnter or not teleportExit then
		print("Teleport Model that errors: ", teleport)
		error("Teleport needs 'Enter' and 'Exit' parts!")
	end

	local direction = teleport:GetAttribute(TELEPORT_DIRECTION_ATTRIBUTE)
	if typeof(direction) ~= "boolean" then
		error("Teleport Direction attribute must be a boolean!")
	end

	if direction then
		setupTouchEvent(teleportEnter, teleportExit, false)
	else
		setupTouchEvent(teleportExit, teleportEnter, true)
	end
end

local TeleportController = Knit.CreateController {
	Name = "TeleportController",
}

function TeleportController:KnitStart()
	audioController = Knit.GetController("AudioController")

	for _, teleport in ipairs(CollectionService:GetTagged(TELEPORT_TAG)) do
		setupTeleport(teleport)
	end
end

return TeleportController