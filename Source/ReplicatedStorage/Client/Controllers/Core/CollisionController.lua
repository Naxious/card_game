local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")

local Knit = require(ReplicatedStorage.Packages.Knit)
local CollisionGroupEnums = require(ReplicatedStorage.Enums.CollisionGroupEnums)

local CollisionController = Knit.CreateController {
	Name = "CollisionController"
}

function CollisionController:addModelToCollisionGroup(groupName: string, model: Model)
	local collisionGroup = CollisionGroupEnums[groupName]
	if not collisionGroup then
		error("Collision group " .. groupName .. " does not exist")
	end

	for _, part in ipairs(model:GetDescendants()) do
		if part:IsA("BasePart") then
			PhysicsService:SetPartCollisionGroup(part, collisionGroup)
		end
	end
end

function CollisionController:addPartToCollisionGroup(groupName: string, part: BasePart)
	local collisionGroup = CollisionGroupEnums[groupName]
	if not collisionGroup then
		error("Collision group " .. groupName .. " does not exist")
	end

	PhysicsService:SetPartCollisionGroup(part, collisionGroup)
end

return CollisionController