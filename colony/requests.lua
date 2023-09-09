require("colony/utils")

local function requestRow(request)
    return {
        text=request.name .. "\n" .. translate(request.target),
        tags={
            request.name,
            translate(request.target)
        },
        request=request
    }
end

local function reloadRequests(colony, filterField, countLabel, requestList, sortOrder)
    local filterText = string.lower(filterField.text or "")
    local requests = colony.getRequests()
    local visibleRequests = filter(requests, function(request)
        return shouldShowRow(requestRow(request), filterText)
    end)
    sortListBy(visibleRequests, sortOrder.by, sortOrder.ascending)
    requestList.items = map(visibleRequests, function(request)
        return requestRow(request)
    end)
    requestList:redraw()

    countLabel.text = string.format("%d/%d", #visibleRequests, #requests)
    countLabel:redraw()
end

local function detailForRequest(request, width)
    local lines = {
        " ",
        " Item: " .. request.name,
        UI.breakPlainTextLines("To: " .. translate(request.target), width-2, " "),
        " ",
        UI.breakPlainTextLines(request.desc, width-2, " ")
    }

    return table.concat(lines, "\n")
end

local function showDetailForRequest(detailView, request)
    detailView.hidden = false
    detailView.request = request
    detailView.text = detailForRequest(request, detailView.w)
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
    local requestList = UI.List.new{
        x=margin, y=2, w=innerWidth, h=contentHeight - 3,
        fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, showsSelection=false,
        items={}, rowHeight=2
    }
    box:add(requestList)

    -- sorting
    local sortOrder = {
        ascending = true
    }
    local sortMenu = makeSortMenu(
        sortOrder,
        {
            { text="Order", sortKey = nil },
            { text="Item", sortKey = "name"},
            { text="Target", sortKey = "target"},
        },
        function()
            reloadRequests(colony, filterField, countLabel, requestList, sortOrder)
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
            "\x7f\x7f\x7f\x7f\x7f Request Row \x7f\x7f\x7f\x7f\n"..
            "{bg=lightBlue}Requested Item        {bg=bg}\n" ..
            "{bg=lightBlue} Target               {bg=bg}\n" ..
            " \n"..
            "\x7f\x7f\x7f\x7f\x7f\x7f Filter By \x7f\x7f\x7f\x7f\x7f\n"..
            " \x04 Requested Item\n"..
            " \x04 Target\n"..
            ""
        }
        container:add(helpText)
        return container
    end, requestList))

    local detailView = UI.Label.new{
        x=0, y=0, w=contentWidth, h=contentHeight,
        bg=colors.white,
        hidden=true,
    }
    box:add(detailView)

    --detailView.onLink = ...

    requestList.onSelect = function(self, index, item)
        showDetailForRequest(detailView, item.request)
    end

    box.onShow = function(self)
        detailView.hidden = true
        reloadRequests(colony, filterField, countLabel, requestList, sortOrder)
        box:redraw()
    end

    box.refresh = function(self)
        if detailView.hidden then
            reloadRequests(colony, filterField, countLabel, requestList, sortOrder)
        end
    end

    reloadRequests(colony, filterField, countLabel, requestList, sortOrder)

    return box
end
