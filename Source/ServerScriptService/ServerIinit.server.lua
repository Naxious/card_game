local SererScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Knit = require(ReplicatedStorage.Packages.Knit)

for _, child in pairs(SererScriptService.Services:GetDescendants()) do
	if child:IsA("ModuleScript") and child.name:match("Service$") then
		warn("⚙️ Loading service", child.name)
		require(child)
	end
end

Knit.Start():catch(warn)