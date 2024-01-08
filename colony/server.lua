local colony = peripheral.find("colonyIntegrator")
local quit = false
local protocol = "colony"
local hostname = colony.getColonyName()

local function eventLoop(colony, protocol)
    local sender, message = rednet.receive(protocol)
    if type(message) ~= "table" or type(message.call) ~= "string" then
        return
    end
    local call = message.call
    if call == "getColonyName" then
        rednet.send(sender, colony.getColonyName(), protocol)
    elseif call == "getHappiness" then
        rednet.send(sender, colony.getHappiness(), protocol)
    elseif call == "getCitizens" then
        rednet.send(sender, colony.getCitizens(), protocol)
    elseif call == "amountOfCitizens" then
        rednet.send(sender, colony.amountOfCitizens(), protocol)
    elseif call == "maxOfCitizens" then
        rednet.send(sender, colony.maxOfCitizens(), protocol)
    elseif call == "getVisitors" then
        rednet.send(sender, colony.getVisitors(), protocol)
    elseif call == "getBuildings" then
        rednet.send(sender, colony.getBuildings(), protocol)
    elseif call == "getWorkOrders" then
        rednet.send(sender, colony.getWorkOrders(), protocol)
    elseif call == "getRequests" then
        rednet.send(sender, colony.getRequests(), protocol)
    elseif call == "getResearch" then
        rednet.send(sender, colony.getResearch(), protocol)
    elseif call == "getWorkOrderResources" then
        rednet.send(sender, colony.getWorkOrderResources(message.arg), protocol)
    else
        rednet.send(sender, {error="unknown call"}, protocol)
    end
end

local args = {...}
if #args ~= 1 then
    error("Usage: server modem-side")
end
local side = args[1]
rednet.open(side)
if not rednet.isOpen(side) then
    error("Rednet not open")
end
rednet.host(protocol, hostname)
repeat
    pcall(function()
        eventLoop(colony, protocol)
    end)
until quit
rednet.unhost(protocol, hostname)
