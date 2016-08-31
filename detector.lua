local sVersion = "v0.7.3-master"
local nBuild = 73

-- Variables par défaut

local sLogFile = "probe.log"
local nRange = 16
local nX = -211
local nY = 74
local nZ = 424

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

-- Init Environment

term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
term.clear()
term.setCursorPos(1, 1)
print("Player Detector Init Environment")
term.setCursorPos(2, 2)

for i = 2, term.getSize() - 1 do
  write("=")
end

term.setCursorPos(1, 4)

if not fs.exists("player_detector.conf") then
  print("\nNo config file found, init setup...")
  local configFile = fs.open("player_detector.conf", "w")
  configFile.write("{\nLogFile = \"probe.log\", \nnRange = 16, \nnX = -211, \nnY = 74, \nnZ = 424, \nuseChatInterface = true, \nprintLog = true, \ndisableTerminateEvent = false, \ndisableAutomaticUpdates = false, \njoinMessage = \"#p joined\", \nleftMessage = \"#p left\", \nchatTo = {\"your_name\"}, \nchatName = \"".."Player Probe on "..os.computerID().."\", \ncanUseCommands = {\"your_name\"}, \ntWhitelist = {}, \njoinProgram = \"\", \nleftProgram = \"\", \n}")
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
  term.setCursorPos(2, 2)

  for i = 2, term.getSize() - 1 do
    write("=")
  end

  term.setCursorPos(1, 4)
else
  print("\nConfig file found")
end

print("Loading settings...")
settings.load("player_detector.conf")

sLogFile = settings.get("LogFile", sLogFile)
nRange = settings.get("nRange", nRange)
nX = settings.get("nX", nX)
nY = settings.get("nY", nY)
nZ = settings.get("nZ", nZ)
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

if not disableAutomaticUpdates then
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
else
  print("\nAutomatics updates are disabled.")
end

print("\n")

if nRange > 20 then
  printError("[WARN] Range is out of bound ("..nRange..")")
  nRange = 20

  for i = 1, 5 do
    write(".")
    sleep(1)
  end
elseif nRange < 1 then
  printError("[WARN] Range is out of bound ("..nRange..")")
  nRange = 1

  for i = 1, 5 do
    write(".")
    sleep(1)
  end
end

-- End Init Environment

local bRun = true

local monX, monY = term.getSize()

if disableTerminateEvent == true then
  local oldPullEvent = os.pullEvent
  os.pullEvent = os.pullEventRaw
end

if not fs.exists("date") then
  shell.run("pastebin get 8GiE70cH date")
end

os.loadAPI("date")

local t = peripheral.find("EntityDetector")
local p = peripheral.find("WorldInterface")
local c = peripheral.find("ChatInterface")

local tSide = ""
local pSide = ""
local cSide = ""

local chatInterfaceConnected = true

if not t then
  error("No EntityDetector found !")
end

if not p then
  error("No WorldInterface found !")
end

if not c then
  chatInterfaceConnected = false
else
  c.setName(chatName)
end

for i = 1, #peripheral.getNames() do
  local sPeripheralType = peripheral.getType(peripheral.getNames()[i])

  if sPeripheralType == "EntityDetector" then
    tSide = peripheral.getNames()[i]
  elseif sPeripheralType == "WorldInterface" then
    pSide = peripheral.getNames()[i]
  elseif sPeripheralType == "ChatInterface" then
    cSide = peripheral.getNames()[i]
  end
end

local tPlayers = {}
local tOldPlayers = {}
local tInventoryPlayers = {}

if not fs.exists(sLogFile) then
  local file = fs.open(sLogFile, "w")
  file.close()
end

term.clear()
term.setCursorPos(1, 1)

print("Player detector "..sVersion)
term.setCursorPos(monX - string.len(string.char(169).." arc13") + 1, 1)
term.write(string.char(169).." arc13")
term.setCursorPos(1, 3)
print("Listening at "..nX..", "..nY..", "..nZ.." (radius "..nRange..")")
print(p.getBlockInfos(nX, nY, nZ)["blockName"]..", "..p.getBiome(nX, nY, nZ).." biome")

term.setCursorPos(2, 5)

for i = 2, term.getSize() - 1 do
  write("=")
end

print("\n")

if not printLog then
  print("Log here is disabled !")
end

