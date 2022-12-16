local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PickupTypeEnums = require(ReplicatedStorage.Enums.PickupTypeEnums)

local PICKUP_TAG = "Pickup"

local PickupService
local pickupDebounce = {}

local pickupGasCan = ReplicatedStorage.Assets.Pickups["Icon_GasCan"]
local pickupGasPump = ReplicatedStorage.Assets.Pickups["Icon_GasPump"]

local function createPickupModel(pickupPart: BasePart)
	local pickupModel = Instance.new("Model")
	pickupModel.Name = "Pickup"

	local pickupType = pickupPart:GetAttribute("PickupType")
	local pickup
	if pickupType == PickupTypeEnums.GasCan then
		pickup = pickupGasCan:Clone()
	elseif pickupType == PickupTypeEnums.GasPump then
		pickup = pickupGasPump:Clone()
	end
	pickup.Parent = pickupModel

	pickupModel:PivotTo(pickupPart:GetPivot() + Vector3.new(0, pickup.Size.Y/4, 0))

	pickupModel.Parent = pickupPart
end

local function setupPickupTouchConnection(self: any, pickupPart: BasePart)
	local connection
	connection = pickupPart.Touched:Connect(function(hit: Instance)
		if hit.Parent:IsA("Model") and hit.Parent:FindFirstChild("Humanoid") then
			if pickupDebounce[pickupPart] then
				return
			end
			pickupDebounce[pickupPart] = true

			connection:Disconnect()
			connection = nil

			pickupPart:Destroy()
			local index = table.find(self._pickups, pickupPart)
			if index then
				table.remove(self._pickups, index)
			end

			PickupService.collectedPickupSignal:Fire(pickupPart)

			task.delay(1, function()
				pickupDebounce[pickupPart] = nil
			end)
		end
	end)
end

local function addPickup(self: any, pickupPart: BasePart)
	createPickupModel(pickupPart)
	setupPickupTouchConnection(self, pickupPart)
	table.insert(self._pickups, pickupPart)
end

local PickupController = Knit.CreateController {
	Name = "PickupController",
	_pickups = {},
}

function PickupController:KnitStart()
	PickupService = Knit.GetService("PickupService")

	local pickups = CollectionService:GetTagged(PICKUP_TAG)
	for _, pickupPart in pairs(pickups) do
		addPickup(self, pickupPart)
		task.wait()
	end

	CollectionService:GetInstanceAddedSignal(PICKUP_TAG):Connect(function(pickupPart)
		addPickup(self, pickupPart)
		task.wait()
	end)

	CollectionService:GetInstanceRemovedSignal(PICKUP_TAG):Connect(function(pickupPart)
		local index = table.find(self._pickups, pickupPart)
		if index then
			table.remove(self._pickups, index)
		end
	end)

	PickupService.collectedPickupSignal:Fire()
end

return PickupController