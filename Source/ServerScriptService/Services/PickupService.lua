local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local PickupTypeEnums = require(ReplicatedStorage.Enums.PickupTypeEnums)

local PICKUP_FOLDER_NAME = "PickupFolder"
local PICKUP_SPAWNER_PAD_TAG = "PickupSpawnerPad"
local PICKUP_TAG = "Pickup"
local PICKUP_TYPE_ATTRIBUTE = "PickupType"
local TOTAL_PICKUPS = 100

local PICKUP_MIN_AMOUNT = 3
local PICKUP_MAX_AMOUNT = 5

local PICKUP_TYPES = {
	[1] = PickupTypeEnums.GasCan,
	[2] = PickupTypeEnums.GasPump
}

local DataService

local isCurrentlySpawningPickups = false

local function createPickupPart()
	local pickupType = PICKUP_TYPES[math.random(1, #PICKUP_TYPES)]

	local pickupPart = Instance.new("Part")
	pickupPart.Anchored = true
	pickupPart.CanCollide = false
	pickupPart.Size = Vector3.new(3, 3, 3)
	pickupPart.Transparency = 1
	pickupPart.Name = pickupType

	CollectionService:AddTag(pickupPart, PICKUP_TAG)

	pickupPart:SetAttribute(PICKUP_TYPE_ATTRIBUTE, pickupType)

	return pickupPart
end

local function spawnPickupParts(self: any)
	if isCurrentlySpawningPickups then
		return
	end
	isCurrentlySpawningPickups = true

	local currentPickups: number = #self._pickups
	if not currentPickups or currentPickups == 0 then
		currentPickups = 1
	end

	for _ = currentPickups, TOTAL_PICKUPS - 1 do
		local pickupPart: BasePart = createPickupPart()

		local randomPad, randomCFrame
		local isTouchingOtherPickup = true
		repeat
			randomPad = self._spawnerPads[math.random(1, #self._spawnerPads)]
			randomCFrame = randomPad.CFrame * CFrame.new(math.random(-randomPad.Size.X / 2, randomPad.Size.X / 2), 0, math.random(-randomPad.Size.Z / 2, randomPad.Size.Z / 2))

			local touchingParts = workspace:GetPartBoundsInBox(randomCFrame, pickupPart.Size)
			for index, touchingPart in pairs(touchingParts) do
				if CollectionService:HasTag(touchingPart, PICKUP_TAG) then
					isTouchingOtherPickup = true
					break
				end

				if index == #touchingParts then
					isTouchingOtherPickup = false
				end
			end
			task.wait()
		until not isTouchingOtherPickup

		pickupPart:PivotTo(randomCFrame)
		pickupPart.Parent = self._pickupFolder

		table.insert(self._pickups, pickupPart)
		self._pickupValues[pickupPart] = math.random(PICKUP_MIN_AMOUNT, PICKUP_MAX_AMOUNT)
	end

	isCurrentlySpawningPickups = false
end

local PickupService = Knit.CreateService {
	Name = "PickupService",
	Client = {
		collectedPickupSignal = Knit.CreateSignal()
	},
	_pickupFolder = nil,
	_spawnerPads = {},
	_pickups = {},
	_pickupValues = {},
	_heartbeat = nil,
}

function PickupService:KnitInit()
	self._pickupFolder = Instance.new("Folder")
	self._pickupFolder.Name = PICKUP_FOLDER_NAME
	self._pickupFolder.Parent = workspace

	local pickupPads = CollectionService:GetTagged(PICKUP_SPAWNER_PAD_TAG)
	for _, pad in pairs(pickupPads) do
		table.insert(self._spawnerPads, pad)
	end

	CollectionService:GetInstanceAddedSignal(PICKUP_SPAWNER_PAD_TAG):Connect(function(pad)
		table.insert(self._spawnerPads, pad)
	end)

	self.Client.collectedPickupSignal:Connect(function(player, pickupPart)
		--TODO: add sanity check to make sure player is actually in range of pickup
		local index = table.find(self._pickups, pickupPart)
		if index then
			pickupPart:Destroy()

			local profile = DataService:getProfile(player)
			if profile then
				profile.Data.FuelCollected += self._pickupValues[pickupPart]
			end

			table.remove(self._pickups, index)
			self._pickupValues[pickupPart] = nil
		end
	end)

	self:startHeartbeat()
end

function PickupService:KnitStart()
	DataService = Knit.GetService("DataService")
end

function PickupService:startHeartbeat()
	self._pickupHeartbeat = RunService.Heartbeat:Connect(function()
		if #self._pickups > TOTAL_PICKUPS then
			return
		end

		spawnPickupParts(self)
	end)
end

return PickupService