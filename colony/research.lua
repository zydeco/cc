require("colony/utils")

local function traverseTree(roots, visitor, depth, parent)
    depth = depth or 1
    for index, item in ipairs(roots or {}) do
        if visitor(item, index, depth, parent) then
            traverseTree(item.children, visitor, depth+1, item)
        end
    end
end

local function allRequirementsFulfilled(requirements)
    for index, requirement in ipairs(requirements) do
        if not requirement.fulfilled then
            return false
        end
    end
    return true
end

local function flattenResearchItem(item, tree, depth)
    local maxProgress = 144 * (2 ^ depth)
    return {
        tree=tree,
        depth=depth,
        id=item.id,
        name=item.name,
        cost=item.cost,
        requirements=item.requirements,
        progress=item.progress / maxProgress,
        hoursLeft=(maxProgress - item.progress) / 288,
        status=item.status,
        effect=item.researchEffects,
        requirementsFulfilled=allRequirementsFulfilled(item.requirements),
    }
end

local RESEARCHES_WITH_ONLY_CHILD = {
    'minecolonies:civilian/stamina',
    'minecolonies:civilian/higherlearning',
    'minecolonies:combat/accuracy',
    'minecolonies:combat/avoidance',
    'minecolonies:combat/regeneration'
}

local function hasOnlyChild(research)
    if research.hasOnlyChild then
        return true
    end
    -- maybe it's not implemented yet
    for index, value in ipairs(RESEARCHES_WITH_ONLY_CHILD) do
        if research.id == value then
            return true
        end
    end
    return false
end

local function hasResearchedChild(research)
    for index, child in ipairs(research.children or {}) do
        if child.status ~= "NOT_STARTED" then
            return true
        end
    end
    return false
end

local function getFlattenedResearch(colony, maxDepth)
    local research = colony.getResearch()
    local result = {}
    for tree, roots in pairs(research) do
        traverseTree(roots, function(item, index, depth, parent)
            if depth > maxDepth then
                return false
            end
            if parent ~= nil and hasOnlyChild(parent) and item.status == "NOT_STARTED" and hasResearchedChild(parent) then
                -- another child of this only-child branch is already researched
                return false
            end
            table.insert(result, flattenResearchItem(item, tree, depth))
            return item.status == "FINISHED"
        end)
    end
    return result
end

local function formatTree(tree)
    if tree == "minecolonies:civilian" then
        return "C"
    elseif tree == "minecolonies:unlockable" then
        return "U"
    elseif tree == "minecolonies:combat" then
        return "M"
    elseif tree == "minecolonies:technology" then
        return "T"
    end
end

local function formatHoursLeft(hours)
    local fullHours = math.floor(hours)
    local minutes = (60 * hours) % 60
    if fullHours > 0 then
        if minutes > 0 then
            return string.format("%dh%dm", fullHours, minutes)
        else
            return string.format("%dh", fullHours)
        end
    else
        return string.format("%dm", minutes)
    end
end

local function researchRow(research, width)
    local treeName = string.sub(research.tree, 14)

    -- line 1: thing and time
    local line1 = formatTree(research.tree) .. " "
    if not research.requirementsFulfilled then
        line1 = line1 .. "{red}"
    end
    local timeLeft = formatHoursLeft(research.hoursLeft)
    local timeLeftColor = "{gray}"
    if research.status == "IN_PROGRESS" then
        timeLeftColor = "{blue}"
    end
    local formattedName = string.sub(research.name, 1, width - (2 + string.len(timeLeft)))
    line1 = line1 .. formattedName .. string.rep(" ", width - (2 + string.len(formattedName) + string.len(timeLeft))) .. timeLeftColor .. timeLeft

    -- line 2: effect
    local line2 = research.depth .. " " .. research.effect[1]
    local tags = {
        research.name,
        "#" .. treeName,
        "#" .. research.depth
    }
    for index, effect in ipairs(research.effect) do
        table.insert(tags, effect)
    end
    return {
        text=line1 .. "\n" .. line2,
        tags=tags,
        research=research
    }
end

local function getUniversityLevel(colony)
    local levels = map(filter(colony.getBuildings(), function(building)
        return building.type == "university"
    end), function(university)
        return university.level
    end)
    table.insert(levels, 0)
    return math.max(table.unpack(levels))
end

local function getMaxResearchDepth(universityLevel)
    if universityLevel == 5 then
        return 6
    else
        return universityLevel
    end
end

