local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local function startTimerHeartbeat(self: any)
	self.timerHeartbeat = RunService.Heartbeat:Connect(function()
		self.currentTime = os.clock()
		self.currentTimeString = string.format("%.3f", self.currentTime)
	end)
end

local SyncService = Knit.CreateService {
	Name = "SyncService",
	Client = {},
	currentTime = os.clock(),
	currentTimeString = "0"
}

function SyncService:KnitInit()
	self.currentTime = os.clock()
	self.currentTimeString = string.format("%.3f", self.currentTime)

	startTimerHeartbeat(self)
end

function SyncService:getCurrentTime()
	return (tonumber(self.currentTimeString))
end

function SyncService.Client:getTime()
	return self.Server.currentTime
end

return SyncService