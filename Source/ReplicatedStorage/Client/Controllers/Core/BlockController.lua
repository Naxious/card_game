local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local diurnalController

local function moveBlock(block: BasePart, moveValue: Vector3)
	block.CFrame = block.CFrame + moveValue
end

local BlockController = Knit.CreateController {
	Name = "BlockController",
	_heartbeartConnection = nil,
	block = nil,
}

function BlockController:KnitInit()
	self.block = Instance.new("Part")
	self.block.Name = "Block"
	self.block.Size = Vector3.new(1, 1, 1)
	self.block.Anchored = true
	self.block.CanCollide = true
	self.block.Position = Vector3.new(0, 10, 0)
	self.block.Parent = workspace
end

function BlockController:KnitStart()
	print("BlockController KnitStart")
	diurnalController = Knit.GetController("DiurnalController")
	local syncService = Knit.GetService("SyncService")

	syncService.timerSignal:Connect(function()
		if not self.block then
			return
		end

		moveBlock(self.block, Vector3.new(0, math.random(0, 1) == 1 and 1 or -1, 0))
	end)

	local time = diurnalController:getCurrentTime()

	self:startBlockHeartbeat()
end

function BlockController:startBlockHeartbeat()

end

return BlockController