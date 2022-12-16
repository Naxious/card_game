local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local SHOULD_DIURNAL_CONTROLLER_RUN = false

local UPDATE_FREQUENCY = 1
local HOURS_IN_DAY = 24
local HOURS_IN_SIMULATED_DAY = 0.5 -- 15 minutes = 0.25 and 30 minutes = 0.5
local MINUTES_IN_SIMULATED_DAY = HOURS_IN_SIMULATED_DAY * 60
local MINUTES_IN_SIMULATED_HOUR = MINUTES_IN_SIMULATED_DAY / HOURS_IN_DAY

local syncController
local a = 0
local function startDiurnalHeartbeat(self: any)
	local updateCheck = 0
	self._diurnalHeartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
		updateCheck += deltaTime
		if updateCheck < UPDATE_FREQUENCY then
			return
		end
		updateCheck -= UPDATE_FREQUENCY

		self._currentTime = syncController:getCurrentTime()
		local currentMinuteAfterMidnight = (self._currentTime % 86400) / 60
		local currentMinuteAfterMidnightInSimulatedDay = currentMinuteAfterMidnight / MINUTES_IN_SIMULATED_HOUR
		local currentSimulatedHour = currentMinuteAfterMidnightInSimulatedDay % HOURS_IN_DAY

		if currentSimulatedHour < self._lastTimeCheck then
			Lighting.ClockTime = 0
		end

		local tweenInfo = TweenInfo.new(UPDATE_FREQUENCY, Enum.EasingStyle.Linear)
		local tween = TweenService:Create(Lighting, tweenInfo, {
			ClockTime = currentSimulatedHour
		})
		tween:Play()

		self._lastTimeCheck = currentSimulatedHour
	end)
end

local DiurnalController = Knit.CreateController {
	Name = "DiurnalController",
	_diurnalHeartbeat = nil,
	_lastTimeCheck = 0,
	_currentTime = 0,
	_minutesAfterMidnight = 0,
	_timeCycleHeartbeat = nil,
}

function DiurnalController:KnitStart()
	syncController = Knit.GetController("SyncController")

	local repeatCount = 0
	repeat
		self._currentTime = syncController:getCurrentTime()
		repeatCount += 1
		task.wait(1)
	until self._currentTime ~= 0 or repeatCount > 30

	if not SHOULD_DIURNAL_CONTROLLER_RUN then
		return
	end
	startDiurnalHeartbeat(self)
end

function DiurnalController:getCurrentTime()
	return self._currentTime
end

function DiurnalController:getMinutesAfterMidnight()
	return self._minutesAfterMidnight
end

return DiurnalController