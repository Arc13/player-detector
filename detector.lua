local sVersion = "v0.9 RC1"
local nBuild = 90
local debugMode = false

-- Variables par défaut

local sLogFormat = "#y#m#d.log"
local sLogDir = "/playerd_logs/"

local useChatInterface = true
local printLog = true
local disableTerminateEvent = false
local disableAutomaticUpdates = false

--[[
	Liste des variables pour les messages du chat :

	#p : Nom du joueur qui entre/sort
	#M : Minute réelle
	#h : Heure réelle
	#d : Jour réel
	#m : Mois réel
	#y : Année réelle
--]]

local joinMessage = "#p joined"
local leftMessage = "#p left"
local chatTo = {"your_name"}
local chatName = "Player Probe "..sVersion.." on "..os.computerID()
local canUseCommands = {"your_name"}

local tWhitelist = {}

local joinProgram = ""
local leftProgram = ""

-- Fin des variables par défaut

-- Déclaration de la fonction au centre du programme

local function getTableDifference(oldTable, newTable)
	if not newTable then
		return false
	end

	local tDifference = {}

	--[[

		print("oldTable :")

		for i = 1, #oldTable do
		print(oldTable[i])
		end

		print("newTable :")

		for i = 1, #newTable do
		print(newTable[i])
		end

		print("Différences :")

	--]]

	for i = 1, #oldTable do
		local isOK = false

		local selectedTable = oldTable[i]
		--print("J'ai "..selectedTable.." actuellement")

		for i = 1, #newTable do
			--print("Je compare "..selectedTable.." avec "..newTable[i])

			if selectedTable == newTable[i] then
				--print("OK")
				isOK = true
				break
			end
		end

		if isOK == false then
			--print(selectedTable.." n'est pas dans table2")
			table.insert(tDifference, selectedTable)
		end
	end

	return tDifference
end

-- Fin de la déclaration

-- Init Environment

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("Player Detector Init Environment")
term.setCursorPos(1, 2)

for i = 1, term.getSize() do
	write("-")
end

term.setCursorPos(1, 4)

if not fs.exists("player_detector.conf") then
	print("\nNo config file found, init setup...")
	local configFile = fs.open("player_detector.conf", "w")
	configFile.write("{\nLogFormat = \"#y#M#d.log\", \nLogDir = \"/playerd_logs/\", \nuseChatInterface = true, \nprintLog = true, \ndisableTerminateEvent = false, \ndisableAutomaticUpdates = false, \njoinMessage = \"#p joined\", \nleftMessage = \"#p left\", \nchatTo = {\"your_name\"}, \nchatName = \"".."Player Probe on "..os.computerID().."\", \ncanUseCommands = {\"your_name\"}, \ntWhitelist = {}, \njoinProgram = \"\", \nleftProgram = \"\", \n}")
	configFile.close()
	print("\nFile created, a text editor will be prompt to edit settings, please save before quit the editor.")
	print("Press any key to continue...")
	os.pullEvent("key")

	shell.run("edit player_detector.conf")

	term.setBackgroundColor(colors.black)
	term.setTextColor(colors.white)
	term.clear()
	term.setCursorPos(1, 1)
	print("Player Detector Init Environment")
	term.setCursorPos(1, 2)

	for i = 1, term.getSize() do
		write("-")
	end

	term.setCursorPos(1, 4)
else
	print("\nConfig file found")
end

print("Loading settings...")
settings.load("player_detector.conf")

sLogFormat = settings.get("LogFormat", sLogFormat)
sLogDir = settings.get("LogDir", sLogDir)
useChatInterface = settings.get("useChatInterface", useChatInterface)
printLog = settings.get("printLog", printLog)
disableTerminateEvent = settings.get("disableTerminateEvent", disableTerminateEvent)
disableAutomaticUpdates = settings.get("disableAutomaticUpdates", disableAutomaticUpdates)
joinMessage = settings.get("joinMessage", joinMessage)
leftMessage = settings.get("leftMessage", leftMessage)
chatTo = settings.get("chatTo", chatTo)
chatName = settings.get("chatName", chatName)
canUseCommands = settings.get("canUseCommands", canUseCommands)
tWhitelist = settings.get("tWhitelist", tWhitelist)
joinProgram = settings.get("joinProgram", joinProgram)
leftProgram = settings.get("leftProgram", leftProgram)

