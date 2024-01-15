Generator={
  storedPower=25990000,
  maxPower=26000000,
  usedPower=666,
  setEnabled=function(value) Generator.enabled=value end,
  getEnabled=function() return Generator.enabled end,
  isRunning=function() return Generator.running end,
  enabled=false,
  running=false,
  getFluid=function() return {amount=12388} end,
  getTankSize=function() return 24000 end,
}
Refinery={
  getLeftInputFluid=function() return {amount=24000} end,
  getLeftInputTankSize=function() return 24000 end,
  getRightInputFluid=function() return {amount=24000} end,
  getRightInputTankSize=function() return 24000 end,

  getOutputFluid=function() return {amount=23800} end,
  getOutputTankSize=function() return 24000 end,
}
Fermenter={
  getFluid=function() return {amount=23982} end,
  getTankSize=function() return 24000 end,
}
Squeezer={
  getFluid=function() return {amount=19872} end,
  getTankSize=function() return 24000 end,
}
GetStoredPower = function()
  return Generator.storedPower, Generator.maxPower
end
GetUsedPower = function()
  if fs.exists("usedPower") then
    local f = fs.open("usedPower", "r")
    Generator.usedPower = textutils.unserialise(f.readAll())
    f.close()
  else
    Generator.usedPower = math.max(0, math.random(Generator.usedPower - 100, Generator.usedPower + 100))
  end
  return Generator.usedPower
end
