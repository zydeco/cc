return function(colony, contentWidth, contentHeight)

local box = UI.Box.new{
    x=0,y=0,w=contentWidth,h=contentHeight,bg=colors.white
}

-- sizes
local margin = 2
local labelX = margin
local labelW = 11
local valueX = labelX + labelW + 1
local valueW = contentWidth - valueX - (2 * margin)
local infoW = contentWidth - (2*margin)
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

box.refresh = box.onShow
return box
end
