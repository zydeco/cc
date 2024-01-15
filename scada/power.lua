local modem=peripheral.wrap("back")
local monitor=peripheral.wrap("bottom")
Generator=peripheral.wrap("diesel_generator_0")
Refinery=peripheral.wrap("refinery_0")
Fermenter=peripheral.wrap("fermenter_0")
Squeezer=peripheral.wrap("squeezer_0")
local drainHistory={}
-- how many iterations to update store power
local storedPowerUpdateInterval = 10

function GetStoredPower()
  local total, max = 0, 0
  for _,name in pairs(modem.getNamesRemote()) do
    if name:sub(1,13) == "capacitor_hv_" then
      total = total + modem.callRemote(name, "getEnergyStored")
      max = max + modem.callRemote(name, "getMaxEnergyStored")
    end
  end
  return total, max
end

function GetUsedPower()
  return peripheral.wrap("top").getAveragePower()
end

local args = {...}
if #args == 1 then
  require(args[1])
end

function formatValue(value, format)
  format = format or "%.2f"
  if value > 999999999 then
    return string.format(format .. "G", value / 1000000000)
  elseif value > 999999 then
    return string.format(format .. "M", value / 1000000)
  elseif value > 9999 then
    return string.format(format .. "k", value / 1000)
  else
    return string.format("%d", value)
  end
end

local function initScreen()
  monitor.setTextScale(2.0)
  monitor.setTextColor(colors.black)
  monitor.setBackgroundColor(colors.white)
  monitor.clear()
  monitor.setCursorPos(1,1)
  monitor.write("POWER:")
  monitor.setCursorPos(1,3)
  monitor.write("DRAIN:")
  monitor.setCursorPos(1,7)
  monitor.write("FLUIDS:")
  monitor.setCursorPos(1,8)
  monitor.write("ETH")
  monitor.setCursorPos(1,9)
  monitor.write("OIL")
  monitor.setCursorPos(1,10)
  monitor.write("DSL")
  drainHistory = table.rep(0, 26)
end

local GRAPH_BITS={
   [0]="\x80",
   [1]="\x9f!",
   [2]="\x97!",
   [3]="\x95!",
  [10]="\x90",
  [11]="\x8f!",
  [12]="\x87!",
  [13]="\x85!",
  [20]="\x94",
  [21]="\x8b!",
  [22]="\x83!",
  [23]="\x81!",
  [30]="\x95",
  [31]="\x8a!",
  [32]="\x82!",
  [33]="\x80!",
}

local function graphBit(value1, value2, fg, bg)
  local char = GRAPH_BITS[math.max(0, math.min(value1, 3)) * 10 + math.max(0, math.min(value2, 3))]
  if char:len()==2 then
    return char:sub(1,1), bg, fg
  else
    return char, fg, bg
  end
end

