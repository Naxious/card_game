local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _, child in pairs(ReplicatedStorage.Client.Controllers:GetDescendants()) do
	if child:IsA("ModuleScript") and child.name:match("Controller$") then
		warn("🎮 Loading controller", child.name)
		require(child)
	end
end

for _,module in pairs(ReplicatedStorage.Client.Components:GetDescendants()) do
	if module:IsA("ModuleScript") then
		warn("💠 Loading component", module.name)
		require(module)
	end
end

Knit.Start():catch(warn)