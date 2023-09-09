require("colony/jobs")
require("colony/utils")

local function formatHappiness(value, format)
    if format == "X" and value == 10.0 then
        return "{purple}\x02"
    end
    return string.format("{%s}%" .. format, getRateColor(value / 10.0), value)
end


local function formatWork(work, width)
    return formatWithLevel(translate(work.job or work.name), work.level, width)
end

local function citizenRow(citizen, width)
    local statusSize = 3
    local name = string.sub(citizen.name, 1, width - statusSize)
    local padSize = width - string.len(name) - statusSize
    local warnIcon = " "
    local happinessIcon = formatHappiness(citizen.happiness, "X")
    local stateIcon = " "
    local lowHealth = citizen.health and citizen.maxHealth and citizen.health < (citizen.maxHealth * 0.1)
    local homeless = citizen.home == nil
    local tags = {citizen.name, "#" .. citizen.age, "#" .. citizen.gender}
    if lowHealth then
        warnIcon = "{red}\x03"
    elseif homeless then
        warnIcon = "{red}h"
        table.insert(tags, "#homeless")
    elseif citizen.betterFood then
        warnIcon = "{red}f"
        table.insert(tags, "#hungry")
    end
    if citizen.isAsleep then
        stateIcon = "{gray}z"
        table.insert(tags, "#asleep")
    elseif citizen.isIdle then
        stateIcon = "{white}-"
        table.insert(tags, "#idle")
        table.insert(tags, "#awake")
    else
        -- working?
        stateIcon = "{blue}w"
        table.insert(tags, "#working")
        table.insert(tags, "#awake")
    end
    local line1 = name .. string.rep(" ", padSize) .. warnIcon .. happinessIcon .. stateIcon
    local line2 = ""
    local ageIcon = ""
    if citizen.age ~= "adult" then
        ageIcon = "{gray}" .. citizen.age
    end
    if citizen.work then
        local jobName = translate(citizen.work.job or citizen.work.name)
        local job = formatWork(citizen.work, width - 2 - UI.strlen(ageIcon))
        local jobPrefix = " "
        if hasBestJob(citizen) then
            jobPrefix = "{blue}\x03{fg}"
        end
        line2 = jobPrefix .. job .. string.rep(" ", width - 1 - string.len(job) - UI.strlen(ageIcon)) .. ageIcon
        table.insert(tags, jobName)
        table.insert(tags, "" .. citizen.work.level)
        table.insert(tags, "@" .. formatPos(citizen.work.location))
    else
        line2 = " {red}unemployed" .. string.rep(" ", width - 11 - UI.strlen(ageIcon)) .. ageIcon
        table.insert(tags, "#unemployed")
    end
    if citizen.bedPos then
        table.insert(tags, "@" .. formatPos(citizen.bedPos))
    end
    if citizen.home then
        table.insert(tags, "@" .. formatPos(citizen.home.location))
    end
    if citizen.location then
        table.insert(tags, "@" .. formatPos(citizen.location))
    end
    return {
        text=line1 .. "\n" .. line2,
        tags=tags,
        citizen=citizen.id
    }
end

