local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local LaunchService
local CameraController
local localPlayer = Players.LocalPlayer

local currentlyLaunching = false

local LaunchController = Knit.CreateController {
	Name = "LaunchController",
	_launchPad = nil,
	_launchZoneCFrame = nil,
	_launchHeartbeat = nil,
}

function LaunchController:KnitStart()
	LaunchService = Knit.GetService("LaunchService")

	CameraController = Knit.GetController("CameraController")

	LaunchService.requestLaunchZone:Fire()

	LaunchService.requestLaunchZone:Connect(function(launchZoneCFrame: CFrame)
		self._launchZoneCFrame = launchZoneCFrame
		self:startLaunchHeartbeat()
	end)

	LaunchService.requestLaunch:Connect(function(rocket: Model)
		self:beginLaunchSequence(rocket)
	end)

	LaunchService.finishedLaunch:Connect(function()
		currentlyLaunching = false
		self:endLaunchSequence()
	end)
end

function LaunchController:startLaunchHeartbeat()
	local checkingLaunch = false
	self._launchHeartbeat = RunService.Heartbeat:Connect(function()
		if checkingLaunch or currentlyLaunching then
			return
		end
		checkingLaunch = true

		local character = localPlayer.Character
		if not character then
			checkingLaunch = false
			return
		end

		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if not humanoidRootPart then
			checkingLaunch = false
			return
		end

		local distance = (humanoidRootPart.Position - self._launchZoneCFrame.Position).Magnitude
		if distance < 10 then
			character:PivotTo(CFrame.new(Vector3.new(0, 15, 0)))
			currentlyLaunching = true
			LaunchService.requestLaunch:Fire()
		end

		checkingLaunch = false
	end)
end

function LaunchController:beginLaunchSequence(rocket: Model)
	CameraController:followTarget(rocket.PrimaryPart)
end

function LaunchController:endLaunchSequence()
	local humanoid = localPlayer.Character and localPlayer.Character:FindFirstChild("Humanoid")
	if not humanoid then
		return
	end

	CameraController:followTarget(humanoid)
end

return LaunchController