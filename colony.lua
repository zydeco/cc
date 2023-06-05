require("ui")

local colony = nil
local args = {...}
if #args == 1 then
    require("colonyStubs/" .. args[1])
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
ui.debug = window.create(term.current(), 1,21,tw,1)

local function notImplementedView(name)
    return UI.Label.new{
        x=0,y=0,w=30,h=3,
        bg=colors.white, fg=colors.red,
        text=name .. " not implemented",
    }
end

local function formatTime()
    return string.format("d%dt%04.1f", os.day(), os.time())
end

local function digits(n)
    return 1 + math.floor(math.log(n, 10))
end

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
    if tabBar and tabBar.currentTab and tabBar.currentTab.onShow then
        tabBar.currentTab:onShow()
    end
end)

-- sizes
local contentWidth = w -- 26 on pocket computer
local contentHeight = h-3 -- 17 on pocket computer

local function filter(list, keep)
    local filtered = {}
    for i=1,#list do
        if keep(list[i]) then
            filtered[#filtered] = list[i]
        end
    end
    return filtered
end

local function countMatching(list, matcher)
    local n = 0
    for i=1,#list do
        if matcher(list[i]) then
            n = n + 1
        end
    end
    return n
end

local function countNilValues(list, key)
    return countMatching(list, function(x)
        return x[key] == nil
    end)
end

local function countTrueValues(list, key)
    return countMatching(list, function(x)
        return x[key]
    end)
end

-- overview view
local function overview(colony)
    local box = UI.Box.new{
        x=0,y=0,w=contentWidth,h=contentHeight,bg=colors.white
    }

    -- sizes
    local margin = 2
    local labelX = margin
    local labelW = 11
    local valueX = labelX + labelW + 1
    local valueW = contentWidth - valueX - (2 * margin)
    local infoW = w - (2*margin)
    local y = 1

    -- happiness
    box:add(UI.Label.new{x=labelX, y=y, text="Happiness:"})
    local happinessValue = UI.Label.new{x=valueX, y=y, w=valueW, text="n/a"}
    box:add(happinessValue)

    -- population
    box:add(UI.Label.new{x=labelX, y=y+1, text="Population:"})
    local populationValue = UI.Label.new{x=valueX, y=y+1, w=valueW, text="n/a"}
    box:add(populationValue)

    -- unemployed
    local unemployedValue = UI.Label.new{x=labelX+2, y=y+2, w=infoW, fg=colors.red}
    box:add(unemployedValue)

    -- homeless
    local homelessValue = UI.Label.new{x=labelX+2, y=y+3, w=infoW, fg=colors.red}
    box:add(homelessValue)

    -- visitors
    box:add(UI.Label.new{x=labelX, y=y+4, text="Visitors:"})
    local visitorsValue = UI.Label.new{x=valueX, y=y+4, w=valueW, text="n/a"}
    box:add(visitorsValue)

    -- buildings
    box:add(UI.Label.new{x=labelX, y=y+5, text="Buildings:"})
    local buildingsValue = UI.Label.new{x=valueX, y=y+5, w=valueW, text="n/a"}
    box:add(buildingsValue)

    -- under construction
    local underConstructionValue = UI.Label.new{x=labelX+2, y=y+6, w=infoW, fg=colors.blue}
    box:add(underConstructionValue)

    -- under renovation
    local underRenovationValue = UI.Label.new{x=labelX+2, y=y+7, w=infoW, fg=colors.blue}
    box:add(underRenovationValue)
    
    -- work orders
    local workOrdersValue = UI.Label.new{x=labelX, y=y+8, w=infoW, fg=colors.green}
    box:add(workOrdersValue)

    box.onShow = function()
        -- update values
        happinessValue.text = string.format("%.2f/10", colony.getHappiness())
        populationValue.text = string.format("%d/%d", colony.amountOfCitizens(), colony.maxOfCitizens())
        local citizens = colony.getCitizens()
        local unemployed = countNilValues(citizens, "work")
        unemployedValue.text = string.format("%d unemployed", unemployed)
        unemployedValue.hidden = (unemployed == 0)
        local homeless = countNilValues(citizens, "home")
        homelessValue.text = string.format("%d homeless", homeless)
        homelessValue.hidden = (homeless == 0)
        if unemployedValue.hidden and not homelessValue.hidden then
            homelessValue.y = unemployedValue.y
        else
            homelessValue.y = unemployedValue.y + 1
        end
        visitorsValue.text = string.format("%d", #colony.getVisitors())
        local buildings = colony.getBuildings()
        local realBuildings = countMatching(buildings, function(b)
            -- don't count postbox or stash as separate buildings
            return b.type ~= "postbox" and b.type ~= "stash"
        end)
        buildingsValue.text = string.format("%d/%d", countTrueValues(buildings, "built"), realBuildings)

        -- buildings under construction
        local underConstruction = countMatching(buildings, function(b)
            return b.isWorkingOn and not b.built
        end)
        underConstructionValue.text = string.format("%d under construction", underConstruction)
        underConstructionValue.hidden = (underConstruction == 0)

        -- buildings under renovation
        local underRenovation = countMatching(buildings, function(b)
            return b.isWorkingOn and b.built
        end)
        underRenovationValue.text = string.format("%d under renovation", underRenovation)
        underRenovationValue.hidden = (underRenovation == 0)
        if underConstructionValue.hidden then
            underRenovationValue.y = underConstructionValue.y
        else
            underRenovationValue.y = underConstructionValue.y + 1
        end

        local workOrders = colony.getWorkOrders()
        workOrdersValue.text = string.format("%d work orders", countMatching(workOrders, function(order)
            -- do not include mine building
            return order.type ~= "WorkOrderMiner"
        end))
        workOrdersValue.hidden = (#workOrders == 0)
        box:redraw()
    end
    return box
end

tabBar = UI.TabBar.new{x=0,y=1,w=ui.base.w,h=ui.base.h-1,bg=colors.black, tabs={
    {
        bg=colors.lightGray, fg=colors.black,
        key="O", name="Overview",
        content=overview(colony)
    },
    {
        bg=colors.lime, fg=colors.black,
        key="C", name="Citizens",
        content=UI.Label.new({
            x=0,y=0,w=20,h=2,
            text="This is the citizens",
        })
    },
    {
        bg=colors.orange, fg=colors.black,
        key="B", name="Buildings",
        content=notImplementedView("Buildings")
    },
    {
        bg=colors.pink, fg=colors.black,
        key="R", name="Requests",
        content=notImplementedView("Requests")
    },
    {
        bg=colors.purple, fg=colors.black,
        key="W", name="Work Orders",
        content=notImplementedView("Work Orders")
    },
    {
        bg=colors.cyan, fg=colors.black,
        key="E", name="Employment",
        content=notImplementedView("Employment")
    },
    {
        bg=colors.green, fg=colors.black,
        key="H", name="Housing",
        content=notImplementedView("Housing")
    },
    {
        bg=colors.yellow, fg=colors.black,
        key="M", name="Map",
        content=notImplementedView("Map")
    },
}}
ui:add(tabBar)

ui:run()
