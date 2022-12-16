local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local GroupService = game:GetService("GroupService")

local Knit = require(ReplicatedStorage.Packages.Knit)

local ChatService

local COMMAND_PREFIX = "/"
local DEFAULT_CHAT_CHANNEL = "All"

local GROUP_ID = 12731007 -- Set this to the group ID of your group
local MINIMUM_COMMAND_RANK = 100 -- Set this to the minimum rank required to use commands

local GROUP_NAME = GroupService:GetGroupInfoAsync(GROUP_ID).Name

local ChatCommandsService = Knit.CreateService {
	Name = "ChatCommandsService",

	registeredCommandAliases = { },
	registeredCommands = { },

	aliasLink = { },

	arguments = {
		["player"] = {
			name = "Player",
			computer = function(argument)
				for _, player in Players:GetPlayers() do
					if string.sub(string.lower(player.Name), 1, #argument) == string.lower(argument) then
						return true, player
					end
				end

				return false
			end
		},
		["string"] = {
			name = "Player",
			computer = function(argument)
				return true, argument
			end
		},
		["number"] = {
			name = "number",
			computer = function(argument)
				local value = tonumber(argument)

				return value ~= nil, value
			end
		},
		["boolean"] = {
			name = "boolean",
			computer = function(argument)
				local value = (argument == "true" and true) or (argument == "false" and false) or nil

				return value ~= nil, value
			end
		}
	}
}
local playerConnections: {[Player]: RBXScriptConnection} = {}

local function onPlayerAdded(player: Player)
	playerConnections[player] = player.Chatted:Connect(function(message)
		local rank = player:GetRankInGroup(GROUP_ID)
		if not rank or rank < MINIMUM_COMMAND_RANK then
			return
		end

		local isCommand, commandName, commandVariables = ChatCommandsService:parseMessage(message)

		if isCommand then
			ChatCommandsService:executeCommand(ChatCommandsService.registeredCommandAliases[commandName] or commandName, player, commandVariables)
		end
	end)
end

local function onPlayerRemoved(player: Player)
	if not playerConnections[player] then
		return
	end

	playerConnections[player]:Disconnect()
end

function ChatCommandsService:setCommandAliases(commandName, ...)
	local commandTable = self.registeredCommands[commandName]

	if commandTable then
		for _, aliasName in { ... } do
			self.registeredCommandAliases[aliasName] = commandName
		end
	end
end

function ChatCommandsService:setCommandDescription(commandName, description)
	local commandTable = self.registeredCommands[commandName]

	if commandTable then
		commandTable.description = description
	end
end

function ChatCommandsService:setCommandArguments(commandName, arguments)
	local commandTable = self.registeredCommands[commandName]

	if commandTable then
		commandTable.arguments = arguments
	end
end

function ChatCommandsService:registerCommand(commandName, commandFunction, commandAliases, commandArguments, description)
	commandName = string.lower(commandName)

	if self.registeredCommands[commandName] then
		error("Command " .. commandName .. " already registered")
	end

	self.registeredCommands[commandName] = {
		compute = commandFunction,
		description = description or "no description has been set",
		arguments = commandArguments or { }
	}

	if commandAliases then
		self.aliasLink[commandName] = commandAliases

		for _, aliasName in commandAliases do
			self.registeredCommandAliases[aliasName] = commandName
		end
	end
end

function ChatCommandsService:executeCommand(commandName, player, commandVariables)
	if not self.registeredCommands[commandName] then
		return warn("Command " .. commandName .. " doesn't exist")
	end

	local commandObject = self.registeredCommands[commandName]

	if #commandObject.arguments > 0 then
		for key, matchedArgumentParser in commandObject.arguments do
			local isPotentialArgument = string.sub(key, 1, 1) == "*"
			local value = (isPotentialArgument and commandVariables[string.sub(key, 2, #key)]) or commandVariables[key]

			if not isPotentialArgument and not value then
				return warn("Command Argument Parser" .. key .. " parameter doesn't exist")
			end

			local parseSuccess, parseResult = matchedArgumentParser.computer(value)

			if not parseSuccess then
				return warn("Command Argument Parser" .. key .. " failed to parse " .. tostring(value))
			end

			commandVariables[key] = parseResult
		end
	end

	return commandObject.compute(player, table.unpack(commandVariables))
end

function ChatCommandsService:parseMessage(message)
	local commandPrefix = string.sub(message, 1, 1)
	local commandSplit = string.split(message, " ")

	commandSplit[1] = (commandSplit[1] and string.sub(commandSplit[1], 2, #commandSplit[1]))
	commandSplit[1] = (commandSplit[1] and string.lower(commandSplit[1]))

	if commandPrefix ~= COMMAND_PREFIX then
		return false
	end

	return true, table.remove(commandSplit, 1), commandSplit
end

function ChatCommandsService:KnitStart()
	self:registerCommand("help", function(player)
		local chatServiceRunner = ServerScriptService:WaitForChild("ChatServiceRunner")
		ChatService = ChatService or (chatServiceRunner and require(chatServiceRunner:FindFirstChild("ChatService")))

		assert(ChatService ~= nil, "Expected ChatService - Not ChatService Available")

		local chatChannel = ChatService:GetChannel(DEFAULT_CHAT_CHANNEL)

		assert(chatChannel ~= nil, "Expected ChatService Channel - No default channel found")

		local chatMessage = "These are the " ..  GROUP_NAME .. " development chat commands."

		for commandName, commandSettings in self.registeredCommands do
			local commandParameterStringified = ""

			if #commandSettings.arguments > 0 then
				for _, commandParser in commandSettings.arguments do
					commandParameterStringified ..= "<" .. commandParser.name .. "> "
				end
			else
				commandParameterStringified = ""
			end

			print(commandName, commandSettings)
			chatMessage ..= string.format("\n/%s %s: %s", commandName, commandParameterStringified, commandSettings.description)
			chatMessage ..= "::Aliases(" .. table.concat(self.aliasLink[commandName] or { }, ", ") .. ")"
		end

		chatChannel:SendSystemMessageToSpeaker(chatMessage, player.Name, {
			ChatColor = Color3.fromRGB(255, 82, 0)
		})
	end, { "cmds", "cmd", "commands" })

	self:setCommandDescription("help", "Shows all the commands")
end

function ChatCommandsService:KnitInit()
	Players.PlayerAdded:Connect(onPlayerAdded)
	Players.PlayerRemoving:Connect(onPlayerRemoved)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end
end

return ChatCommandsService