local function isInWhitelist(sPlayerName)
  for i = 1, #tWhitelist do
    if sPlayerName == tWhitelist[i] then
      --c.sendPlayerMessage("arc13", "whitelisted")
      return true
    end
  end

  --c.sendPlayerMessage("arc13", "not whitelisted")
  return false
end

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

local function getInventorySize(tInventory)
  local i = 0

  for k, v in pairs(tInventory) do
    i = i + 1
  end

  return i
end

local function getPlayers(range, x, y, z)
  if not z then
    return false
  end

  local playerList = {}
  local f = t.getEntityList(range, x, y, z)

  for k, v in pairs(f) do
    if v.type == "EntityPlayerMP" then
      table.insert(playerList, v.name)
    end
  end

  return playerList
end

local function logJoin(sPlayerJoined)
  if printLog then
    print(sPlayerJoined.." join")
  end

  local file = fs.open(sLogFile, "a")

  file.writeLine("["..date.formatDateTime("%d/%m/%y %h:%M").."] "..sPlayerJoined.." join")
  file.close()

  tInventoryPlayers[sPlayerJoined] = {inventory = {}}
  tInventoryPlayers[sPlayerJoined]["inventorySize"] = getInventorySize(t.getPlayerDetail(sPlayerJoined)[sPlayerJoined].inventory)

  for k, v in pairs(t.getPlayerDetail(sPlayerJoined)[sPlayerJoined].inventory) do
    table.insert(tInventoryPlayers[sPlayerJoined]["inventory"], v.displayName)
  end

  if useChatInterface == true and chatInterfaceConnected == true then
    for i = 1, #chatTo do
      local sMsg = string.gsub(joinMessage, "#p", sPlayerJoined)
      sMsg = sMsg:gsub("#M", date.formatDateTime("%M"))
      sMsg = sMsg:gsub("#h", date.formatDateTime("%h"))
      sMsg = sMsg:gsub("#d", date.formatDateTime("%d"))
      sMsg = sMsg:gsub("#m", date.formatDateTime("%m"))
      sMsg = sMsg:gsub("#y", date.formatDateTime("%y"))
      c.sendPlayerMessage(chatTo[i], sMsg)
    end
  end
end

local function logLeft(sPlayerLeft)
  if printLog then
    print(sPlayerLeft.." left")
  end

  local file = fs.open(sLogFile, "a")

  file.writeLine("["..date.formatDateTime("%d/%m/%y %h:%M").."] "..sPlayerLeft.." left")

  if tInventoryPlayers[sPlayerLeft]["inventorySize"] ~= getInventorySize(t.getPlayerDetail(sPlayerLeft)[sPlayerLeft].inventory) then
    print("Inventory has changed ! ("..getInventorySize(t.getPlayerDetail(sPlayerLeft)[sPlayerLeft].inventory).." items now, "..tInventoryPlayers[sPlayerLeft]["inventorySize"].." before)")

    local tCurrentInventory = {}

    for k, v in pairs(t.getPlayerDetail(sPlayerLeft)[sPlayerLeft].inventory) do
      table.insert(tCurrentInventory, v.displayName)
    end

    if getInventorySize(t.getPlayerDetail(sPlayerLeft)[sPlayerLeft].inventory) > tInventoryPlayers[sPlayerLeft]["inventorySize"] then
      -- Un/plusieurs item(s) à/ont été(s) ajouté(s)
      local tDifference = getTableDifference(tCurrentInventory, tInventoryPlayers[sPlayerLeft]["inventory"])

      file.writeLine("Inventory has changed (+) : ")

      file.write("/")

      for i = 1, #tDifference do
        file.write(tDifference[i].."/")
      end

      file.write("\n")
    elseif getInventorySize(t.getPlayerDetail(sPlayerLeft)[sPlayerLeft].inventory) < tInventoryPlayers[sPlayerLeft]["inventorySize"] then
      -- Un/plusieurs item(s) à/ont été(s) enlevée(s)
      local tDifference = getTableDifference(tInventoryPlayers[sPlayerLeft]["inventory"], tCurrentInventory)

      file.writeLine("Inventory has changed (-) : ")

      file.write("/")

      for i = 1, #tDifference do
        file.write(tDifference[i].."/")
      end

      file.write("\n")
    end
  end

  file.close()

  if useChatInterface == true and chatInterfaceConnected == true then
    for i = 1, #chatTo do
      local sMsg = string.gsub(leftMessage, "#p", sPlayerLeft)
      sMsg = sMsg:gsub("#M", date.formatDateTime("%M"))
      sMsg = sMsg:gsub("#h", date.formatDateTime("%h"))
      sMsg = sMsg:gsub("#d", date.formatDateTime("%d"))
      sMsg = sMsg:gsub("#m", date.formatDateTime("%m"))
      sMsg = sMsg:gsub("#y", date.formatDateTime("%y"))
      c.sendPlayerMessage(chatTo[i], sMsg)
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

  for i = 1, #tDifference do
    if not isInWhitelist(tDifference[i]) then
      logJoin(tDifference[i])
    else
      if printLog then
        print("Whitelisted : "..tDifference[i])
      end
    end
  end
