local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local AudioData = require(ReplicatedStorage.Data.AudioData)

local DEFAULT_SOUND_VOLUME = 1
local DEFAULT_PLAYBACK_SPEED = 1

local function preloadSounds(self: any)
	for _, soundCategory in pairs(AudioData) do
		for _, soundId in pairs(soundCategory) do
			local sound = Instance.new("Sound")
			sound.Name = soundId
			sound.SoundId = soundId
			sound.Volume = 0
			sound.Parent = self._soundsFolder
		end
	end

	for _, soundObject in pairs(self._soundsFolder:GetChildren()) do
		table.insert(self.soundNames, soundObject.Name)
		self.soundData[soundObject.Name] = soundObject
	end

	ContentProvider:PreloadAsync(self._soundsFolder:GetChildren())
	while ContentProvider.RequestQueueSize > 0 do
		task.wait()
	end
end

local function createSound(self: any, soundName: string, playbackSpeed: number?)
	if not self.soundData[soundName] then
		error("Sound name " .. soundName .. " not found")
	end

	local sound = Instance.new("Sound")
	sound.Name = soundName
	sound.SoundId = self.soundData[soundName].SoundId
	sound.PlaybackSpeed = playbackSpeed or DEFAULT_PLAYBACK_SPEED
	sound.Volume = DEFAULT_SOUND_VOLUME
	return sound
end

local function destroySoundWhenItEnds(sound: Sound)
	if not sound then
		return
	end

	local soundEndedConnection
	soundEndedConnection = sound.Ended:Connect(function()
		sound:Destroy()
	end)

	task.delay(sound.TimeLength * 10, function()
		sound:Destroy()
		soundEndedConnection:Disconnect()
		soundEndedConnection = nil
	end)
end

local AudioController = Knit.CreateController {
	Name = "AudioController",
	_soundsFolder = nil,
	soundNames = {},
	soundData = {},
}

function AudioController:KnitStart()
	self._soundsFolder = Instance.new("Folder")
	self._soundsFolder.Name = "Sounds"
	self._soundsFolder.Parent = workspace

	preloadSounds(self)
end

function AudioController:playSound(soundName: string, object: BasePart)
	local sound: Sound
	if object then
		if object:FindFirstChild(soundName) then
			sound = object:FindFirstChild(soundName)
		else
			sound = createSound(self, soundName)
			sound.Parent = object
		end

		sound:Play()
		destroySoundWhenItEnds(sound)
		return
	end

	if SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
		sound:Play()
		destroySoundWhenItEnds(sound)
		return
	end

	sound = createSound(self, soundName)
	sound.Parent = SoundService
	sound:Play()
	destroySoundWhenItEnds(sound)
end

function AudioController:playSoundWithPlaybackSpeed(soundName: string, playbackSpeed: number, object: BasePart)
	local sound: Sound
	if object then
		if object:FindFirstChild(soundName) then
			sound = object:FindFirstChild(soundName)
		else
			sound = createSound(self, soundName)
			sound.Parent = object
		end

		sound.PlaybackSpeed = playbackSpeed or DEFAULT_PLAYBACK_SPEED
		sound:Play()
		destroySoundWhenItEnds(sound)
		return
	end

	if SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
		sound.PlaybackSpeed = playbackSpeed or DEFAULT_PLAYBACK_SPEED
		sound:Play()
		destroySoundWhenItEnds(sound)
		return
	end

	sound = createSound(self, soundName, playbackSpeed)
	sound.Parent = SoundService
	sound:Play()
	destroySoundWhenItEnds(sound)
end

function AudioController:playSoundWithFadeIn(soundName: string, duration: number, object: BasePart)
	local sound: Sound
	if object then
		if object:FindFirstChild(soundName) then
			sound = object:FindFirstChild(soundName)
		else
			sound = createSound(self, soundName)
			sound.Parent = object
		end

		sound:Play()
		sound.Volume = 0
		local tween = TweenService:Create(sound, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Volume = DEFAULT_SOUND_VOLUME})
		tween:Play()
		destroySoundWhenItEnds(sound)
		return
	end

	if SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
		sound:Play()
		sound.Volume = 0
		local tween = TweenService:Create(sound, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Volume = DEFAULT_SOUND_VOLUME})
		tween:Play()
		destroySoundWhenItEnds(sound)
		return
	end

	sound = createSound(self, soundName)
	sound.Parent = SoundService
	sound:Play()
	sound.Volume = 0
	local tween = TweenService:Create(sound, TweenInfo.new(duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out), {Volume = DEFAULT_SOUND_VOLUME})
	tween:Play()
	destroySoundWhenItEnds(sound)
end

function AudioController:stopSound(soundName: string, object: BasePart)
	local sound: Sound
	if object and object:FindFirstChild(soundName) then
		sound = object:FindFirstChild(soundName)
	elseif SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
	end

	if not sound then
		error("Sound name " .. soundName .. " not found")
	end

	sound:Stop()
	sound:Destroy()
end

function AudioController:stopSoundWithFadeOut(soundName: string, duration: number, object: BasePart)
	local sound
	if object and object:FindFirstChild(soundName) then
		sound = object:FindFirstChild(soundName)
	elseif SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
	end

	if not sound then
		error("Sound name " .. soundName .. " not found")
	end

	local tween = TweenService:Create(sound, TweenInfo.new(duration), {Volume = 0})
	tween:Play()
	tween.Completed:Connect(function()
		sound:Destroy()
	end)
end

function AudioController:pauseSound(soundName: string, object: BasePart)
	local sound: Sound
	if object and object:FindFirstChild(soundName) then
		sound = object:FindFirstChild(soundName)	
	elseif SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
	end

	if not sound then
		error("Sound name " .. soundName .. " not found")
	end

	sound:Pause()
end

function AudioController:setSoundVolumeInstant(soundName: string, volume: number, object: BasePart)
	local sound: Sound
	if object and object:FindFirstChild(soundName) then
		sound = object:FindFirstChild(soundName)
	elseif SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
	end

	if not sound then
		error("Sound name " .. soundName .. " not found")
	end

	sound.Volume = volume
end

function AudioController:setSoundVolumeTween(soundName: string, volume: number, duration: number, object: BasePart)
	local sound
	if object and object:FindFirstChild(soundName) then
		sound = object:FindFirstChild(soundName)
	elseif SoundService:FindFirstChild(soundName) then
		sound = SoundService:FindFirstChild(soundName)
	end

	if not sound then
		error("Sound name " .. soundName .. " not found")
	end

	local tween = TweenService:Create(sound, TweenInfo.new(duration), {Volume = volume})
	tween:Play()
end

return AudioController