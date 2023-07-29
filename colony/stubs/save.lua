ci=peripheral.find("colonyIntegrator")
c=ci.getCitizens()
v=ci.getVisitors()
b=ci.getBuildings()
w=ci.getWorkOrders()
r=ci.getRequests()

function serialize(value)
  local ok,str = pcall(function()
    return textutils.serialize(value)
  end)
  if ok then
    return str
  end
  str = "{\n"
  if #value > 0 then
    for i=1,#value do
      str = str .. serialize(value[i]) .. ",\n" 
    end
  else
    for k, v in pairs(value) do
      str = str .. "[" .. serialize(k) .. "] = " .. serialize(v) .. ",\n"
    end
  end
  str = str .. "}"
  return str
end

function wf(f, name, value)
  f.writeLine(name .. "=function()")
  f.writeLine("  return " .. serialize(value))
  f.writeLine("end,")
end

function wm(f, name, values)
  f.writeLine(name .. "=function(id)")
  f.writeLine("  if id == nil then")
  f.writeLine("    return nil")
  for k,v in pairs(values) do
    f.writeLine("  elseif id == " .. serialize(k) .. " then")
    f.writeLine("    return " .. serialize(v))
  end
  f.writeLine("  end")
  f.writeLine("end,")
end

f = fs.open("stub.lua", "w")
f.writeLine("COLONY_STUB = {")
wf(f, "getColonyID", ci.getColonyID())
wf(f, "getColonyName", ci.getColonyName())
wf(f, "getColonyStyle", ci.getColonyStyle())
wf(f, "getLocation", ci.getLocation())
wf(f, "getHappiness", ci.getHappiness())
wf(f, "isActive", ci.isActive())
wf(f, "isUnderAttack", ci.isUnderAttack())
wf(f, "isUnderRaid", ci.isUnderRaid())
wf(f, "isInColony", ci.isInColony())
wf(f, "isWithin", true)
wf(f, "amountOfCitizens", ci.amountOfCitizens())
wf(f, "maxOfCitizens", ci.maxOfCitizens())
wf(f, "amountOfGraves", ci.amountOfGraves())
wf(f, "amountOfConstructionSites", ci.amountOfConstructionSites())
wf(f, "getCitizens", c)
wf(f, "getVisitors", v)
wf(f, "getBuildings", b)
wf(f, "getWorkOrders", w)
wf(f, "getRequests", r)
if ci.getResearch then
  wf(f, "getResearch", ci.getResearch())
end

wor={}
br={}
for i=1,#w do
  local wo = w[i]
  wor[wo.id] = ci.getWorkOrderResources(wo.id)
  local builder = wo.builder
  if builder ~= nil then
    br[builder] = ci.getBuilderResources(builder)
  end
end

wm(f, "getWorkOrderResources", wor)
wm(f, "getBuilderResources", br)

f.writeLine("}")
f.close()