end

local function playerLeft(tPlayers, tOldPlayers)
  local tDifference = getTableDifference(tOldPlayers, tPlayers)

  if leftProgram ~= "" and multishell then
    local sTempPlayers = ""

    for i = 1, #tDifference do
      sTempPlayers = sTempPlayers..tDifference[i]..","
    end

    shell.openTab(leftProgram.." "..sTempPlayers)
  end

  for i = 1, #tDifference do
    if not isInWhitelist(tDifference[i]) then
      logLeft(tDifference[i])
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
    tPlayers = getPlayers(nRange, nX, nY, nZ)

    if #tPlayers ~= #tOldPlayers then
      if printLog then
        print(#tPlayers.." players ("..#tOldPlayers.." before)")
      end
      if #tPlayers > #tOldPlayers then
        os.queueEvent("player_join", tPlayers, tOldPlayers)

        threadJoin = coroutine.create(playerJoin)
        coroutine.resume(threadJoin, tPlayers, tOldPlayers)
      elseif #tPlayers < #tOldPlayers then
        os.queueEvent("player_left", tPlayers, tOldPlayers)

        threadLeft = coroutine.create(playerLeft)
        coroutine.resume(threadLeft, tPlayers, tOldPlayers)
      end
    end

    sleep(0.1)
  end
end

-- Unitilisable avant que les events soit fixés
local function peripheralHandler()
  while bRun do
    local sEvent, sSide = os.pullEvent()

    if sEvent == "peripheral" or sEvent == "peripheral_detach" then
      print(sSide)
      print(pSide)
      print(tSide)
      print(cSide)
    end

    if sEvent == "peripheral" then
      if peripheral.getType(sSide) == "ChatInterface" then
        chatInterfaceConnected = true
        print("[SYSTEM] ChatInterface connected")
        cSide = sSide
      end
    elseif sEvent == "peripheral_detach" then
      if sSide == pSide then
        -- Le world interface à été détaché
        error("[SYSTEM] WorldInterface disconnected")
      elseif sSide == tSide then
        -- L'entity detector à été détaché
        error("[SYSTEM] EntityDetector disconnected")
      elseif sSide == cSide then
        -- Le chat interface à été détaché
        chatInterfaceConnected = false
        cSide = ""
        print("[SYSTEM] ChatInterface disconnected")
      end
    end
  end
end

local function chatHandler()
  while bRun do
    local sEvent, sPlayer, sMessage = os.pullEvent("chat_message")

    for i = 1, #canUseCommands do
      if sPlayer == canUseCommands[i] then
        if sMessage == "##disable_chat" then
          useChatInterface = false
          c.sendPlayerMessage(sPlayer, "Chat disabled !")
        elseif sMessage == "##enable_chat" then
          useChatInterface = true
          c.sendPlayerMessage(sPlayer, "Chat enabled !")
        elseif sMessage == "##stop" then
          c.sendPlayerMessage(sPlayer, "Terminated")
          os.pullEvent = oldPullEvent
          bRun = false
        elseif sMessage == "##get_players" then
          local tPlayersToSend = getPlayers(nRange, nX, nY, nZ)

          local sMsgToSend = ""

          if #tPlayersToSend == 0 then
            c.sendPlayerMessage(sPlayer, "No players detected")
          elseif #tPlayersToSend == 1 then
            c.sendPlayerMessage(sPlayer, "Player : "..tPlayersToSend[1])
          else
            for i = 1, #tPlayersToSend - 1 do
              sMsgToSend = sMsgToSend..tPlayersToSend[i]..", "
            end

            sMsgToSend = sMsgToSend..tPlayersToSend[#tPlayersToSend]

            c.sendPlayerMessage(sPlayer, sMsgToSend)
          end
        end
      end
    end
  end
end

parallel.waitForAll(main, chatHandler)
