local function canHasCitizens(buildingType)
    -- town hall can't employ/house anyone, so it's ok to have 0 citizens
    return buildingType ~= "townhall"
end

local function maxCitizens(building)
    local type = building.type
    if not building.built then
        -- unbuilt buildings can't have citizens
        return 0
    elseif type == "townhall" or type == "barracks" or type == "mysticalsite" then
        -- uninhabited
        return 0
    elseif type == "residence" or type == "barrackstower" or type == "university" or type == "combatacademy" or type == "archery" then
        -- # of residents/researchers
        return building.level
    elseif type == "cook" then
        -- ass cook at lvl 3
        if building.level >= 3 then
            return 2
        else
            return 1
        end
    elseif type == "school" then
        -- teacher + students
        return 1 + (building.level * 2)
    elseif type == "library" or type == "warehouse" then
        return building.level * 2
    elseif type == "tavern" then
        -- max 4 residents
        return 4
    else
        -- one worker
        return 1
    end
end

local function isResidence(buildingType)
    return buildingType == "residence" or buildingType == "tavern"
end

local function buildingRow(building, width)
    local statusSize = 3
    local name = formatBuilding(building, width - (1 + statusSize))
    local padSize = width - string.len(name) - statusSize
    -- status = guarded + built + workingOn
    local status = ""
    if building.guarded then
        status = status .. "{green}G"
    else
        status = status .. "{red}g"
    end
    if building.built then
        status = status .. "{green}B"
    else
        status = status .. "{white}b"
    end
    if building.isWorkingOn then
        status = status .. "{orange}W"
    else
        status = status .. " "
    end
    local line1 = name .. string.rep(" ", padSize) .. status
    local pos = formatPos(building.location)
    local citizens = "" .. #building.citizens
    if #building.citizens < maxCitizens(building) then
        citizens = "{red}" .. citizens
    elseif #building.citizens == 0 then
        citizens = ""
    end
    local line2 = " " .. pos .. string.rep(" ", width - 2 - string.len(pos) - UI.strlen(citizens)) .. citizens
    return {
        text=line1 .. "\n" .. line2,
        building=building
    }
end

local function shouldShowBuilding(building, filterText)
    return string.find(string.lower(translate(building.name)), filterText) ~= nil
end

local function reloadBuildings(colony, filterField, countLabel, buildingList)
    local filterText = string.lower(filterField.text or "")
    local buildings = filter(colony.getBuildings(), function (b)
        -- don't count postbox or stash as separate buildings
        return b.type ~= "postbox" and b.type ~= "stash"
    end)
    local visibleBuildings = filter(buildings, function(building)
        return shouldShowBuilding(building, filterText)
    end)
    local hasScrollBar = (#visibleBuildings * buildingList.rowHeight) > buildingList.h
    local rowWidth = buildingList.w
    if hasScrollBar then
        rowWidth = buildingList.w - 2
    end
    buildingList.items = map(visibleBuildings, function(building)
        return buildingRow(building, rowWidth)
    end)
    buildingList:redraw()

    countLabel.text = string.format("%d/%d", #visibleBuildings, #buildings)
    countLabel:redraw()
end

local function detailForBuilding(building)
    local lines = {
        " ",
        "{align=center}" .. translate(building.name) .. " " .. building.level,
        "{align=center}{gray}" .. building.style,
        "{align=center}{gray}" .. formatPos(building.location),
    }

    if not building.guarded then
        table.insert(lines, "{align=center}{red}not guarded")
    end

    if building.isWorkingOn then
        if building.built then
            table.insert(lines, "{align=center}{blue}upgrading...")
        else
            table.insert(lines, "{align=center}{blue}under construction")
        end
    end

    table.insert(lines, " ")

    table.insert(lines, "  Storage: " .. building.storageBlocks .. "b (" .. building.storageSlots .. ")")
    if building.built and #building.citizens == 0 and canHasCitizens(building.type) then
        if isResidence(building.type) then
            table.insert(lines, "  {align=center}{red}no residents")
        else
            table.insert(lines, "  {align=center}{red}no workers")
        end
    elseif #building.citizens > 0 then
        if isResidence(building.type) then
            table.insert(lines, "  Residents:")
        else
            table.insert(lines, "  Workers:")
        end
        for index, citizen in ipairs(building.citizens) do
            table.insert(lines, "    {link=citizen/" .. citizen.id .. "}" .. citizen.name .. "{link=}")
        end
    end

    return table.concat(lines, "\n")
end

local function showDetailForBuilding(detailView, building)
    detailView.hidden = false
    detailView.building = building
    detailView.text = detailForBuilding(building)
    detailView:redraw()
end

return function(colony, contentWidth, contentHeight)

local box = UI.Box.new{
    x=0,y=0,w=contentWidth,h=contentHeight,bg=colors.white
}

-- sizes
local margin = 1
local innerWidth = contentWidth - (2*margin)

-- filter
local filterField = UI.Field.new{
    x=margin, y=1, w=innerWidth - 5, h=1,
    placeholder={
        text="Filter",
        color=colors.gray
    },
    bg=colors.lightGray, fg=colors.black,
    onChange=function(self)
        box:onShow()
    end
}
box:add(filterField)

local countLabel = UI.Label.new{
    x=margin + innerWidth - 5, y=1, w=5, h=1,
    bg=colors.lightGray, fg=colors.gray,
    align=UI.RIGHT,
    text="0/0"
}
box:add(countLabel)

-- list
local buildingList = UI.List.new{
    x=margin, y=2, w=innerWidth, h=contentHeight - 3,
    fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, bgSelected=colors.blue,
    items={}, rowHeight=2
}
box:add(buildingList)

local detailView = UI.Label.new{
    x=0, y=0, w=contentWidth, h=contentHeight,
    bg=colors.white,
    hidden=true,
}
box:add(detailView)

detailView.onLink = function(self, link)
    
end

buildingList.onSelect = function(self, index, item)
    showDetailForBuilding(detailView, item.building)
end

box.onShow = function(self)
    self.ui.msg="boxOnShow"
    detailView.hidden = true
    reloadBuildings(colony, filterField, countLabel, buildingList)
    box:redraw()
end

box.refresh = function(self)
    if detailView.hidden then
        reloadBuildings(colony, filterField, countLabel, buildingList)
    end
end

reloadBuildings(colony, filterField, countLabel, buildingList)

return box

end