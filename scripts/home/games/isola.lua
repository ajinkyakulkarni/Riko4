local gridSize = 9

local rif = dofile("/lib/rif.lua")

local running = true
local width, height = gpu.width, gpu.height
local translateX = math.floor((width  - (gridSize + 1) * 16) / 2)
local translateY = math.floor((height - (gridSize + 1) * 16) / 2)

local curs = rif.createImage("curs.rif")
local tex = rif.createImage("tex.rif")

local mousePosX, mousePosY = -5, -5


local grid = {}
for i = 0, (gridSize - 1) do
  grid[i] = {}
  for j = 0, (gridSize - 1) do
    if j % (gridSize - 1) == 0 and i == (gridSize - 1) / 2 then
      grid[i][j] = true
    else
      grid[i][j] = false
    end
  end
end

local turn = 0
local state = 0

local p1 = {(gridSize - 1) / 2, gridSize - 1}
local p2 = {(gridSize - 1) / 2, 0}
local lookup = {p1, p2}

local function playMove()
  speaker.stopChannel(3)
  speaker.play({channel = 3, frequency = 600, time = 0.06, shift = 0, volume = 0.06, attack = 0, release = 0})
  speaker.play({channel = 3, frequency = 800, time = 0.06, shift = 0, volume = 0.06, attack = 0, release = 0})
  speaker.play({channel = 3, frequency = 900, time = 0.06, shift = 0, volume = 0.06, attack = 0, release = 0})
  speaker.play({channel = 3, frequency = 800, time = 0.06, shift = 0, volume = 0.06, attack = 0, release = 0})
  speaker.play({channel = 3, frequency = 600, time = 0.06, shift = 0, volume = 0.06, attack = 0, release = 0})
end

local function playDestroy()
  speaker.stopChannel(5)
  speaker.play({channel = 5, frequency = 600, time = 0.15, shift = -400, volume = 0.06, attack = 0, release = 0})
end

local function playNotAllowed()
  speaker.stopChannel(2)
  speaker.play({channel = 2, frequency = 400, time = 0.03, shift = 50, volume = 0.06, attack = 0, release = 0})
  speaker.play({channel = 2, frequency = 500, time = 0.01, shift = -400, volume = 0, attack = 0, release = 0})
  speaker.play({channel = 2, frequency = 400, time = 0.03, shift = 50, volume = 0.06, attack = 0, release = 0})
end

local dirty = true

local function draw()
  if dirty then
    gpu.clear()

    for i = 0, gridSize - 1 do
      for j = 0, gridSize - 1 do
        if grid[i][j] then
          tex:render(translateX + i * 16, translateY + j * 16, 17, 0, 16, 16)
        else
          tex:render(translateX + i * 16, translateY + j * 16, 0, 0, 16, 16)
        end
      end
    end

    tex:render(translateX + p1[1] * 16 - 1, translateY + p1[2] * 16 - 1, 0, 17, 16, 16)
    tex:render(translateX + p2[1] * 16 - 1, translateY + p2[2] * 16 - 1, 17, 17, 16, 16)

    tex:render(translateX + 0, translateY + gridSize * 16, 0, 34, 16, 16)
    tex:render(translateX + gridSize * 16, translateY + 0, 34, 0, 16, 16)

    tex:render(translateX + gridSize * 16, translateY + gridSize * 16, 34, 34, 16, 16)
    for i = 1, gridSize - 1 do
      tex:render(translateX + i * 16, translateY + gridSize * 16, 17, 34, 16, 16)
      tex:render(translateX + gridSize * 16, translateY + i * 16, 34, 17, 16, 16)
    end

    local str = "P" .. (turn + 1) .. "'s turn: " .. (state == 0 and "Move" or "Destroy")
    write(str, math.floor((width - (8 * #str)) / 2) + 1, translateY + 16 * (gridSize + 1) + 1, turn == 0 and 2 or 3)
    write(str, math.floor((width - (8 * #str)) / 2), translateY + 16 * (gridSize + 1), turn == 0 and 13 or 14)

    curs:render(mousePosX, mousePosY)

    gpu.swap()

    dirty = false
  end
end

local function processEvent(e, ...)
  if e == "key" then
    local key = ...
    if key == "escape" then
      running = false
    end
  elseif e == "mouseMoved" then
    local nx, ny = ...
    mousePosX = nx
    mousePosY = ny

    dirty = true
  elseif e == "mousePressed" then
    local mx, my = ...
    mx, my = mx - translateX, my - translateY

    local dirted

    local rx, ry = math.floor(mx / 16), math.floor(my / 16)
    if rx < 0 or rx > #grid or ry < 0 or ry > #grid[0] then return end
    if grid[rx][ry] then return playNotAllowed() end

    if (p1[1] == rx and p1[2] == ry) or (p2[1] == rx and p2[2] == ry) then return playNotAllowed() end

    if state == 0 then
      local dx, dy =
        rx - lookup[turn + 1][1],
        ry - lookup[turn + 1][2]

      if math.abs(dx) > 1 or math.abs(dy) > 1 then return playNotAllowed() end

      lookup[turn + 1][1] = rx
      lookup[turn + 1][2] = ry

      dirted = true
      playMove()
    else
      grid[rx][ry] = true
      dirted = true
      playDestroy()
    end

    if dirted then
      turn = state == 1 and 1 - turn or turn
      state = (state + 1) % 2
      dirty = true
    end
  end
end

local eventQueue = {}
while running do
  while true do
    local e = {coroutine.yield()}
    if #e == 0 then break end
    eventQueue[#eventQueue + 1] = e
  end

  while #eventQueue > 0 do
    processEvent(unpack(
      table.remove(eventQueue, 1)))
  end

  draw()
end