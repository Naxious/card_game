local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local DELTA_UPDATE_TIME = 30

local syncService
local localPlayer = Players.LocalPlayer

local function startTimerHeartbeat(self: any)
	local lastTick = tick() - DELTA_UPDATE_TIME
	self.timerHeartbeat = RunService.Heartbeat:Connect(function()
		self.currentTime = os.clock() + self.totalDeltaTime
		self.currentTimeString = string.format("%.3f", self.currentTime)

		if tick() - lastTick < DELTA_UPDATE_TIME then
			return
		end
		lastTick = tick()

		syncService.getTime():andThen(function(serverTime: number)
			self.totalDeltaTime = serverTime - os.clock() + (localPlayer:GetNetworkPing() / 2)
		end)
	end)
end

local SyncController = Knit.CreateController {
	Name = "SyncController",
	timerHeartbeat = nil,
	totalDeltaTime = 0,
	currentTime = 0,
	currentTimeString = "0"
}

function SyncController:KnitStart()
	syncService = Knit.GetService("SyncService")
	startTimerHeartbeat(self)
end

function SyncController:getCurrentTime()
	return (tonumber(self.currentTimeString))
end

return SyncController