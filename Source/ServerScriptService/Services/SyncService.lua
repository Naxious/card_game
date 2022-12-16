local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local function startTimerHeartbeat(self: any)
	local timerCount = 0
	self.timerHeartbeat = RunService.Heartbeat:Connect(function(deltaTime: number)
		self.currentTime = os.clock()
		self.currentTimeString = string.format("%.3f", self.currentTime)

		timerCount += deltaTime
		if timerCount <= 2 then
			return
		end

		timerCount -= 2
		self.Client.timerSignal:FireAll()
	end)
end

local SyncService = Knit.CreateService {
	Name = "SyncService",
	Client = {
		timerSignal = Knit.CreateSignal()
	},
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