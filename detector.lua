-- Variables à modifier

local sLogFile = "probe.log"
local nRange = 20
local nX = -211
local nY = 75
local nZ = 424

-- Fin des variables à modifier

local t = peripheral.find("EntityDetector")

if not t then
  error("No EntityDetector found !")
end

local tPlayers = {}
local tOldPlayers = {}

if not fs.exists("time") then
  shell.run("pastebin get 6nArsPfK time")
end

os.loadAPI("time")

if not fs.exists(sLogFile) then
  local file = fs.open(sLogFile, "w")
  file.close()
end

term.clear()
term.setCursorPos(1, 1)

print("Player detector v0.3.2")
print(string.char(169).." arc13\n")

local function getTableDifference(oldTable, newTable)
  if not newTable then
    return false
  end

  tDifference = {}

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
    isOK = false

    selectedTable = oldTable[i]
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
  local file = fs.open(sLogFile, "a")
  file.writeLine("["..time.getRealCompleteDate().." "..time.getRealComplete().."] "..sPlayerJoined.." join")
  file.close()
  print(sPlayerJoined.." join")
end

local function logLeft(sPlayerLeft)
  local file = fs.open(sLogFile, "a")
  file.writeLine("["..time.getRealCompleteDate().." "..time.getRealComplete().."] "..sPlayerLeft.." left")
  file.close()
  print(sPlayerLeft.." left")
end

local function main()
  while true do
    tOldPlayers = tPlayers
    tPlayers = getPlayers(nRange, nX, nY, nZ)

    if #tPlayers ~= #tOldPlayers then
      print(#tPlayers.." players")
      if #tPlayers > #tOldPlayers then
        os.queueEvent("player_join", tPlayers, tOldPlayers)
      elseif #tPlayers < #tOldPlayers then
        os.queueEvent("player_left", tPlayers, tOldPlayers)
      end
    end

    sleep(1)
  end
end

local function playerHandler()
  while true do
    bState = false

    local event, tPlayers, tOldPlayers = os.pullEvent()

    if event == "player_join" then
      local tDifference = getTableDifference(tPlayers, tOldPlayers)

      for i = 1, #tDifference do
        logJoin(tDifference[i])
      end
    elseif event == "player_left" then
      local tDifference = getTableDifference(tOldPlayers, tPlayers)

      for i = 1, #tDifference do
        logLeft(tDifference[i])
      end
    end
  end
end

parallel.waitForAll(main, playerHandler)