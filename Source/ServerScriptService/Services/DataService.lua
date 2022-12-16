local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ProfileService = require(ServerScriptService.Modules.ProfileService)
local ProfileTemplate = require(ServerScriptService.Data.ProfileTemplate)

local SECONDS_IN_DAY = 86400
local DAYS_IN_WEEK = 7
local SESSION_AMOUNT_AVERAGE = 20

local profileStore = ProfileService.GetProfileStore("PlayerData", ProfileTemplate)

local function successfullLogin(self: any, profile: any, player: Player)
	local currentTime = os.time()
	local timeSinceLastLogin = currentTime - profile.Data.lastLogin

	profile.Data.currentLogin = currentTime

	if timeSinceLastLogin < SECONDS_IN_DAY then
		return
	end

	profile.Data.lastLogin = currentTime

	if profile.Data.dailyLogins == 0 or timeSinceLastLogin < SECONDS_IN_DAY * 2 then
		profile.Data.dailyLogins += 1
	end

	if timeSinceLastLogin > SECONDS_IN_DAY * 2 or profile.Data.dailyLogins > DAYS_IN_WEEK then
		profile.Data.dailyLogins = 1
	end

	self.dailyLoginEvent:Fire(player, profile.Data.dailyLogins)
end

local function successfullLogout(profile: any)
	if profile.Data.currentLogin == 0 then
		return
	end

	local timePlayed = os.time() - profile.Data.currentLogin

	profile.Data.totalTimePlayed += timePlayed

	local sessionTimes = profile.Data.sessionTimes
	repeat
		if #sessionTimes >= SESSION_AMOUNT_AVERAGE then
			table.remove(sessionTimes, 1)
		end
		task.wait()
	until #sessionTimes <= SESSION_AMOUNT_AVERAGE - 1
	table.insert(sessionTimes, timePlayed)

	profile.Data.sessionTimes = sessionTimes

	local averageSessionTime = 0
	for _, sessionTime in pairs(sessionTimes) do
		averageSessionTime += sessionTime
	end

	profile.Data.averageSessionTime = averageSessionTime / #sessionTimes

	print("Profile Logged out", profile.Data)
end

local DataService = Knit.CreateService {
	Name = "DataService",
	_profiles = {},
	dailyLoginEvent = Instance.new("BindableEvent"),
}

function DataService:KnitInit()
	Players.PlayerAdded:Connect(function(player)
		self:playerAdded(player)
	end)

	Players.PlayerRemoving:Connect(function(player)
		local profile = self._profiles[player]
		if profile ~= nil then
			successfullLogout(profile)
			profile:Release()
		end
	end)

	-- In case Players have joined the server earlier than this script ran:
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			self:playerAdded(player)
		end)
	end
end

function DataService:KnitStart()
	local ChatCommandsService = Knit.GetService("ChatCommandsService")

	ChatCommandsService:registerCommand(
		"resetdata",
		function(player)
			self:hardResetData(player)
		end,
		{"datareset", "reset_data", "data_reset"},
		nil,
		"Resets all data for the player, and treats it as if you just logged in for the first time"
	)
end

function DataService:playerAdded(player)
	local profile = profileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
        profile:AddUserId(player.UserId) -- GDPR compliance
        profile:Reconcile() -- Fill in missing variables from ProfileTemplate (optional)
        profile:ListenToRelease(function()
            self._profiles[player] = nil
            player:Kick()
        end)

        if player:IsDescendantOf(Players) == true then
			-- A profile has been successfully loaded:
            self._profiles[player] = profile
            successfullLogin(self, profile, player)
        else
            -- Player left before the profile loaded:
            profile:Release()
        end
    else
        player:Kick()
    end

	self._profiles[player] = profile
end

function DataService:hardResetData(player)
	local profile = self._profiles[player]
	for key, value in pairs(ProfileTemplate) do
		profile.Data[key] = value
	end

	self:removeNonTemplateData(player)
	successfullLogin(self, profile, player)

	print("Player Reset Data", profile.Data)
end

function DataService:removeNonTemplateData(player)
	local profile = self._profiles[player]
	for key in pairs(profile.Data) do
		if ProfileTemplate[key] == nil then
			profile.Data[key] = nil
		end
	end
end

function DataService:getProfile(player)
	if not self._profiles[player] then
		return nil
	end

	return self._profiles[player]
end

return DataService