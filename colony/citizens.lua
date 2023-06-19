local function getRateColor(rate)
    if rate < 0.4 then
        return "red"
    elseif rate < 0.6 then
        return "orange"
    elseif rate < 0.9 then
        return "green"
    else
        return "blue"
    end
end

local function formatHappiness(value, format)
    return string.format("{%s}%" .. format, getRateColor(value / 10.0), value)
end

local function citizenRow(citizen, width)
    local statusSize = 3
    local name = string.sub(citizen.name, 1, width - statusSize)
    local padSize = width - string.len(name) - statusSize
    local warnIcon = " "
    local happinessIcon = formatHappiness(citizen.happiness, "X")
    local stateIcon = " "
    local lowHealth = citizen.health and citizen.maxHealth and citizen.health < (citizen.maxHealth * 0.1)
    if lowHealth then
        warnIcon = "{red}\x03"
    elseif citizen.homeless then
        warnIcon = "{red}h"
    elseif citizen.betterFood then
        warnIcon = "{red}f"
    end
    if citizen.isAsleep then
        stateIcon = "{gray}z"
    elseif citizen.isIdle then
        stateIcon = "{white}-"
    else
        -- working?
        stateIcon = "{blue}w"
    end
    local line1 = name .. string.rep(" ", padSize) .. warnIcon .. happinessIcon .. stateIcon
    local line2 = ""
    local ageIcon = ""
    if citizen.age ~= "adult" then
        ageIcon = "{gray}" .. citizen.age
    end
    if citizen.work then
        local job = citizen.work.type
        line2 = " " .. job .. " " .. citizen.work.level .. string.rep(" ", width - 3 - string.len(job) - UI.strlen(ageIcon)) .. ageIcon
    else
        line2 = " {red}unemployed" .. string.rep(" ", width - 11 - UI.strlen(ageIcon)) .. ageIcon
    end
    return {
        text=line1 .. "\n" .. line2,
        citizen=citizen.id
    }
end

local function shouldShowCitizen(citizen, filterText)
    return string.find(string.lower(citizen.name), filterText) ~= nil or
    (citizen.work ~= nil and string.find(string.lower(citizen.work.type), filterText) == 1)
end

