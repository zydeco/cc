require("ui")
require("colony/wrapper")

local colony = nil
local args = {...}
local externalMonitor = nil
local monitorScale = 1.0
local remoteColonyName = nil
local modemSide = "back"

-- parse arguments
if #args > 0 then
    for _, arg in ipairs(args) do
        if string.sub(arg, 1, 2) == "--" then
            -- named argument
            local equals = string.find(arg, "=")
            local argName = string.sub(arg, 3, equals-1)
            local argValue = string.sub(arg, equals+1, -1)
            if argName == "modem" then
                -- modem side
                modemSide = argValue
            elseif argName == "remote" then
                -- remote colony
                remoteColonyName = argValue
            elseif argName == "monitor" then
                -- external monitor
                externalMonitor = argValue
            elseif argName == "scale" then
                -- external monitor scale
                monitorScale = tonumber(argValue) or 1.0
            end
        else
            -- stub
            require("colony/stubs/" .. args[1])
            colony = COLONY_STUB
        end
    end
end

-- find colony
if colony == nil then
    if remoteColonyName ~= nil then
        colony = wrapRemoteColony(remoteColonyName, modemSide)
    else
        colony = peripheral.find("colonyIntegrator")
        if colony == nil then
            print("No colony integrator")
            return 1
        end
        colony = wrapColony(colony)
    end
end

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

if externalMonitor ~= nil then
    base = ui:attachMonitor(externalMonitor, monitorScale)
    w,h = base.w, base.h
end

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

local openTabAndSearch = function(tabIndex, search)
    tabBar:selectTab(tabIndex)
    if search ~= nil and tabBar.currentTab.search then
        tabBar.currentTab.search(search)
    end
end

local openTabAndShowDetail = function(tabIndex, subId)
    tabBar:selectTab(tabIndex)
    if subId ~= nil and tabBar.currentTab.showDetailById then
        tabBar.currentTab.showDetailById(subId)
    end
end

local TAB_CITIZENS = 2
local TAB_BUILDINGS = 4
local TAB_WORK_ORDERS = 6

local handleLink = function(view, link)
    if link == "unguarded" then
        openTabAndSearch(TAB_BUILDINGS, "#unguarded")
    elseif link == "unbuilt" then
        openTabAndSearch(TAB_BUILDINGS, "#unbuilt")
    elseif link == "unemployed" then
        openTabAndSearch(TAB_CITIZENS, "#unemployed")
    elseif link == "work_orders" then
        openTabAndSearch(TAB_WORK_ORDERS)
    elseif string.sub(link, 1, 8) == "citizen/" then
        local subId = tonumber(string.sub(link, 9))
        openTabAndShowDetail(TAB_CITIZENS, subId)
    elseif string.sub(link, 1, 9) == "building/" then
        local subId = string.sub(link, 10)
        openTabAndShowDetail(TAB_BUILDINGS, subId)
    elseif string.sub(link, 1, 12) == "work_orders/" then
        local query = string.sub(link, 13)
        openTabAndSearch(TAB_WORK_ORDERS, query)
    end
end

-- sizes
local contentWidth = w -- 26 on pocket computer
local contentHeight = h-3 -- 17 on pocket computer

tabBar = UI.TabBar.new{x=0,y=1,w=w,h=h-1,bg=colors.black, tabs={
    {
        bg=colors.lightGray, fg=colors.black,
        key="O", name="Overview",
        content=require("colony/overview")(colony, contentWidth, contentHeight, handleLink)
    },
    {
        bg=colors.lime, fg=colors.black,
        key="C", name="Citizens",
        content=require("colony/citizens")(colony, contentWidth, contentHeight, handleLink)
    },
    {
        bg=colors.green, fg=colors.black,
        key="V", name="Visitors",
        content=require("colony/visitors")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.orange, fg=colors.black,
        key="B", name="Buildings",
        content=require("colony/buildings")(colony, contentWidth, contentHeight, handleLink)
    },
    {
        bg=colors.cyan, fg=colors.black,
        key="Q", name="Requests",
        content=require("colony/requests")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.purple, fg=colors.black,
        key="W", name="Work Orders",
        content=require("colony/work_orders")(colony, contentWidth, contentHeight, handleLink)
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
