-- Variables à modifier

local sLogFile = "probe.log"
local nRange = 1
local nX = -211
local nY = 75
local nZ = 424

-- Fin des variables à modifier

local t = peripheral.find("EntityDetector")
local p = peripheral.find("WorldInterface")

if not t then
  error("No EntityDetector found !")
end

if not p then
  error("No WorldInterface found !")
end

local tPlayers = {}
local tOldPlayers = {}

if not fs.exists(sLogFile) then
  local file = fs.open(sLogFile, "w")
  file.close()
end

term.clear()
term.setCursorPos(1, 1)

<<<<<<< HEAD
print("Player detector v0.3.4-test")
=======
print("Player detector v0.4.1-master")
>>>>>>> refs/remotes/origin/test
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
  print(sPlayerJoined.." join")
  local file = fs.open(sLogFile, "a")
<<<<<<< HEAD
  local date = time.getRealCompleteDate()
  local hour = time.getRealComplete()
  file.writeLine("["..date.." "..hour.."] "..sPlayerJoined.." join")
=======

  file.writeLine("["..p.getRealDate().."] "..sPlayerJoined.." join")
>>>>>>> refs/remotes/origin/test
  file.close()
end

local function logLeft(sPlayerLeft)
  print(sPlayerLeft.." left")
  local file = fs.open(sLogFile, "a")
<<<<<<< HEAD
  local file = fs.open(sLogFile, "a")
  local date = time.getRealCompleteDate()
  local hour = time.getRealComplete()
  file.writeLine("["..date.." "..hour.."] "..sPlayerJoined.." left")
  file.close()
=======

  file.writeLine("["..p.getRealDate().."] "..sPlayerLeft.." left")
  file.close()
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
>>>>>>> refs/remotes/origin/test
end

local function main()
  while true do
    tOldPlayers = tPlayers
    tPlayers = getPlayers(nRange, nX, nY, nZ)

    if #tPlayers ~= #tOldPlayers then
      print(#tPlayers.." players ("..#tOldPlayers.." before)")
      if #tPlayers > #tOldPlayers then
        os.queueEvent("player_join", tPlayers, tOldPlayers)
<<<<<<< HEAD
        --print("join queued")
      elseif #tPlayers < #tOldPlayers then
        os.queueEvent("player_left", tPlayers, tOldPlayers)
        --print("left queued")
      end
    end

    sleep(0.1)
  end
end

local function playerJoinHandler()
  while true do
    local event, tPlayers, tOldPlayers = os.pullEvent("player_join")

    local tDifference = getTableDifference(tPlayers, tOldPlayers)

    for i = 1, #tDifference do
      logJoin(tDifference[i])
    end
  end
end

local function playerLeftHandler()
  while true do
    local event, tPlayers, tOldPlayers = os.pullEvent("player_left")

    local tDifference = getTableDifference(tOldPlayers, tPlayers)

    for i = 1, #tDifference do
      logLeft(tDifference[i])
=======

        threadJoin = coroutine.create(playerJoin)
        coroutine.resume(threadJoin, tPlayers, tOldPlayers)
      elseif #tPlayers < #tOldPlayers then
        os.queueEvent("player_left", tPlayers, tOldPlayers)

        threadLeft = coroutine.create(playerLeft)
        coroutine.resume(threadLeft, tPlayers, tOldPlayers)
      end
>>>>>>> refs/remotes/origin/test
    end

    sleep(0.1)
  end
end

<<<<<<< HEAD
parallel.waitForAll(main, playerJoinHandler, playerLeftHandler)
=======
parallel.waitForAll(main)
>>>>>>> refs/remotes/origin/test