local function reloadCitizens(colony, filterField, countLabel, citizenList)
    local filterText = string.lower(filterField.text or "")
    local visibleCitizens = filter(colony.getCitizens(), function(citizen)
        return shouldShowCitizen(citizen, filterText)
    end)
    local hasScrollBar = (#visibleCitizens * citizenList.rowHeight) > citizenList.h
    local rowWidth = citizenList.w
    if hasScrollBar then
        rowWidth = citizenList.w - 2
    end
    citizenList.items = map(visibleCitizens, function(citizen)
        return citizenRow(citizen, rowWidth)
    end)
    citizenList:redraw()

    countLabel.text = string.format("%d/%d", #visibleCitizens, colony.amountOfCitizens())
    countLabel:redraw()
end

local function dataField(name, value)
    if name ~= "" then
        name = name .. ": "
    end
    return string.format("%-10s%s", name, value)
end

local function formatHealth(citizen)
    return string.format("{%s}%.2g/%d", getRateColor(citizen.health / citizen.maxHealth), citizen.health, citizen.maxHealth)
end

local function formatBuilding(building)
    return building.type .. " " .. building.level
end

local function worksFromHome(citizen)
    if citizen.work == nil or citizen.home == nil then
        return false
    end
    return sameLocation(citizen.work.location, citizen.home.location)
end

local function getCitizen(citizens, id)
    for index, citizen in ipairs(citizens) do
        if citizen.id == id then
            return citizen
        end
    end
    error("citizen " .. id .. " not found")
end

local function citizenName(citizens, id)
    return getCitizen(citizens, id).name
end

local function getParents(citizens, id)
    local parents = {}
    for index, citizen in ipairs(citizens) do
        if citizen.children and #citizen.children > 0 then
            for index, childId in ipairs(citizen.children) do
                if childId == id then
                    table.insert(parents, citizen)
                end
            end
        end
    end
    return parents
end

local function detailForCitizen(citizenId, citizens, showChildren)
    local citizen = getCitizen(citizens, citizenId)
    local lines = {
        "{align=center}" .. citizen.name,
        "{align=center}{gray}" .. citizen.age .. " " .. citizen.gender,
        "{align=center}{gray}" .. citizen.state .. " " .. formatPos(citizen.location),
        dataField("  Happy", formatHappiness(citizen.happiness, ".2f")),
        dataField("  Health", formatHealth(citizen))
    }

    if citizen.betterFood then
        table.insert(lines, "  {red}needs better food")
    end

    if citizen.homeless then 
        table.insert(lines, "  {red}homeless")
    else
        local home = citizen.home
        table.insert(lines, dataField("  Home", formatBuilding(home)))
        table.insert(lines, dataField("", formatPos(home.location)))
    end

    if citizen.work == nil then
        table.insert(lines, "  {red}unemployed")
    elseif not worksFromHome(citizen) then
        local work = citizen.work
        table.insert(lines, dataField("  Job", formatBuilding(work)))
        table.insert(lines, dataField("", formatPos(work.location)))
    end

    if citizen.armor > 0 then
        table.insert(lines, dataField("  Armour", citizen.armor))
    end
    if citizen.toughness > 0 then
        table.insert(lines, dataField("  Tough", citizen.toughness))
    end

    if #citizen.children > 0 then
        if showChildren then
            table.insert(lines, dataField("  Children", "{link=hideChildren}" .. #citizen.children .. "{link=}"))
            for index, child in ipairs(citizen.children) do
                local childName = citizenName(citizens, child)
                table.insert(lines, "    {link=citizen/" .. child .. "}" .. childName .. "{link=}")
            end
        else
            table.insert(lines, dataField("  Children", "{link=showChildren}" .. #citizen.children .. "{link=}"))
        end
    end

    local parents = getParents(citizens, citizen.id)
    if #parents > 0 then
        table.insert(lines, "  Parents:")
        for index, parent in ipairs(parents) do
            table.insert(lines, "    {link=citizen/" .. parent.id .. "}" .. parent.name .. "{link=}")
        end
    end
    return table.concat(lines, "\n")
end

local function showDetailForCitizen(detailView, citizen, citizens, showChildren)
    detailView.hidden = false
    detailView.citizen = citizen
    detailView.text = detailForCitizen(citizen, citizens, showChildren)
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
local citizenList = UI.List.new{
    x=margin, y=2, w=innerWidth, h=contentHeight - 3,
    fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, bgSelected=colors.blue,
    items={}, rowHeight=2
}
box:add(citizenList)

local detailView = UI.Label.new{
    x=0, y=0, w=contentWidth, h=contentHeight,
    bg=colors.white,
    hidden=true,
}
box:add(detailView)

detailView.onLink = function(self, link)
    if link == "showChildren" then
        showDetailForCitizen(self, detailView.citizen, colony.getCitizens(), true)
    elseif link == "hideChildren" then
        showDetailForCitizen(self, detailView.citizen, colony.getCitizens(), false)
    elseif string.sub(link, 1, 8) == "citizen/" then
        local id = tonumber(string.sub(link, 9))
        showDetailForCitizen(self, id, colony.getCitizens(), false)
    end
end

citizenList.onSelect = function(self, index, item)
    showDetailForCitizen(detailView, item.citizen, colony.getCitizens(), false)
end

box.onShow = function(self)
    self.ui.msg="boxOnShow"
    detailView.hidden = true
    reloadCitizens(colony, filterField, countLabel, citizenList)
    box:redraw()
end

box.refresh = function(self)
    if detailView.hidden then
        reloadCitizens(colony, filterField, countLabel, citizenList)
    end
end

reloadCitizens(colony, filterField, countLabel, citizenList)

return box
end
