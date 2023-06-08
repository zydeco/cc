function citizenRow(citizen, width)
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
    local ageIcon = "{gray}" .. string.sub(citizen.age, 1, 1)
    if citizen.work then
        local job = citizen.work.type
        line2 = " " .. job .. " " .. citizen.work.level .. string.rep(" ", width - 3 - string.len(job) - 1) .. ageIcon
    else
        line2 = " {red}unemployed" .. string.rep(" ", width - 11 - 1) .. ageIcon
    end
    return line1 .. "\n" .. line2
end

function shouldShowCitizen(citizen, filterText)
    return string.find(string.lower(citizen.name), filterText) ~= nil or
    (citizen.work ~= nil and string.find(string.lower(citizen.work.type), filterText) == 1)
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
    x=margin, y=1, w=innerWidth, h=1,
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

-- list
local citizenList = UI.List.new{
    x=margin, y=2, w=innerWidth, h=contentHeight - 3,
    fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, bgSelected=colors.blue,
    items={}, rowHeight=2,
    onSelect=function()

    end
}
box:add(citizenList)

-- detail?

box.onShow = function(self)
    local filterText = string.lower(filterField.text or "")
    local visibleCitizens = filter(colony.getCitizens(), function(citizen)
        return shouldShowCitizen(citizen, filterText)
    end)
    local hasScrollBar = #visibleCitizens > (citizenList.h * citizenList.rowHeight)
    local rowWidth = citizenList.w
    if hasScrollBar then
        rowWidth = citizenList.w - 2
    end
    citizenList.items = map(visibleCitizens, function(citizen)
        return citizenRow(citizen, rowWidth)
    end)
    citizenList:redraw()
end

box:onShow()

return box
end
