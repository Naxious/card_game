local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local LAUNCH_ZONE_TAG = "LaunchZone"
local LAUNCH_PAD_TAG = "LaunchPad"

local rocketBody = ReplicatedStorage.Assets.RocketParts.Body

local LaunchService = Knit.CreateService {
	Name = "LaunchService",
	Client = {
		requestLaunch = Knit.CreateSignal(),
		requestLaunchZone = Knit.CreateSignal(),
		finishedLaunch = Knit.CreateSignal(),
	},
	_launchZoneCFrame = nil,
	_launchPad = nil,
}

function LaunchService:KnitInit()
	local launchButtons = CollectionService:GetTagged(LAUNCH_ZONE_TAG)
	if #launchButtons > 1 then
		error("There should only be one launch button!")
	end
	self._launchZoneCFrame = launchButtons[1]:GetPivot()
	launchButtons[1]:Destroy()

	local launchPads = CollectionService:GetTagged(LAUNCH_PAD_TAG)
	if #launchPads > 1 then
		error("There should only be one launch pad!")
	end
	self._launchPad = launchPads[1]
	launchPads[1].Transparency = 1

	self.Client.requestLaunch:Connect(function(player: Player)
		self:playerRequestingLaunch(player)
	end)

	self.Client.requestLaunchZone:Connect(function(player: Player)
		self:sendLaunchZone(player)
	end)
end

function LaunchService:sendLaunchZone(player: Player)
	self.Client.requestLaunchZone:Fire(player, self._launchZoneCFrame)
end

function LaunchService:playerRequestingLaunch(player: Player)
	local rocket = self:createRocketForPlayer(player)

	self.Client.requestLaunch:Fire(player, rocket)
	local rocketHeartbeat

	local launchHeight = 0
	rocketHeartbeat = RunService.Heartbeat:Connect(function(deltaTime)
		rocket:PivotTo(rocket.PrimaryPart.CFrame * CFrame.new(0, 10 * deltaTime, 0))
		launchHeight += 10 * deltaTime
	end)

	task.delay(5, function()
		self.Client.finishedLaunch:Fire(player)
		rocketHeartbeat:Disconnect()
		launchHeight = 0
	end)
end

function LaunchService:createRocketForPlayer(player: Player)
	local rocketModel = Instance.new("Model")
	rocketModel.Name = player.Name .. "_Rocket"

	local rocketBodyClone: BasePart = rocketBody:Clone()
	rocketBodyClone.Parent = rocketModel

	rocketModel.PrimaryPart = rocketBodyClone

	local rocketSize = rocketModel:GetExtentsSize()
	rocketModel:PivotTo(CFrame.new(self._launchPad.Position + Vector3.new(0, self._launchPad.Size.Y/2 + rocketSize.Y/2, 0)))
	rocketModel.Parent = workspace

	return rocketModel
end

return LaunchService