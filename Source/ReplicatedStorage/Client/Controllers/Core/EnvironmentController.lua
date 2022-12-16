local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local WindShake = require(ReplicatedStorage.Libraries.WindShake)

local WIND_DIRECTION = Vector3.new(1, 0, 0.3)
local WIND_SPEED = 25
local WIND_POWER = 0.6

local EnvironmentController = Knit.CreateController {
	Name = "EnvironmentController",
}

function EnvironmentController:KnitStart()
	WindShake:SetDefaultSettings({
		WindSpeed = WIND_SPEED,
		WindDirection = WIND_DIRECTION,
		WindPower = WIND_POWER,
	})

	WindShake:Init()
end

return EnvironmentController