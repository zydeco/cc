local function overviewField(name, value)
    return string.format("%-14s%s", name .. ": ", value)
end

local function overviewText(colony)
    -- general information
    local lines = {
        overviewField("Happiness", string.format("%.2f/10", colony.getHappiness())),
        overviewField("Population", string.format("%d/%d", colony.amountOfCitizens(), colony.maxOfCitizens())),
    }

    -- citizens
    local citizens = colony.getCitizens()
    local children = countMatching(citizens, function(citizen)
        return citizen.age == "child"
    end)
    if children > 0 then
        table.insert(lines, string.format("  {blue}%d children", children))
    end
    local unemployed = countNilValues(citizens, "work")
    if unemployed > 0 then
        table.insert(lines, string.format("  {link=unemployed}{red}%d unemployed", unemployed))
    end
    local homeless = countNilValues(citizens, "home")
    if homeless > 0 then
        table.insert(lines, string.format("  {red}%d homeless", homeless))
    end

    -- visitors
    table.insert(lines, overviewField("Visitors", #colony.getVisitors()))

    -- buildings
    local buildings = colony.getBuildings()
    local numberOfRealBuildings = countMatching(buildings, function(b)
        -- don't count postbox or stash as separate buildings
        return b.type ~= "postbox" and b.type ~= "stash"
    end)
    local numberOfBuiltBuildings = countTrueValues(buildings, "built")
    table.insert(lines, overviewField("Buildings", string.format("%d/%d", numberOfBuiltBuildings, numberOfRealBuildings)))

    -- unguarded
    local numberUnguarded = countMatching(buildings, function(b)
        return b.guarded == false
    end)
    if numberUnguarded > 0 then
        table.insert(lines, string.format("  {link=unguarded}{red}%d unguarded{link=}", numberUnguarded))
    end

    -- under construction
    local numberUnderConstruction = countMatching(buildings, function(b)
        return b.isWorkingOn and not b.built
    end)
    if numberUnderConstruction > 0 then
        table.insert(lines, string.format("  {link=work_orders}{blue}%d under construction{link=}", numberUnderConstruction))
    end

    -- under renovation
    local numberUnderRenovation = countMatching(buildings, function(b)
        return b.isWorkingOn and b.built
    end)
    if numberUnderRenovation > 0 then
        table.insert(lines, string.format("  {link=work_orders}{blue}%d under renovation{link=}", numberUnderRenovation))
    end

    -- work orders
    local workOrders = colony.getWorkOrders()
    local numberOfWorkOrders = countMatching(workOrders, function(order)
        -- do not include mine building
        return order.type ~= "WorkOrderMiner"
    end)
    table.insert(lines, overviewField("Work Orders", numberOfWorkOrders))

    return table.concat(lines, "\n")
end

return function(colony, contentWidth, contentHeight, linkHandler)

local box = UI.Box.new{
    x=0,y=0,w=contentWidth,h=contentHeight,bg=colors.white
}

-- sizes
local margin = 2
local dataLabel = UI.Label.new{
    x=margin, y=1, w=contentWidth - (2*margin), h=(contentHeight - 2),
}
box:add(dataLabel)

dataLabel.onLink = linkHandler
box.onShow = function()
    dataLabel.text = overviewText(colony)
    dataLabel:redraw()
end

box.refresh = box.onShow
return box
end