local function reloadCitizens(colony, filterField, countLabel, citizenList, sortOrder)
    local filterText = string.lower(filterField.text or "")
    local rowWidth = citizenList.w
    local visibleCitizens = filter(colony.getCitizens(), function(citizen)
        return shouldShowRow(citizenRow(citizen, rowWidth), filterText)
    end)
    local hasScrollBar = (#visibleCitizens * citizenList.rowHeight) > citizenList.h
    if hasScrollBar then
        rowWidth = citizenList.w - 1
    end
    sortListBy(visibleCitizens, sortOrder.by, sortOrder.ascending)
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
    if string.sub(value, 1, 6) == "{link=" then
        return string.format("%-9s%s", name, value)
    else
        return string.format("%-10s%s", name, value)
    end
end

local function formatHealth(citizen)
    return string.format("{%s}%.2g/%d", getRateColor(citizen.health / citizen.maxHealth), citizen.health, citizen.maxHealth)
end

local function worksFromHome(citizen)
    if citizen.work == nil or citizen.home == nil then
        return false
    end
    return sameLocation(citizen.work.location, citizen.home.location)
end

local function getCitizen(citizens, id)
    return getById(citizens, id)
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

local function detailForCitizen(citizenId, citizens, state, colony)
    local citizen = getCitizen(citizens, citizenId)
    local homeless = citizen.home == nil
    local lines = {
        "{align=center}" .. citizen.name,
        "{align=center}{gray}" .. citizen.age .. " " .. citizen.gender,
        "{align=center}{gray}" .. citizen.state,
        "{align=center}{gray}" .. formatPos(citizen.location),
        dataField("  Happy", formatHappiness(citizen.happiness, ".2f")),
        dataField("  Health", formatHealth(citizen))
    }

    if citizen.betterFood then
        table.insert(lines, "  {red}needs better food")
    end

    if homeless then 
        table.insert(lines, dataField("  Home", "{red}none"))
    elseif not worksFromHome(citizen) then
        local home = citizen.home
        table.insert(lines, dataField("  Home", "{link=building/" .. formatPos(home.location) .. "}\xbb" .. formatBuilding(home, 16) .. "{link=}"))
        table.insert(lines, dataField("", formatPos(home.location)))
    end

    if citizen.work == nil then
        table.insert(lines, dataField("  Job", "{red}none"))
    else
        local work = citizen.work
        table.insert(lines, dataField("  Job", formatWork(work, 16)))
        table.insert(lines, dataField("", "{link=building/" .. formatPos(work.location) .. "}\xbb" .. translate(work.name) .. "{link=}"))
        table.insert(lines, dataField("", formatPos(work.location)))
        if not homeless then
            local commute = distance(citizen.home.location, work.location)
            local commuteGrade = "green"
            if commute > 160 then
                commuteGrade = "red"
            elseif commute > 100 then
                commuteGrade = "orange"
            elseif commute < 50 then
                commuteGrade = "blue"
            end
            if math.floor(commute) > 0 then
                table.insert(lines, dataField("", string.format("{%s}%db from home", commuteGrade, commute)))
            end
        end
        if work.type == "builder" then
            local workOrders = filter(colony.getWorkOrders(), function(order)
                return sameLocation(order.builder, work.location)
            end)
            local plural = ""
            if #workOrders > 1 then plural = "s" end
            table.insert(lines, dataField("", string.format("{link=work_orders/%s}\xbb%d work order%s{link=}", citizen.name, #workOrders, plural)))
        end
    end

    local topJobs = bestJobs(citizen, nil, 5) or {}
    if #topJobs == 1 then
        table.insert(lines, "  Best:   " .. translate(topJobs[1][2], true))
    else
        if state.showBestJobs then
            table.insert(lines, "  {link=hideBestJobs}Best jobs \x1f{link=}")
            for _,job in ipairs(topJobs) do
                table.insert(lines, "    " .. formatJobLine(job))
            end
        else
            table.insert(lines, "  {link=showBestJobs}Best jobs \x10{link=}")
        end
    end

    if citizen.armor > 0 then
        table.insert(lines, dataField("  Armour", citizen.armor))
    end
    if citizen.toughness > 0 then
        table.insert(lines, dataField("  Tough", citizen.toughness))
    end

    if #citizen.children > 0 then
        if state.showChildren then
            table.insert(lines, dataField("  Children", "{link=hideChildren}" .. #citizen.children .. " \x1f{link=}"))
            for index, child in ipairs(citizen.children) do
                local childName = citizenName(citizens, child)
                table.insert(lines, "   {link=citizen/" .. child .. "}\xbb" .. childName .. "{link=}")
            end
        else
            table.insert(lines, dataField("  Children", "{link=showChildren}" .. #citizen.children .. " \x10{link=}"))
        end
    end

    local parents = getParents(citizens, citizen.id)
    if #parents > 0 then
        table.insert(lines, "  Parents:")
        for index, parent in ipairs(parents) do
            table.insert(lines, "   {link=citizen/" .. parent.id .. "}\xbb" .. parent.name .. "{link=}")
        end
    end
    return lines
end

local function showDetailForCitizen(detailView, citizen, citizens, colony)
    detailView.hidden = false
    detailView.citizen = citizen
    detailView.items = detailForCitizen(citizen, citizens, detailView.state, colony)
    detailView:redraw()
end

return function(colony, contentWidth, contentHeight, linkHandler)

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
    end,
    clearButton=true
}
box:add(filterField)
box.search = function(filter) filterField:setText(filter) end

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
    fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, showsSelection=false,
    items={}, rowHeight=2
}
box:add(citizenList)

-- sorting
local sortOrder = {
    ascending = true
}
local sortMenu = makeSortMenu(
    sortOrder,
    {
        { text="ID", sortKey = "id" },
        { text="Name", sortKey = "name" },
        { text="Health", sortKey = "health" },
        { text="Happiness", sortKey = "happiness" },
        { text="Job", sortKey = function(citizen)
            if citizen.work then
                return translate(citizen.work.job or citizen.work.name)
            else
                return ""
            end
        end},
        { text="Level", sortKey = function(citizen)
            if citizen.work then
                return citizen.work.level
            else
                return 0
            end
        end},
        { text="Age", sortKey = function(citizen)
            if citizen.age == "adult" then
                return 36
            else
                return 10
            end
        end},
        { text="State", sortKey = "state" },
    },
    function()
        reloadCitizens(colony, filterField, countLabel, citizenList, sortOrder)
        citizenList:redraw()
    end,
    21
)
box:add(sortMenu)

-- help button
box:add(helpButton(contentWidth-4,0,"(?)",function()
    local helpWidth = contentWidth-2
    local helpHeight = contentHeight-2
    local container = UI.Box.new{
        x=1,y=1,w=helpWidth,h=helpHeight,bg=colors.lightGray
    }
    local helpText = UI.Label.new{
        x=1,y=0,w=helpWidth-2,h=helpHeight,bg=colors.lightGray,fg=colors.black,text=
        "\x7f\x7f\x7f\x7f Citizen Row \x7f\x7f\x7f\x7f\x7f\n"..
        "{bg=lightBlue}Citizen Name       {red}1{blue}2{gray}3{bg=bg}\n" ..
        "{bg=lightBlue}{blue}\x03{black}Job & Level          {bg=bg}\n" ..
        "1: {red}\x03{fg} Low health\n"..
        "   {red}h{fg} Homeless\n"..
        "   {red}f{fg} Need better food\n"..
        "2: Happiness {red}0{gray}\xad{orange}4{gray}\xad{blue}6{gray}\xad{purple}9\x02{fg}\n"..
        "3: {gray}z{fg} Sleeping, {white}-{fg} Idle\n   {blue}w{fg} Working\n"..
        "{blue}\x03{fg}= Has best job\n"..
        "\n"..
        "\x7f\x7f\x7f\x7f\x7f\x7f Filter By \x7f\x7f\x7f\x7f\x7f\n"..
        " \x04 Name, Job, Level\n"..
        " #child #adult #awake\n"..
        " #homeless #unemployed\n"..
        " #hungry #asleep #idle\n"..
        ""
    }
    container:add(helpText)
    return container
end, citizenList))

local detailView = UI.List.new{
    x=0, y=0, w=contentWidth, h=contentHeight,
    bg=colors.white,
    hidden=true,
    items={}
}
detailView.state = {}
box:add(detailView)

detailView.onLink = function(self, link)
    local id = detailView.citizen
    local state = detailView.state
    if link == "showChildren" then
        state.showChildren = true
    elseif link == "hideChildren" then
        state.showChildren = false
    elseif link == "showBestJobs" then
        state.showBestJobs = true
    elseif link == "hideBestJobs" then
        state.showBestJobs = false
    elseif string.sub(link, 1, 8) == "citizen/" then
        id = tonumber(string.sub(link, 9))
        detailView.state = {}
    else
        linkHandler(self, link)
        return
    end
    showDetailForCitizen(self, id, colony.getCitizens(), colony)
end

box.showDetailById = function(id)
    detailView.state = {}
    showDetailForCitizen(detailView, id, colony.getCitizens(), colony)
end

citizenList.onSelect = function(self, index, item)
    if item ~= nil then
        showDetailForCitizen(detailView, item.citizen, colony.getCitizens(), colony)
    end
end

box.onShow = function(self)
    self.ui.msg="boxOnShow"
    detailView.hidden = true
    reloadCitizens(colony, filterField, countLabel, citizenList, sortOrder)
    box:redraw()
end

box.refresh = function(self)
    if detailView.hidden then
        reloadCitizens(colony, filterField, countLabel, citizenList, sortOrder)
    end
end

reloadCitizens(colony, filterField, countLabel, citizenList, sortOrder)

return box
end
