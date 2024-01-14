local colony = peripheral.find("colonyIntegrator")
local quit = false
local protocol = "colony"

local function handleRednetMessage(colony, sender, message)
    if type(message) ~= "table" or type(message.call) ~= "string" then
        print(string.format("%d invalid message", sender))
        return
    end
    local call = message.call
    print(string.format("%d:%s", sender, call))
    if call == "getColonyName" then
        rednet.send(sender, {call=call, result=colony.getColonyName()}, protocol)
    elseif call == "getHappiness" then
        rednet.send(sender, {call=call, result=colony.getHappiness()}, protocol)
    elseif call == "getCitizens" then
        rednet.send(sender, {call=call, result=colony.getCitizens()}, protocol)
    elseif call == "amountOfCitizens" then
        rednet.send(sender, {call=call, result=colony.amountOfCitizens()}, protocol)
    elseif call == "maxOfCitizens" then
        rednet.send(sender, {call=call, result=colony.maxOfCitizens()}, protocol)
    elseif call == "getVisitors" then
        rednet.send(sender, {call=call, result=colony.getVisitors()}, protocol)
    elseif call == "getBuildings" then
        rednet.send(sender, {call=call, result=colony.getBuildings()}, protocol)
    elseif call == "getWorkOrders" then
        rednet.send(sender, {call=call, result=colony.getWorkOrders()}, protocol)
    elseif call == "getRequests" then
        rednet.send(sender, {call=call, result=colony.getRequests()}, protocol)
    elseif call == "getResearch" then
        rednet.send(sender, {call=call, result=colony.getResearch()}, protocol)
    elseif call == "getWorkOrderResources" then
        rednet.send(sender, {call=call, result=colony.getWorkOrderResources(message.arg)}, protocol)
    else
        rednet.send(sender, {error="unknown call"}, protocol)
    end
end

local function eventLoop(colony, protocol)
    local event, p1, p2, p3 = os.pullEvent()
    if event == "rednet_message" and p3 == protocol then
        handleRednetMessage(colony, p1, p2)
    elseif event == "rednet_message" and p3 == "colony_query" then
        print(string.format("%d:query", p1))
        rednet.send(p1, {name=colony.getColonyName()}, p3)
    elseif event == "char" and p1 == "q" then
        print("Goodbye!")
        quit=true
    end
end

local function saveState(state)
    f = fs.open(state.fileName, "w")
    f.write(textutils.serialize(state))
    f.close()
end

local function loadState(colony, fileName)
    local state = {}
    f = fs.open(fileName, "r")
    if f ~= nil then
        state = textutils.unserialize(f.readAll())
        f.close()
    end
    -- set initial citizens
    local save = false
    if state.citizens == nil then
        state.citizens = {}
        for _, citizen in ipairs(colony.getCitizens()) do
            state.citizens[citizen.id] = citizen
        end
        save = true
    end
    if state.log == nil then
        state.log = {}
        save = true
    end
    if state.fileName == nil then
        state.fileName = fileName
    end
    if save then saveState(state) end
    return state
end

local function idle(colony, state)
    local time = {
        day=os.day(),
        time=os.time(),
        utc=os.epoch("utc"),
        date=os.date(),
    }
    local timeDiff = time.utc - state.lastIdleTick
    if time.utc - state.lastIdleTick > 30000 then
        return
    else
        state.lastIdleTick = time.utc
    end
    -- check citizens for births or joins
    local citizens = colony.getCitizens()
    local save = false
    local alive = {}
    for _, citizen in ipairs(citizens) do
        alive[citizens.id] = true
        if state.citizens[citizen.id] == nil then
            -- new citizen
            table.insert(state.log, {time=time, event="new_citizen", citizen=citizen})
            state.citizens[citizen.id] = citizen
            save = true
        end
    end
    -- check for deaths
    for id, citizen in pairs(state.citizens) do
        if alive[id] ~= true then
            table.insert(state.log, {time=time, event="death", citizen={id=id, name=citizen.name}})
            citizen.death = time
            save = true
        end
    end
    -- save state
    if save then saveState(state) end
end

local args = {...}
if #args == 2 then
    print("Using colony stub")
    require("stubs/" .. args[2])
    colony = COLONY_STUB
elseif #args ~= 1 then
    error("Usage: server modem-side")
end

local hostname = colony.getColonyName()

-- open modem
local side = args[1]
rednet.open(side)
if not rednet.isOpen(side) then
    error("Rednet not open")
end

-- load state
local state = loadState(colony, string.format("colony%d.state", colony.getColonyID()))

-- start server
print("Serving colony " .. hostname .."...")
print("Hold Q to quit")
rednet.host(protocol, hostname)

repeat
    pcall(function()
        eventLoop(colony, protocol)
        if not quit then idle(colony, state) end
    end)
until quit

print("Saving state to " .. state.fileName)
saveState(state)
rednet.unhost(protocol, hostname)
