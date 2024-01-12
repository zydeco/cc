
function wrapColony(colonyIntegrator)
    local wrapper = {}

    local function wrappedCall(originalFunction, defaultValue)
        return function()
            local result = defaultValue
            pcall(function()
                result = originalFunction()
            end)
            return result
        end
    end

    wrapper.getColonyName = wrappedCall(colonyIntegrator.getColonyName, "{red}No colony")
    wrapper.getHappiness = wrappedCall(colonyIntegrator.getHappiness, 0.0)
    wrapper.getCitizens = wrappedCall(colonyIntegrator.getCitizens, {})
    wrapper.amountOfCitizens = wrappedCall(colonyIntegrator.amountOfCitizens, 0)
    wrapper.maxOfCitizens = wrappedCall(colonyIntegrator.maxOfCitizens, 0)
    wrapper.getVisitors = wrappedCall(colonyIntegrator.getVisitors, {})
    wrapper.getBuildings = wrappedCall(colonyIntegrator.getBuildings, {})
    wrapper.getWorkOrders = wrappedCall(colonyIntegrator.getWorkOrders, {})
    wrapper.getRequests = wrappedCall(colonyIntegrator.getRequests, {})
    wrapper.getResearch = wrappedCall(colonyIntegrator.getResearch, {})

    wrapper.getWorkOrderResources = function(orderId)
        local result = {}
        pcall(function()
            result = colonyIntegrator.getWorkOrderResources(orderId)
        end)
        return result
    end

    return wrapper
end

function wrapRemoteColony(colonyName, side)
    local wrapper = {}
    local timeout = 2
    local protocol = "colony"

    -- open rednet
    rednet.open(side)
    if not rednet.isOpen(side) then
        print("Rednet not open. Ensure modem exists.")
        return nil
    end

    -- find colony
    print("Looking for colony...")
    local remote = rednet.lookup(protocol, colonyName)
    if remote == nil then
        print("Colony not found")
        return nil
    end
    print("Found colony computer ID " .. remote)
    local function remoteCall(functionName, defaultValue)
        return function(arg)
            local result = defaultValue
            rednet.send(remote, {call=functionName, arg=arg}, protocol)
            local _, message = rednet.receive(protocol, timeout)
            if message ~= nil then
                result = message
            end
            return result
        end
    end

    wrapper.getColonyName = remoteCall("getColonyName", "{red}No colony")
    wrapper.getHappiness = remoteCall("getHappiness", 0.0)
    wrapper.getCitizens = remoteCall("getCitizens", {})
    wrapper.amountOfCitizens = remoteCall("amountOfCitizens", 0)
    wrapper.maxOfCitizens = remoteCall("maxOfCitizens", 0)
    wrapper.getVisitors = remoteCall("getVisitors", {})
    wrapper.getBuildings = remoteCall("getBuildings", {})
    wrapper.getWorkOrders = remoteCall("getWorkOrders", {})
    wrapper.getRequests = remoteCall("getRequests", {})
    wrapper.getResearch = remoteCall("getResearch", {})
    wrapper.getWorkOrderResources = remoteCall("getWorkOrderResources", {})
    wrapper.highlightWorker = remoteCall("highlightWorker", false) -- arg {id=123}
    wrapper.highlightWorker = remoteCall("highlightBuilding", false) --  arg {}
    return wrapper
end

local function getRemoteColonyName(id)
    rednet.send(id, {call="getColonyName"}, "colony")
    local _, message = rednet.receive("colony", 2)
    return message
end

function listRemoteColonies(side)
    local protocol = "colony"

    -- open rednet
    rednet.open(side)
    if not rednet.isOpen(side) then
        print("Rednet not open. Ensure modem exists.")
        return
    end

    -- find colonies
    print("Looking for colonies...")
    local remotes = {rednet.lookup(protocol)}
    if #remotes == 0 then
        print("No colonies found")
        return
    end

    -- print results
    print("Found " .. #remotes .. " colony server(s):")
    for _, remote in ipairs(remotes) do
        local name = getRemoteColonyName(remote)
        print(name)
    end
end