-- Check new version

if not disableAutomaticUpdates and http.get("http://pastebin.com/raw/ZD8t8ZSK") then
	print("\nChecking for updates...")

	local sBuildNet = http.get("http://pastebin.com/raw/ZD8t8ZSK")
	local nBuildNet = tonumber(sBuildNet.readAll())
	sBuildNet.close()

	if nBuildNet > nBuild then
		print("A new version is available ! (build "..nBuildNet..")")
		--print("I'm running "..shell.getRunningProgram())
		print("Downloading new version...")

		local sNewSoftware = http.get("http://pastebin.com/raw/7Jg670Ra")

		local sTempFile = fs.open(".temp", "w")
		sTempFile.write(sNewSoftware.readAll())
		sTempFile.close()

		sNewSoftware.close()

		if fs.exists(".temp") then
			print("Downloaded succesfully, updating...")
			fs.delete(shell.getRunningProgram())
			fs.move(".temp", shell.getRunningProgram())
			fs.delete(".temp")
			write("Rebooting")
			write(".")
			sleep(1)
			write(".")
			sleep(1)
			write(".")
			sleep(1)
			os.reboot()
		else
			print("Download fail...")
		end
	else
		print("You are on the latest version")
	end
elseif disableAutomaticUpdates then
	print("\nAutomatics updates are disabled.")
else
	print("An error has occured, please check your internet connection.")
end

print("")

print("Checking config file...")
local tKeyAllowed = {"{", "LogFormat", "LogDir", "useChatInterface", "printLog", "disableTerminateEvent", "disableAutomaticUpdates", "joinMessage", "leftMessage", "chatTo", "chatName", "canUseCommands", "tWhitelist", "joinProgram", "leftProgram", "}"}
local tPresentKeys = {}
local tErroredKey = {}
local tConfigLines = {}
local sActualLine = ""
local sScanningLine = ""
local sScanningKey = ""
local bScanResult = false

local configCheck = fs.open("player_detector.conf", "r")

while sActualLine ~= nil do
	sActualLine = configCheck.readLine()
	table.insert(tConfigLines, sActualLine)
end

configCheck.close()

