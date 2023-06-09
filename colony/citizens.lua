local function citizenRow(citizen, width)
    local statusSize = 2
    local name = string.sub(citizen.name, 1, width - statusSize)
    local padSize = width - string.len(name) - statusSize
    local warnIcon = " "
    local stateIcon = " "
    local lowHealth = citizen.health and citizen.maxHealth and citizen.health < (citizen.maxHealth * 0.1)
    if lowHealth then
        warnIcon = "{red}!"
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
    local line1 = name .. string.rep(" ", padSize) .. warnIcon .. stateIcon
    local line2 = ""
    local ageIcon = "{gray}" .. citizen.age
    if citizen.work then
        local job = citizen.work.type
        line2 = " " .. job .. " " .. citizen.work.level .. string.rep(" ", width - 3 - string.len(job) - UI.strlen(ageIcon)) .. ageIcon
    else
        line2 = " {red}unemployed" .. string.rep(" ", width - 11 - UI.strlen(ageIcon)) .. ageIcon
    end
    return {
        text=line1 .. "\n" .. line2,
        citizen=citizen
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

function createDetailView(detailView)
    local contentWidth = detailView.w
    local contentHeight = detailView.h
    detailView.nameLabel = UI.Label.new{
        x=0, y=0, w=contentWidth, align=UI.CENTER
    }
    detailView:add(detailView.nameLabel)
end

function showDetailForCitizen(detailView, citizen)
    detailView.hidden = false
    if #detailView.subviews == 0 then
        createDetailView(detailView)
    end
    detailView.nameLabel.text = citizen.name
    detailView.parent:redraw()
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

local detailView = UI.Box.new{
    x=0, y=0, w=contentWidth, h=contentHeight,
    bg=colors.orange,
    hidden=true
}
box:add(detailView)

citizenList.onSelect = function(self, index, item)
    showDetailForCitizen(detailView, item.citizen)
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