function DrawGraph(x, y, height, values, scale, fg, bg)
  -- scale = max value, or function mapping value to [0,height*3]
  -- fg = color, or function that returns color for TWO VALUES
  local width = math.floor(#values / 2)
  if type(fg) ~= "function" then
    local fgValue = fg
    fg = function(_,_) return colors.green end
  end
  local lines = {}
  -- calculate value stops
  if type(scale) ~= "function" then
    local unit = scale / (height*3)
    scale = function(value) return math.ceil(value / unit) end
  end
  -- scale values
  local scaled = {}
  local barColors = {}
  for i = 1, #values, 2 do
    table.insert(scaled, scale(values[i]))
    table.insert(scaled, scale(values[i+1]))
    table.insert(barColors, fg(values[i], values[i+1]))
  end
  -- draw
  for i = 1, height do
    local line = ""
    local fgs = ""
    local bgs = ""
    local base = 3 * (height-i)
    for v = 1, 2*width, 2 do
      local c,f,b = graphBit(scaled[v]-base, scaled[v+1]-base, barColors[math.ceil(v/2)], bg)
      line = line .. c
      fgs = fgs .. colors.toBlit(f)
      bgs = bgs .. colors.toBlit(b)
    end
    monitor.setCursorPos(x,y+i-1)
    monitor.blit(line, fgs, bgs)
  end
end

function DrawBar(x, y, width, progress, fg, bg, text)
  monitor.setCursorPos(x,y)
  monitor.setBackgroundColor(fg)
  local full = math.floor(width*progress)
  local line = string.rep(" ", full)
  monitor.setTextColor(bg)
  if text ~= nil and text:len() <= full then
    line = (text..line):sub(1, full)
    text = nil
  end
  monitor.write(line)
  monitor.setBackgroundColor(bg)
  monitor.setTextColor(fg)
  local empty = math.floor((1.0 - progress) * width)
  line = string.rep(" ", empty)
  if text ~= nil and text:len() <= empty then
    line = (text..line):sub(1, empty)
  end
  if full + empty < width then
    local diff = (progress * width) - full
    if diff >= 0.4 then
      line = "\x95" .. line
    else
      line = line .. " "
    end
  end
  monitor.write(line)
end

local function getEthanol()
  local stored = Fermenter.getFluid().amount + Refinery.getLeftInputFluid().amount
  local max = Fermenter.getTankSize() + Refinery.getLeftInputTankSize()
  return stored, max
end

local function getPlantOil()
  local stored = Squeezer.getFluid().amount + Refinery.getRightInputFluid().amount
  local max = Squeezer.getTankSize() + Refinery.getRightInputTankSize()
  return stored, max
end

local function getDiesel()
  local stored = Refinery.getOutputFluid().amount + Generator.getFluid().amount
  local max = Refinery.getOutputTankSize() + Generator.getTankSize()
  return stored, max
end

local function updateScreen(storedPwr, maxPwr)
  local updateBatteryStatus = (storedPwr ~= nil and maxPwr ~= nil)
  monitor.setCursorPos(1,1)
  monitor.setBackgroundColor(colors.white)
  monitor.setTextColor(colors.black)
  if Generator.isRunning() then
    monitor.blit("POWER", "ddddd", "00000")
  elseif Generator.getEnabled() then
    monitor.blit("POWER", "44444", "eeeee")
  else
    monitor.blit("POWER", "fffff", "00000")
  end
  monitor.setCursorPos(8,1)
  monitor.write(formatValue(storedPwr).."F      ")
  monitor.setCursorPos(8,3)
  local drain = GetUsedPower()
  monitor.write(formatValue(drain).."F/t      ")
  table.insert(drainHistory, drain)
  if #drainHistory > 26 then table.remove(drainHistory, 1) end

  -- battery bar
  local batteryLevel = storedPwr/maxPwr
  local batteryColor = colors.green
  if batteryLevel < 0.5 then
    batteryColor = colors.orange
  elseif batteryLevel < 0.2 then
    batteryColor = colors.red
  end
  DrawBar(2,2,13, batteryLevel, batteryColor, colors.gray)
  -- drain bar
  local drainLevel = drain / 4096.0
  local drainColor = colors.green
  if drainLevel > 0.75 then
    drainColor = colors.orange
  elseif drainLevel >= 1.0 then
    drainColor = colors.red
  end
  DrawGraph(2,4,3,drainHistory, 4096.0, function(a,b)
    local v = math.max(a,b)
    if v >= 3500 then
      return colors.red
    elseif v >= 2000 then
      return colors.orange
    else
      return colors.green
    end
  end, colors.gray)
  -- ethanol bar
  local ethStored, ethMax = getEthanol()
  DrawBar(4,8,11, ethStored/ethMax, colors.lightGray, colors.gray, formatValue(ethStored, "%.0f"))
  -- plant oil bar
  local oilStored, oilMax = getPlantOil()
  DrawBar(4,9,11, oilStored/oilMax, colors.yellow, colors.gray, formatValue(oilStored, "%.0f"))
  -- diesel bar
  local fuelStored, fuelMax = getDiesel()
  DrawBar(4,10,11, fuelStored/fuelMax, colors.brown, colors.gray, formatValue(fuelStored, "%.0f"))
end

local function enableOrDisableGenerator(batteryPercent)
  local generatorOn = Generator.getEnabled()
  if batteryPercent < 0.2 and not generatorOn then
    print("Enabling generator")
    Generator.setEnabled(true)
  elseif batteryPercent > 0.9 and generatorOn then
    print("Disabling generator")
    Generator.setEnabled(false)
  end
end

print("Starting industrial monitor")
initScreen()
local nextStoredPowerUpdate = 0
local storedPwr, maxPwr = nil, nil
while true do
  local doBatteryUpdate = (storedPwr == nil or nextStoredPowerUpdate <= 0)
  if doBatteryUpdate then
    storedPwr, maxPwr = GetStoredPower()
    nextStoredPowerUpdate = storedPowerUpdateInterval - 1
    enableOrDisableGenerator(storedPwr / maxPwr)
  else
    nextStoredPowerUpdate = nextStoredPowerUpdate - 1
  end
  updateScreen(storedPwr, maxPwr)
  os.sleep(1.0)
end