local function reloadResearch(colony, filterField, countLabel, researchList)
    local filterText = string.lower(filterField.text or "")
    local research = getFlattenedResearch(colony, getMaxResearchDepth(getUniversityLevel(colony)))
    -- don't show finished
    research = filter(research, function(item)
        return item.status ~= "FINISHED"
    end)
    sortListBy(research, function(item)
        local sortKey = item.tree .. item.name
        if item.status == "IN_PROGRESS" then
            return "  " .. sortKey
        elseif item.requirementsFulfilled then
            return " " .. sortKey
        else
            return sortKey
        end
    end, true) -- in-progress first
    local rowWidth = researchList.w
    local visibleResearch = filter(research, function(item)
        return shouldShowRow(researchRow(item, rowWidth), filterText)
    end)
    local hasScrollBar = (#visibleResearch * researchList.rowHeight) > researchList.h
    if hasScrollBar then
        rowWidth = researchList.w - 1
    end
    researchList.items = map(visibleResearch, function(item)
        return researchRow(item, rowWidth)
    end)
    researchList:redraw()

    countLabel.text = string.format("%d/%d", #visibleResearch, #research)
    countLabel:redraw()
end

local function requirementColor(requirement)
    if requirement.fulfilled then
        return "{green}"
    else
        return "{red}"
    end
end

local function detailForResearch(research, width)
    local lines = {
        " ",
        "{align=center}" .. research.name,
        "{align=center}{blue}" .. string.sub(research.tree, 14),
    }

    -- effects
    table.insert(lines, " Effects:")
    for _, effect in ipairs(research.effect) do
        local formattedEffect = UI.breakPlainTextLines(effect, width-2, " \x04 ", "   ")
        for _, line in ipairs(UI.textLines(formattedEffect)) do
            table.insert(lines, "{gray}" .. line)
        end
    end

    -- requirements
    if #research.requirements > 0 then
        table.insert(lines, " ")
        table.insert(lines, " Requirements:")
        for index, requirement in ipairs(research.requirements) do
            local prefix = requirementColor(requirement)
            local formattedRequirement = UI.breakPlainTextLines(requirement.desc, width-2, " \x04 ", "   ")
            for _, line in ipairs(UI.textLines(formattedRequirement)) do
                table.insert(lines, prefix .. line)
            end
        end
    else
        table.insert(lines, " Requirements: none")
    end

    -- cost
    if #research.cost > 0 then
        table.insert(lines, " ")
        table.insert(lines, " Cost:")
        for index, cost in ipairs(research.cost) do
            local itemName = string.gsub(string.gsub(cost.displayName, "^ +", ""), "[%[%]]", "")
            table.insert(lines, string.format(" \x04 %d{gray}x{fg}%s", cost.count, itemName))
        end
    else
        table.insert(lines, " Cost: none")
    end
    
    return lines
end

local function showDetailForResearch(detailView, research)
    detailView.hidden = false
    detailView.research = research
    detailView.items = detailForResearch(research, detailView.w)
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
    local researchList = UI.List.new{
        x=margin, y=2, w=innerWidth, h=contentHeight - 3,
        fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, showsSelection=false,
        items={}, rowHeight=2
    }
    box:add(researchList)

    -- help button
    box:add(helpButton(contentWidth-4,0,"(?)",function()
        local helpWidth = contentWidth-2
        local helpHeight = contentHeight-2
        local container = UI.Box.new{
            x=1,y=1,w=helpWidth,h=helpHeight,bg=colors.lightGray
        }
        local helpText = UI.Label.new{
            x=1,y=0,w=helpWidth-2,h=helpHeight,bg=colors.lightGray,fg=colors.black,text=
            "\x7f\x7f\x7f\x7f Research Row \x7f\x7f\x7f\x7f\n"..
            "{bg=lightBlue}T Name       {gray}Time Left{bg=bg}\n" ..
            "{bg=lightBlue}L Effect              {bg=bg}\n" ..
            " \n"..
            "X: \n"..
            " C Civilian\n"..
            " M Military\n"..
            " T Technology\n"..
            "L: Level\n"..
            " \n"..
            "\x7f\x7f\x7f\x7f\x7f\x7f Filter By \x7f\x7f\x7f\x7f\x7f\n"..
            " \x04 Name\n"..
            " \x04 Effect\n"..
            " \x04 #level\n"..
            ""
        }
        container:add(helpText)
        return container
    end, researchList))

    local detailView = UI.List.new{
        x=0, y=0, w=contentWidth, h=contentHeight,
        bg=colors.white,
        hidden=true,
        items={}
    }
    box:add(detailView)

    --detailView.onLink = ...

    researchList.onSelect = function(self, index, item)
        showDetailForResearch(detailView, item.research)
    end

    box.onShow = function(self)
        detailView.hidden = true
        reloadResearch(colony, filterField, countLabel, researchList)
        box:redraw()
    end

    box.refresh = function(self)
        if detailView.hidden then
            reloadResearch(colony, filterField, countLabel, researchList)
        end
    end

    reloadResearch(colony, filterField, countLabel, researchList)

    return box
end
