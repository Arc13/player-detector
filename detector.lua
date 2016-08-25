local sVersion = "v0.6.1-master"

-- Variables à modifier

local sLogFile = "probe.log"
local nRange = 1
local nX = -211
local nY = 75
local nZ = 424

local useChatInterface = true
local joinMessage = "#p joined"
local leftMessage = "#p left"
local chatTo = {"arc13"}
local chatName = "Player Probe "..sVersion

-- Fin des variables à modifier

if not fs.exists("date") then
  shelL.run("pastebin get 8GiE70cH date")
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
print(string.char(169).." arc13\n")

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
  print(sPlayerJoined.." join")
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
      c.sendPlayerMessage(chatTo[i], sMsg)
    end
  end
end

local function logLeft(sPlayerLeft)
  print(sPlayerLeft.." left")
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
      c.sendPlayerMessage(chatTo[i], sMsg)
    end
  end
end

local function playerJoin(tPlayers, tOldPlayers)
  local tDifference = getTableDifference(tPlayers, tOldPlayers)

  for i = 1, #tDifference do
    logJoin(tDifference[i])
  end
end

local function playerLeft(tPlayers, tOldPlayers)
  local tDifference = getTableDifference(tOldPlayers, tPlayers)

  for i = 1, #tDifference do
    logLeft(tDifference[i])
  end
end

local function main()
  while true do
    tOldPlayers = tPlayers
    tPlayers = getPlayers(nRange, nX, nY, nZ)

    if #tPlayers ~= #tOldPlayers then
      print(#tPlayers.." players ("..#tOldPlayers.." before)")
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
  while true do
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
        print("ChatInterface connected")
        cSide = sSide
      end
    elseif sEvent == "peripheral_detach" then
      if sSide == pSide then
        -- Le world interface à été détaché
        error("WorldInterface disconnected")
      elseif sSide == tSide then
        -- L'entity detector à été détaché
        error("EntityDetector disconnected")
      elseif sSide == cSide then
        -- Le chat interface à été détaché
        chatInterfaceConnected = false
        cSide = ""
        print("ChatInterface disconnected")
      end
    end
  end
end

parallel.waitForAll(main)
