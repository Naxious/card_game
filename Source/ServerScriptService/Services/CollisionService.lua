local ReplicatedStorage = game:GetService("ReplicatedStorage")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local CollisionGroupEnums = require(ReplicatedStorage.Enums.CollisionGroupEnums)

local collisionGroups = {}

local function setCollisionGroupsCollidable(group1: string, group2: string, collidable: boolean)
	PhysicsService:CollisionGroupSetCollidable(group1, group2, collidable)
end

local CollisionService = Knit.CreateService {
	Name = "CollisionService"
}

function CollisionService:KnitInit()
	for _, collisionGroup in pairs(CollisionGroupEnums) do
		collisionGroups[collisionGroup] = PhysicsService:CreateCollisionGroup(collisionGroup)
	end

	for _, player in pairs(Players:GetPlayers()) do
		if not player.Character then
			continue
		end

		self:addModelToCollisionGroup(player.Character, CollisionGroupEnums.Players)
	end

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			self:addModelToCollisionGroup(CollisionGroupEnums.Players, character)
		end)
	end)

	setCollisionGroupsCollidable(CollisionGroupEnums.Players, CollisionGroupEnums.Players, false)
end

function CollisionService:addModelToCollisionGroup(groupName: string, model: Model)
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

function CollisionService:addPartToCollisionGroup(groupName: string, part: BasePart)
	local collisionGroup = CollisionGroupEnums[groupName]
	if not collisionGroup then
		error("Collision group " .. groupName .. " does not exist")
	end

	PhysicsService:SetPartCollisionGroup(part, collisionGroup)
end

return CollisionService