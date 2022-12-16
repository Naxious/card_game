local ProfileTemplate = {
	-- Settings Table
	Settings = {

	},

	-- Basic Data
	Stars = 0,
	Rebirths = 0,
	LaunchHeight = 0,
	FuelCollected = 0,

	-- System Data
	Pets = {},
	Trails = {},
	GamePasses = {},

	-- Achievement Data
	robuxSpent = 0,
	capsulesOpened = {
		star1 = 0,
		star2 = 0,
		star3 = 0,
		star4 = 0,
		star5 = 0
	},

	-- Login Data
	lastLogin = 0,
	currentLogin = 0,
	dailyLogins = 0,
	totalTimePlayed = 0,
	sessionTimes = {},
	averageSessionTime = 0,
}

table.freeze(ProfileTemplate)
return ProfileTemplate