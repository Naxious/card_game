local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

local camera = workspace.CurrentCamera

local CameraController = Knit.CreateController {
	Name = "CameraController",
}

function CameraController:followTarget(target: Instance)
	camera.CameraSubject = target
end

return CameraController