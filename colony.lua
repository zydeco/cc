require("ui")

local colony = nil
local args = {...}
if #args == 1 then
    require("colony/stubs/" .. args[1])
    colony = COLONY_STUB
else
    colony = peripheral.find("colonyIntegrator")
    if colony == nil then
        print("No colony integrator")
        return 1
    end
end

local function wrapColony(colonyIntegrator)
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

colony = wrapColony(colony)

local screen = term.current()
local tw,th = term.current().getSize()
local w,h = screen.getSize()
if th > 20 then
    screen = window.create(term.current(), 1,1,tw,th-1)
    h = th - 1
end
local ui = UI.new(screen)
local base = ui.base

if th > 20 then
    ui.debug = window.create(term.current(), 1,th,tw,1)
end

--base = ui:attachMonitor("left", 1.0)
--w,h = base.w, base.h

require("colony/utils")

local statusBarWidth = 8 + digits(os.day())

-- colony name
local nameLabel = UI.Label.new{
    x=0,y=0,w=w-statusBarWidth,h=1,text=colony.getColonyName(),
    bg=colors.black, fg=colors.white
}
base:add(nameLabel)

-- date/time
local statusBar = UI.Label.new{
    x=w-statusBarWidth, y=0, w=statusBarWidth, h=1, text=formatTime(), align=UI.RIGHT,
    bg=colors.black, fg=colors.white
}
statusBar.onMouseUp = function()
    ui:stop()
end
statusBar.onTouch = statusBar.onMouseUp
base:add(statusBar)

-- update every 6 game minutes (5 seconds)
-- TODO: accurately
local tabBar = nil
ui:addTimer(5.0, nil, function()
    local newName = colony.getColonyName()
    if newName ~= nameLabel.text then
        nameLabel.text = newName
        nameLabel:redraw()
    end
    statusBar.text = formatTime()
    statusBar:redraw()
    if tabBar and tabBar.currentTab and tabBar.currentTab.refresh then
        tabBar.currentTab:refresh()
    end
end)

-- sizes
local contentWidth = w -- 26 on pocket computer
local contentHeight = h-3 -- 17 on pocket computer

tabBar = UI.TabBar.new{x=0,y=1,w=w,h=h-1,bg=colors.black, tabs={
    {
        bg=colors.lightGray, fg=colors.black,
        key="O", name="Overview",
        content=require("colony/overview")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.lime, fg=colors.black,
        key="C", name="Citizens",
        content=require("colony/citizens")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.green, fg=colors.black,
        key="V", name="Visitors",
        content=require("colony/visitors")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.orange, fg=colors.black,
        key="B", name="Buildings",
        content=require("colony/buildings")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.cyan, fg=colors.black,
        key="Q", name="Requests",
        content=require("colony/requests")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.purple, fg=colors.black,
        key="W", name="Work Orders",
        content=require("colony/work_orders")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.pink, fg=colors.black,
        key="R", name="Research",
        content=require("colony/research")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.yellow, fg=colors.black,
        key="M", name="Map",
        content=notImplementedView("Map")
    },
}}
base:add(tabBar)

ui:registerKeyboardShortcut({keys.o}, function() tabBar:selectTab(1) end)
ui:registerKeyboardShortcut({keys.c}, function() tabBar:selectTab(2) end)
ui:registerKeyboardShortcut({keys.v}, function() tabBar:selectTab(3) end)
ui:registerKeyboardShortcut({keys.b}, function() tabBar:selectTab(4) end)
ui:registerKeyboardShortcut({keys.q}, function() tabBar:selectTab(5) end)
ui:registerKeyboardShortcut({keys.w}, function() tabBar:selectTab(6) end)
ui:registerKeyboardShortcut({keys.r}, function() tabBar:selectTab(7) end)
ui:registerKeyboardShortcut({keys.m}, function() tabBar:selectTab(8) end)

ui:run()
