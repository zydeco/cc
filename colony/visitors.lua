require("colony/jobs")
require("colony/utils")

local function getRecruitCostItemName(recruitCost)
    return string.gsub(string.gsub(recruitCost.displayName, "^ +", ""), "[%[%]]", "")
end

local function visitorRow(visitor)
    -- name & happiness
    local line1 = visitor.name .. " " .. formatGender(visitor.gender)

    -- recruit cost
    local itemName = getRecruitCostItemName(visitor.recruitCost)
    local line2 = string.format(" %d{gray}x{fg}%s", visitor.recruitCost.count, itemName)

    local tags = {
        visitor.name,
        "#" .. visitor.gender,
        itemName, 
        "" .. visitor.recruitCost.count,
        "@" .. formatPos(visitor.location),
    }

    -- best jobs
    local jobs = bestJobs(visitor, finalJobs(), 3)
    local line3 = " "
    for index, job in ipairs(jobs) do
        local jobName = translate(job[2], true)
        line3 = line3 .. jobName .. ", "
        table.insert(tags, jobName)
    end

    return {
        text=line1 .. "\n" .. line2 .. "\n" .. line3,
        tags=tags,
        visitor=visitor
    }
end

local function reloadVisitors(colony, filterField, countLabel, visitorList)
    local filterText = string.lower(filterField.text or "")
    local visitors = colony.getVisitors()
    local visibleVisitors = filter(visitors, function(visitor)
        return shouldShowRow(visitorRow(visitor), filterText)
    end)
    visitorList.items = map(visibleVisitors, function(visitor)
        return visitorRow(visitor)
    end)
    visitorList:redraw()

    countLabel.text = string.format("%d/%d", #visibleVisitors, #visitors)
    countLabel:redraw()
end

local function detailForVisitor(visitor)
    local itemName = getRecruitCostItemName(visitor.recruitCost)
    local lines = {
        "{align=center}" .. visitor.name .. " " .. formatGender(visitor.gender),
        string.format("{align=center}%d{gray}x{fg}%s", visitor.recruitCost.count, itemName),
        "{align=center}{gray}" .. formatPos(visitor.location),
        "",
        "  Best jobs:"
    }

    local topJobs = bestJobs(visitor, finalJobs(), 10) or {}
    for _,job in ipairs(topJobs) do
        table.insert(lines, "    " .. formatJobLine(job))
    end

    return lines
end

local function showDetailForVisitor(detailView, visitor)
    detailView.hidden = false
    detailView.visitor = visitor
    detailView.items = detailForVisitor(visitor)
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
local visitorList = UI.List.new{
    x=margin, y=2, w=innerWidth, h=contentHeight - 3,
    fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, showsSelection=false,
    items={}, rowHeight=3
}
box:add(visitorList)

-- help button
box:add(helpButton(contentWidth-4,0,"(?)",function()
    local helpWidth = contentWidth-2
    local helpHeight = contentHeight-2
    local container = UI.Box.new{
        x=1,y=1,w=helpWidth,h=helpHeight,bg=colors.lightGray
    }
    local helpText = UI.Label.new{
        x=1,y=0,w=helpWidth-2,h=helpHeight,bg=colors.lightGray,fg=colors.black,text=
        "\x7f\x7f\x7f\x7f Visitor Row \x7f\x7f\x7f\x7f\x7f\n"..
        " \n"..
        "{bg=lightBlue}Visitor Name          {bg=bg}\n" ..
        "{bg=lightBlue} Recruit cost         {bg=bg}\n" ..
        "{bg=lightBlue} 3 Best jobs          {bg=bg}\n" ..
        " \n"..
        "\x7f\x7f\x7f\x7f\x7f\x7f Filter By \x7f\x7f\x7f\x7f\x7f\n"..
        " \n"..
        " \x04 Name\n"..
        " \x04 Recruit cost item\n"..
        " \x04 Recruit cost amount\n"..
        " \x04 Preferred job\n"..
        " \x04 #male, #female\n" ..
        ""
    }
    container:add(helpText)
    return container
end, visitorList))

local detailView = UI.List.new{
    x=0, y=0, w=contentWidth, h=contentHeight,
    bg=colors.white,
    hidden=true,
    items={}
}
box:add(detailView)

--detailView.onLink = ...

visitorList.onSelect = function(self, index, item)
    if item ~= nil then
        showDetailForVisitor(detailView, item.visitor, colony.getVisitors())
    end
end

box.onShow = function(self)
    detailView.hidden = true
    reloadVisitors(colony, filterField, countLabel, visitorList)
    box:redraw()
end

box.refresh = function(self)
    if detailView.hidden then
        reloadVisitors(colony, filterField, countLabel, visitorList)
    end
end

reloadVisitors(colony, filterField, countLabel, visitorList)

return box
end