for i = 1, #tConfigLines do
	sScanningLine = tConfigLines[i]
	bScanResult = false

	for i = 1, #tKeyAllowed do
		sScanningKey = sScanningLine:sub(1, #tKeyAllowed[i])
		if sScanningKey == tKeyAllowed[i] then
			bScanResult = true
			break
		end
	end

	if bScanResult == false then
		if not sScanningLine:sub(1, 7) == "LogFile" then
			table.insert(tErroredKey, "L"..i.." > \""..sScanningLine.."\"")
		end
	else
		table.insert(tPresentKeys, sScanningKey)
	end
end

if #tErroredKey > 0 then
	if #tErroredKey == 1 then
		printError("Errored key found :")
	else
		printError("Errored keys found :")
	end
	print("")

	textutils.pagedTabulate(tErroredKey)
	print("\nPress any key to continue...")
	os.pullEvent("key")
else
	print("No errored key found !")
end

local tKeyDifference = getTableDifference(tKeyAllowed, tPresentKeys)

if #tKeyDifference > 0 then
	if #tKeyDifference == 1 then
		printError("Missing key found :")
	else
		printError("Missing keys found :")
	end

	print("")
	textutils.pagedTabulate(tKeyDifference)
	print("")

	print("<          >")

	local nCurX, nCurY = term.getCursorPos()
	term.setCursorPos(2, nCurY - 1)

	for i = 1, 10 do
		sleep(1)
		write("=")
	end

	sleep(1)
else
	print("No missing key found !")
end

--sleep(5)

-- End Init Environment

local bRun = true

local monX, monY = term.getSize()
local oldMonX, oldMonY = term.getSize()

local tActualDate = {}

if monX < 29 then
	printError("Resolution is too low !")
	sleep(5)
end

if disableTerminateEvent == true then
	local oldPullEvent = os.pullEvent
	os.pullEvent = os.pullEventRaw
end

--LIP : EntityDetector / OpenCCSensor : sensor
--LIP : WorldInterface / Peripherals++ : timeSensor
--LIP : ChatInterface / Peripherals++ : chatBox

local tSensorPeripheral = peripheral.find("sensor")
local tTimePeripheral = peripheral.find("timeSensor")
local tChatPeripheral = peripheral.find("chatBox")

local tSensorSide = ""
local tTimeSide = ""
local tChatSide = ""

local bScrollEffectDone = false

local chatInterfaceConnected = true

if not tSensorPeripheral then
	error("No sensor found !")
end

if tSensorPeripheral.getSensorName() ~= "proximityCard" then
	error("No proximityCard inserted !")
end

if not tTimePeripheral then
	error("No timeSensor found !")
end

if not tChatPeripheral then
	chatInterfaceConnected = false
end

for i = 1, #peripheral.getNames() do
	local sPeripheralType = peripheral.getType(peripheral.getNames()[i])

	if sPeripheralType == "sensor" then
		tSensorSide = peripheral.getNames()[i]
	elseif sPeripheralType == "timeSensor" then
		tTimeSide = peripheral.getNames()[i]
	elseif sPeripheralType == "chatBox" then
		tChatSide = peripheral.getNames()[i]
	end
end

local tPlayers = {}
local tOldPlayers = {}

local tInventoryPlayers = {}
local tActualInventoryPlayers = {}

if not fs.exists(sLogDir) then
	fs.makeDir(sLogDir)
end

term.clear()
term.setCursorPos(1, 1)

if monX >= 51 then
	print("Player detector "..sVersion)
	term.setCursorPos(monX - string.len(string.char(174).." arc13") + 1, 1)
	term.write(string.char(174).." arc13")

	if term.isColor() then
		term.setTextColor(colors.lightGray)
	end

	term.setCursorPos(1, 3)
	if useChatInterface and chatInterfaceConnected then
		print("ChatBox enabled")
	else
		print("ChatBox disabled")
	end

	term.setCursorPos(1, 4)
elseif monX < 51 and monX >= 29 then
	print("Player detector "..sVersion)
	term.setCursorPos(monX - string.len(string.char(174).." arc13") + 1, 1)
	term.write(string.char(174).." arc13")
	term.setCursorPos(1, 3)
	if useChatInterface and chatInterfaceConnected then
		print("ChatBox enabled")
	else
		print("ChatBox disabled")
	end

	term.setCursorPos(1, 4)
end

if term.isColor() then
	term.setTextColor(colors.gray)
end

for i = 1, term.getSize() do
	write("-")
end

term.setTextColor(colors.white)

print("\n")

if not printLog then
	print("Log here is disabled !")
end

local function redrawHeader()
	local oldCurX, oldCurY = term.getCursorPos()

	term.setCursorPos(1, 1)
	term.clearLine()
	print("Player detector "..sVersion)
	term.setCursorPos(monX - string.len(string.char(174).." arc13") + 1, 1)
	term.write(string.char(174).." arc13")

	if term.isColor() then
		term.setTextColor(colors.gray)
	end

	if bScrollEffectDone == true then
		term.setCursorPos(1, 2)
	else
		if monX >= 51 then
			term.setCursorPos(1, 4)
		elseif monX < 51 and monX >= 29 then
			term.setCursorPos(1, 4)
		end
	end

	for i = 1, term.getSize() do
		write("-")
	end

	term.setTextColor(colors.white)

	if monX < 29 then
		term.clear()
		term.setCursorPos(1, 1)
		print("Resolution too low !")
	end

	term.setCursorPos(oldCurX, oldCurY)
end

local function scrollEffect()
	sleep(5)

	local oldCurX, oldCurY = term.getCursorPos()

	for i = 1, 1 do
		term.scroll(1)

		term.setCursorPos(1, 1)
		print("Player detector "..sVersion)
		term.setCursorPos(monX - string.len(string.char(174).." arc13") + 1, 1)
		term.write(string.char(174).." arc13")
		paintutils.drawLine(1, 2, monX, 2, colors.black)

		if monX < 51 and monX >= 29 and i == 2 then
			term.setCursorPos(1, 2)

			if term.isColor() then
				term.setTextColor(colors.gray)
			end

			for i = 1, term.getSize() do
				write("-")
			end

			term.setTextColor(colors.white)
		end

		sleep(0.2)
	end
	term.scroll(1)

	term.setCursorPos(1, 1)
	print("Player detector "..sVersion)
	term.setCursorPos(monX - string.len(string.char(174).." arc13") + 1, 1)
	term.write(string.char(174).." arc13")

	if monX < 51 and monX >= 29 then
		term.setCursorPos(1, 2)

		if term.isColor() then
			term.setTextColor(colors.gray)
		end

		for i = 1, term.getSize() do
			write("-")
		end

		term.setTextColor(colors.white)
	end

	bScrollEffectDone = true

	redrawHeader()

	if monX >= 51 then
		term.setCursorPos(oldCurX, oldCurY - 3)
	elseif monX < 51 and monX >= 29 then
		term.setCursorPos(oldCurX, oldCurY - 2)
	end
end

local function isInWhitelist(sPlayerName)
	for i = 1, #tWhitelist do
		if sPlayerName == tWhitelist[i] then
			--tChatPeripheral.tell("arc13", "whitelisted")
			return true
		end
	end

	--tChatPeripheral.tell("arc13", "not whitelisted")
	return false
end

local function getInventorySize(tInventory)
	local i = 0

	for k, v in pairs(tInventory) do
		i = i + 1
	end

	return i
end

local function getPlayers()
	local playerList = {}
	local f = tSensorPeripheral.getTargets()

	for k, v in pairs(f) do
		if v.IsPlayer then
			table.insert(playerList, k)
		end
	end

	for i = 1, #playerList do
		--print(playerList[i])
	end

	return playerList
end

function logJoin(sPlayerJoined)
	if printLog then
		if term.isColor() then
			term.setTextColor(colors.lightGray)
		end

		local sFormattedPlayer = ""

		if #tPlayers > 1 then
			sFormattedPlayer = "players"
		else
			sFormattedPlayer = "player"
		end

		tActualDate = tTimePeripheral.getDate()
		write("["..string.format("%02i", tActualDate.hour)..":"..string.format("%02i", tActualDate.minute)..", "..#tPlayers.." "..sFormattedPlayer.."] ")
		term.setTextColor(colors.white)
		print(sPlayerJoined.." join")
	end

	local sLogName = sLogFormat
	sLogName = sLogName:gsub("#m", string.format("%02i", tActualDate.minute))
	sLogName = sLogName:gsub("#h", string.format("%02i", tActualDate.hour))
	sLogName = sLogName:gsub("#d", string.format("%02i", tActualDate.day))
	sLogName = sLogName:gsub("#M", string.format("%02i", tActualDate.month))
	sLogName = sLogName:gsub("#y", string.format("%02i", tActualDate.year))

	local file = fs.open(sLogDir..sLogName, fs.exists(sLogDir..sLogName) and "a" or "w")

	file.writeLine("["..string.format("%02i", tActualDate.hour)..":"..string.format("%02i", tActualDate.minute).."] "..sPlayerJoined.." join")
	file.close()

	if useChatInterface == true and chatInterfaceConnected == true then
		for i = 1, #chatTo do
			local sMsg = string.gsub(joinMessage, "#p", sPlayerJoined)
			sMsg = sMsg:gsub("#M", string.format("%02i", tActualDate.minute))
			sMsg = sMsg:gsub("#h", string.format("%02i", tActualDate.hour))
			sMsg = sMsg:gsub("#d", string.format("%02i", tActualDate.day))
			sMsg = sMsg:gsub("#m", string.format("%02i", tActualDate.month))
			sMsg = sMsg:gsub("#y", string.format("%02i", tActualDate.year))

			if chatName == "" then
				tChatPeripheral.tell(chatTo[i], sMsg)
			else
				tChatPeripheral.tell(chatTo[i], "["..chatName.."] "..sMsg)
			end
		end
	end
end

local function logLeft(sPlayerLeft)
	if printLog then
		if term.isColor() then
			term.setTextColor(colors.lightGray)
		end

		local sFormattedPlayer = ""

		if #tPlayers > 1 then
			sFormattedPlayer = "players"
		else
			sFormattedPlayer = "player"
		end

		tActualDate = tTimePeripheral.getDate()
		write("["..string.format("%02i", tActualDate.hour)..":"..string.format("%02i", tActualDate.minute)..", "..#tPlayers.." "..sFormattedPlayer.."] ")
		term.setTextColor(colors.white)
		print(sPlayerLeft.." left")
	end

	local sLogName = sLogFormat
	sLogName = sLogName:gsub("#m", string.format("%02i", tActualDate.minute))
	sLogName = sLogName:gsub("#h", string.format("%02i", tActualDate.hour))
	sLogName = sLogName:gsub("#d", string.format("%02i", tActualDate.day))
	sLogName = sLogName:gsub("#M", string.format("%02i", tActualDate.month))
	sLogName = sLogName:gsub("#y", string.format("%02i", tActualDate.year))

	local file = fs.open(sLogDir..sLogName, fs.exists(sLogDir..sLogName) and "a" or "w")

	file.writeLine("["..string.format("%02i", tActualDate.hour)..":"..string.format("%02i", tActualDate.minute).."] "..sPlayerLeft.." left")

	file.close()

	if useChatInterface == true and chatInterfaceConnected == true then
		for i = 1, #chatTo do
			local sMsg = string.gsub(leftMessage, "#p", sPlayerLeft)
			sMsg = sMsg:gsub("#M", string.format("%02i", tActualDate.minute))
			sMsg = sMsg:gsub("#h", string.format("%02i", tActualDate.hour))
			sMsg = sMsg:gsub("#d", string.format("%02i", tActualDate.day))
			sMsg = sMsg:gsub("#m", string.format("%02i", tActualDate.month))
			sMsg = sMsg:gsub("#y", string.format("%02i", tActualDate.year))

			if chatName == "" then
				tChatPeripheral.tell(chatTo[i], sMsg)
			else
				tChatPeripheral.tell(chatTo[i], "["..chatName.."] "..sMsg)
			end
		end
	end
end

local function playerJoin(tPlayers, tOldPlayers)
	local tDifference = getTableDifference(tPlayers, tOldPlayers)

	if joinProgram ~= "" and multishell then
		local sTempPlayers = ""

		for i = 1, #tDifference do
			sTempPlayers = sTempPlayers..tDifference[i]..","
		end

		shell.openTab(joinProgram.." "..sTempPlayers)
	end

	os.queueEvent("player_join", tDifference)

	for i = 1, #tDifference do
		if not isInWhitelist(tDifference[i]) then
			logJoin(tDifference[i])

			redrawHeader()
		else
			if printLog then
				print("Whitelisted : "..tDifference[i])
			end
		end
	end
end

local function playerLeft(tPlayers, tOldPlayers)
	local tDifference = getTableDifference(tOldPlayers, tPlayers)

	if debugMode then
		print("Differences:")
		for i = 1, #tDifference do
			print(tDifference[i])
		end
	end

	if leftProgram ~= "" and multishell then
		local sTempPlayers = ""

		for i = 1, #tDifference do
			sTempPlayers = sTempPlayers..tDifference[i]..","
		end

		shell.openTab(leftProgram.." "..sTempPlayers)
	end

	os.queueEvent("player_left", tDifference)

	for i = 1, #tDifference do
		if not isInWhitelist(tDifference[i]) then
			logLeft(tDifference[i])

			redrawHeader()
		else
			if printLog then
				print("Whitelisted : "..tDifference[i])
			end
		end
	end
end

local function main()
	while bRun do
		tOldPlayers = tPlayers
		tPlayers = getPlayers()

		if debugMode then
			print("tOldPlayers:")
			for i = 1, #tOldPlayers do
				print(tOldPlayers[i])
			end

			print("tPlayers:")
			for i = 1, #tPlayers do
				print(tPlayers[i])
			end

			--sleep(5)
		end

		if #tPlayers ~= #tOldPlayers then
			if debugMode then
				print("New player")
			end
			if #tPlayers > #tOldPlayers then
				if debugMode then
					print("Player joined")
				end

				threadJoin = coroutine.create(playerJoin)
				coroutine.resume(threadJoin, tPlayers, tOldPlayers)
			elseif #tPlayers < #tOldPlayers then
				if debugMode then
					print("Player left")
				end

				threadLeft = coroutine.create(playerLeft)
				coroutine.resume(threadLeft, tPlayers, tOldPlayers)
			end
		else
			if debugMode then
				--print("No new player")
			end
		end

		sleep(0.1)
	end
end

-- Les events de peripherals sont incompréhensibles
local function peripheralHandler()
	while bRun do
		redrawHeader()

		local sEvent, sSide = os.pullEvent()

		if sEvent == "peripheral" or sEvent == "peripheral_detach" then
			print(sSide)
			print(tTimeSide)
			print(tSensorSide)
			print(tChatSide)
		end

		if sEvent == "peripheral" then
			if peripheral.getType(sSide) == "chatBox" then
				chatInterfaceConnected = true
				print("[SYSTEM] Chat Box connected")
				tChatSide = sSide
			end
		elseif sEvent == "peripheral_detach" then
			if sSide == tTimeSide then
				-- Le timeSensor à été détaché
				error("[SYSTEM] Time Sensor disconnected")
			elseif sSide == tSensorSide then
				-- Le sensor à été détaché
				error("[SYSTEM] Proximity Sensor disconnected")
			elseif sSide == tChatSide then
				-- La Chat Box à été détaché
				chatInterfaceConnected = false
				tChatSide = ""
				print("[SYSTEM] Chat Box disconnected")
			end
		end
	end
end

local function chatHandler()
	while bRun do
		local sEvent, sPlayer, sMessage = os.pullEvent("chat")

		for i = 1, #canUseCommands do
			if sPlayer == canUseCommands[i] then
				if sMessage == "##disable_chat" then
					useChatInterface = false
					tChatPeripheral.tell(sPlayer, "Chat disabled !")
				elseif sMessage == "##enable_chat" then
					useChatInterface = true
					tChatPeripheral.tell(sPlayer, "Chat enabled !")
				elseif sMessage == "##stop" then
					tChatPeripheral.tell(sPlayer, "Terminated")
					os.pullEvent = oldPullEvent
					bRun = false
				elseif sMessage == "##get_players" then
					local tPlayersToSend = getPlayers()

					local sMsgToSend = ""

					if #tPlayersToSend == 0 then
						tChatPeripheral.tell(sPlayer, "No players detected")
					elseif #tPlayersToSend == 1 then
						tChatPeripheral.tell(sPlayer, "Player : "..tPlayersToSend[1])
					else
						for i = 1, #tPlayersToSend - 1 do
							sMsgToSend = sMsgToSend..tPlayersToSend[i]..", "
						end

						sMsgToSend = sMsgToSend..tPlayersToSend[#tPlayersToSend]

						tChatPeripheral.tell(sPlayer, sMsgToSend)
					end
				end
			end
		end
	end
end

local function UIRefresh()
	while bRun do
		sleep(2)

		redrawHeader()
	end
end

local function resizeHandler()
	while bRun do
		event, side = os.pullEvent("monitor_resize")

		oldMonX, oldMonY = monX, monY

		monX, monY = term.getSize()

		if monX ~= oldMonX or monY ~= oldMonY then
			-- Resolution has changed, the program run on a monitor

			if monX >= 29 then
				redrawHeader()

				if bScrollEffectDone == true then
					term.setCursorPos(1, 3)
				else
					if monX >= 51 then
						term.setCursorPos(1, 6)
					elseif monX < 51 and monX >= 29 then
						term.setCursorPos(1, 5)
					end
				end
			else
				term.setCursorPos(1, 1)
				print("Resolution too low !")
			end
		end
	end
end

local function getPlayerInventory(sPlayer)
	return tSensorPeripheral.getTargetDetails(sPlayer).Inventory
end

local function inventoryUpdate()
	while bRun do
		local tPlayersInRange = getPlayers()

		for i = 1, #tPlayersInRange do
			local bSuccess, tTargetDetails = pcall(getPlayerInventory, tPlayersInRange[i])

			if bSuccess then
				if not tActualInventoryPlayers[tPlayersInRange[i]] then
					tActualInventoryPlayers[tPlayersInRange[i]] = {inventory = {}}
				end

				local tActualInventory = {}

				tActualInventoryPlayers[tPlayersInRange[i]]["inventorySize"] = getInventorySize(tTargetDetails)

				for k, v in pairs(tTargetDetails) do
					table.insert(tActualInventory, v.Name)
				end

				tActualInventoryPlayers[tPlayersInRange[i]]["inventory"] = tActualInventory
			else
				--print("error")
			end
		end

		sleep(0.1)
	end
end

local function inventoryHandler()
	while bRun do
		local invHandlerEvent, invHandlerPlayer = os.pullEvent()

		if invHandlerEvent == "player_join" then
			for i = 1, #invHandlerPlayer do
				local bSuccess, tTargetDetails = pcall(getPlayerInventory, invHandlerPlayer[i])

				if bSuccess then
					if not tInventoryPlayers[invHandlerPlayer[i]] then
						tInventoryPlayers[invHandlerPlayer[i]] = {inventory = {}}
					end

					local tActualInventory = {}

					tInventoryPlayers[invHandlerPlayer[i]]["inventorySize"] = getInventorySize(tTargetDetails)

					for k, v in pairs(tTargetDetails) do
						table.insert(tActualInventory, v.Name)
					end

					tInventoryPlayers[invHandlerPlayer[i]]["inventory"] = tActualInventory
				else
					--print("error")
				end
			end
		elseif invHandlerEvent == "player_left" then
	    for i = 1, #invHandlerPlayer do
				if not isInWhitelist(invHandlerPlayer[i]) then
					local sLogName = sLogFormat
					sLogName = sLogName:gsub("#m", string.format("%02i", tActualDate.minute))
					sLogName = sLogName:gsub("#h", string.format("%02i", tActualDate.hour))
					sLogName = sLogName:gsub("#d", string.format("%02i", tActualDate.day))
					sLogName = sLogName:gsub("#M", string.format("%02i", tActualDate.month))
					sLogName = sLogName:gsub("#y", string.format("%02i", tActualDate.year))

					local file = fs.open(sLogDir..sLogName, fs.exists(sLogDir..sLogName) and "a" or "w")

					local tCurrentInventory = {}

					for k, v in pairs(tActualInventoryPlayers[invHandlerPlayer[i]]["inventory"]) do
						table.insert(tCurrentInventory, v.displayName)
					end

					local tInvDifferencePlus = getTableDifference(tActualInventoryPlayers[invHandlerPlayer[i]]["inventory"], tInventoryPlayers[invHandlerPlayer[i]]["inventory"])
					local tInvDifferenceMinus = getTableDifference(tInventoryPlayers[invHandlerPlayer[i]]["inventory"], tActualInventoryPlayers[invHandlerPlayer[i]]["inventory"])

					if #tInvDifferencePlus > 0 or #tInvDifferenceMinus > 0 then
						print("Inventory has changed ! ("..tActualInventoryPlayers[invHandlerPlayer[i]]["inventorySize"].." items now, "..tInventoryPlayers[invHandlerPlayer[i]]["inventorySize"].." before)")
					end

					if #tInvDifferencePlus > 0 then
						-- Un/plusieurs item(s) à/ont été(s) ajouté(s)

						os.queueEvent("inventory_add", invHandlerPlayer[i], tInvDifferencePlus)

						file.writeLine("Inventory has changed (+) : ")

						file.write("/")

						for i = 1, #tInvDifferencePlus do
							file.write(tInvDifferencePlus[i].."/")
							if debugMode then
								print(tInvDifferencePlus[i])
							end
						end

						file.write("\n")
					end

					if #tInvDifferenceMinus > 0 then
						-- Un/plusieurs item(s) à/ont été(s) enlevée(s)

						os.queueEvent("inventory_remove", invHandlerPlayer[i], tInvDifferenceMinus)

						file.writeLine("Inventory has changed (-) : ")

						file.write("/")

						for i = 1, #tInvDifferenceMinus do
							file.write(tInvDifferenceMinus[i].."/")
							if debugMode then
								print(tInvDifferenceMinus[i])
							end
						end

						file.write("\n")
					end

					file.close()
				end
			end
		end
	end
end

parallel.waitForAll(main, chatHandler, scrollEffect, UIRefresh, resizeHandler, inventoryUpdate, inventoryHandler)
