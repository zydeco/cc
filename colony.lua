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

local screen = window.create(term.current(), 1,1,26,20)
local tw,th = term.current().getSize()
local w,h = screen.getSize()
local ui = UI.new(screen)
if th > 20 then
    ui.debug = window.create(term.current(), 1,21,tw,1)
end

require("colony/utils")

local statusBarWidth = 8 + digits(os.day())

-- colony name
ui:add(UI.Label.new{
    x=0,y=0,w=w-statusBarWidth,h=1,text=colony.getColonyName(),
    bg=colors.black, fg=colors.white
})

-- date/time
local statusBar = UI.Label.new{
    x=w-statusBarWidth, y=0, w=statusBarWidth, h=1, text=formatTime(), align=UI.RIGHT,
    bg=colors.black, fg=colors.white
}
statusBar.onMouseUp = function()
    ui:stop()
end
ui:add(statusBar)

-- update every 6 game minutes (5 seconds)
-- TODO: accurately
local tabBar = nil
ui:addTimer(5.0, nil, function()
    statusBar.text=formatTime()
    statusBar:redraw()
    if tabBar and tabBar.currentTab and tabBar.currentTab.refresh then
        tabBar.currentTab:refresh()
    end
end)

-- sizes
local contentWidth = w -- 26 on pocket computer
local contentHeight = h-3 -- 17 on pocket computer

tabBar = UI.TabBar.new{x=0,y=1,w=ui.base.w,h=ui.base.h-1,bg=colors.black, tabs={
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
        content=notImplementedView("Requests")
    },
    {
        bg=colors.purple, fg=colors.black,
        key="W", name="Work Orders",
        content=require("colony/work_orders")(colony, contentWidth, contentHeight)
    },
    {
        bg=colors.pink, fg=colors.black,
        key="R", name="Research",
        content=notImplementedView("Research")
    },
    {
        bg=colors.yellow, fg=colors.black,
        key="M", name="Map",
        content=notImplementedView("Map")
    },
}}
ui:add(tabBar)

ui:registerKeyboardShortcut({keys.o}, function() tabBar:selectTab(1) end)
ui:registerKeyboardShortcut({keys.c}, function() tabBar:selectTab(2) end)
ui:registerKeyboardShortcut({keys.v}, function() tabBar:selectTab(3) end)
ui:registerKeyboardShortcut({keys.b}, function() tabBar:selectTab(4) end)
ui:registerKeyboardShortcut({keys.q}, function() tabBar:selectTab(5) end)
ui:registerKeyboardShortcut({keys.w}, function() tabBar:selectTab(6) end)
ui:registerKeyboardShortcut({keys.r}, function() tabBar:selectTab(7) end)
ui:registerKeyboardShortcut({keys.m}, function() tabBar:selectTab(8) end)
ui:registerKeyboardShortcut({keys.e}, function() error("shortcut") end)

ui:run()
