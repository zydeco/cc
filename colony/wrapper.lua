
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

    if colonyIntegrator == nil then colonyIntegrator = {} end
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

function wrapRemoteColony(colonyNameOrServerId, side)
    local wrapper = {}
    local timeout = 2
    local protocol = "colony"

    -- open rednet
    if not rednet.isOpen(side) then
        error("Rednet not open. Ensure modem exists.")
    end

    -- find colony
    local remote = nil
    if type(colonyNameOrServerId) == "string" then
        remote = rednet.lookup(protocol, colonyNameOrServerId)
        if remote == nil then
            print("Colony not found")
            return nil
        end
    elseif type(colonyNameOrServerId) == "number" then
        remote = colonyNameOrServerId
    elseif colonyNameOrServerId == nil then
        -- valid when no colony is wrapped
    end
    wrapper.remote = remote
    local function remoteCall(functionName, defaultValue)
        return function(arg)
            if wrapper.remote == nil then
                return defaultValue
            end
            local result = defaultValue
            rednet.send(wrapper.remote, {call=functionName, arg=arg}, protocol)
            local _, message = rednet.receive(protocol, timeout)
            if message ~= nil and message.call == functionName then
                result = message.result
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
