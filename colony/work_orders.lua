require("colony/utils")

local function findBuilding(colony, type, location)
    return filter(colony.getBuildings(), function(building)
        return building.type == type and
            building.location.x == location.x and
            building.location.y == location.y and
            building.location.z == location.z
    end)[1]
end

local function orderRow(order, colony)
    -- target building
    local line1 = order.buildingName

    -- order type
    local line2 = " " .. string.gsub(string.lower(order.workOrderType), "^%l", string.upper)
    if order.workOrderType == "UPGRADE" then
        line2 = line2 .. string.format(" %d>%d", order.targetLevel-1, order.targetLevel)
    end

    -- worker
    local line3 = " {gray}unclaimed"
    local builderName = ""
    if order.isClaimed then
        local builder = findBuilding(colony, "builder", order.builder)
        builderName = builder.citizens[1].name
        line3 = " " .. builderName
    end

    return {
        text=line1 .. "\n" .. line2 .. "\n" .. line3,
        filterable={
            order.buildingName,
            order.workOrderType,
            order.targetLevel or "",
            builderName
        },
        order=order
    }
end

local function shouldShowOrder(order, colony, filterText)
    if filterText == "" then
        return true
    end
    local filterItems = orderRow(order, colony).filterable
    for index, value in ipairs(filterItems) do
        if value ~= "" and string.find(string.lower(value), filterText) ~= nil then
            return true
        end
    end
    return false
end

local function reloadWorkOrders(colony, filterField, countLabel, orderList)
    local filterText = string.lower(filterField.text or "")
    local allOrders = colony.getWorkOrders()
    local orders = filter(allOrders, function(order)
        -- do not include mine building
        return order.type ~= "WorkOrderMiner"
    end)
    local visibleOrders = filter(orders, function(order)
        return shouldShowOrder(order, colony, filterText)
    end)
    orderList.items = map(visibleOrders, function(order)
        return orderRow(order, colony)
    end)
    orderList:redraw()

    countLabel.text = string.format("%d/%d", #visibleOrders, #orders)
    countLabel:redraw()
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
    local orderList = UI.List.new{
        x=margin, y=2, w=innerWidth, h=contentHeight - 3,
        fg=colors.black, bg=colors.lightBlue, bgAlternate=colors.lightGray, bgSelected=colors.blue,
        items={}, rowHeight=3
    }
    box:add(orderList)
    
    local detailView = UI.List.new{
        x=0, y=0, w=contentWidth, h=contentHeight,
        bg=colors.white,
        hidden=true,
        items={}
    }
    box:add(detailView)
    
    --detailView.onLink = ...
    
    --orderList.onSelect = function(self, index, item)
    --    showDetailForOrder(detailView, item)
    --end
    
    box.onShow = function(self)
        detailView.hidden = true
        reloadWorkOrders(colony, filterField, countLabel, orderList)
        box:redraw()
    end
    
    box.refresh = function(self)
        if detailView.hidden then
            reloadWorkOrders(colony, filterField, countLabel, orderList)
        end
    end
    
    reloadWorkOrders(colony, filterField, countLabel, orderList)
    
    return box
    end
    