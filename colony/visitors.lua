require("colony/jobs")
require("colony/utils")

local function visitorRow(visitor)
    -- name & happiness
    local line1 = visitor.name

    -- recruit cost
    local itemName =  string.gsub(string.gsub(visitor.recruitCost.displayName, "^ +", ""), "[%[%]]", "")
    local line2 = string.format(" %d{gray}x{fg}%s", visitor.recruitCost.count, itemName)

    local filterable = {
        visitor.name,
        itemName, 
        "" .. visitor.recruitCost.count
    }

    -- best jobs
    local jobs = bestJobs(visitor, finalJobs(), 3)
    local line3 = " "
    for index, job in ipairs(jobs) do
        local jobName = translate(job[2])
        line3 = line3 .. jobName .. ", "
        table.insert(filterable, jobName)
    end

    return {
        text=line1 .. "\n" .. line2 .. "\n" .. line3,
        filterable=filterable,
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
    local lines = {
        "{align=center}" .. visitor.name,
        "{align=center}{gray}" .. visitor.age .. " " .. visitor.gender,
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
local visitorList = UI.List.new{
    x=margin, y=2, w=innerWidth, h=contentHeight - 3,
    fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, bgSelected=colors.blue,
    items={}, rowHeight=3
}
box:add(visitorList)

local detailView = UI.List.new{
    x=0, y=0, w=contentWidth, h=contentHeight,
    bg=colors.white,
    hidden=true,
    items={}
}
box:add(detailView)

--detailView.onLink = ...

visitorList.onSelect = function(self, index, item)
    showDetailForVisitor(detailView, item.visitor, colony.getVisitors())
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
