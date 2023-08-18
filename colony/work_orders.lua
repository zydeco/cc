require("colony/utils")

local function findBuilding(colony, type, location)
    return filter(colony.getBuildings(), function(building)
        return building.type == type and sameLocation(building.location, location)
    end)[1]
end

local function getOrderNeededResources(resources)
    if resources == nil then
        return 0
    end
    local needed = 0
    for index, value in ipairs(resources) do
        if value.needed > value.available then
            needed = needed + (value.needed - value.available)
        end
    end
    return needed
end

local function orderRow(order, colony, isActive)
    -- target building
    local line1 = order.buildingName
    local tags = {
        order.buildingName,
        order.workOrderType,
        order.targetLevel or "",
    }

    -- order type & needed resources
    local line2 = " " .. string.gsub(string.lower(order.workOrderType), "^%l", string.upper)
    if order.workOrderType == "UPGRADE" then
        line2 = line2 .. string.format(" %d>%d", order.targetLevel-1, order.targetLevel)
    end
    if isActive then
        local resources = colony.getWorkOrderResources(order.id)
        local needed = getOrderNeededResources(resources)
        if needed > 0 then
            line2 = line2 .. string.format(" {red}!%d", needed)
            table.insert(tags, "#needed")
        else
            table.insert(tags, "#ready")
        end
    else
        line2 = line2 .. " {gray}(queued)"
        table.insert(tags, "#queued")
    end

    -- worker
    local line3 = " {gray}unclaimed"
    if order.isClaimed and order.builder ~= nil then
        local builder = findBuilding(colony, "builder", order.builder)
        if #builder.citizens > 0 then
          local builderName = builder.citizens[1].name
          line3 = " " .. builderName
          table.insert(tags, builderName)
        else
          line3 = " {red}missing builder"
        end
    else
        table.insert(tags, "#unclaimed")
    end

    return {
        text=line1 .. "\n" .. line2 .. "\n" .. line3,
        tags=tags,
        order=order
    }
end

local function currentOrderIdForBuilder(builder, allOrders)
    if builder == nil then
        return nil
    end
    -- is this the same? https://github.com/ldtteam/minecolonies/blob/ce3539919863e3814bba1edf22668546e2f24c3e/src/main/java/com/minecolonies/coremod/client/gui/WindowResourceList.java#L314-L315
    local ordersForBuilder = filter(allOrders, function(order)
        return order.builder ~= nil and sameLocation(order.builder, builder)
    end)
    if #ordersForBuilder == 0 then
        return nil
    end
    table.sort(ordersForBuilder, function(a, b)
        return a.priority < b.priority
    end)
    return ordersForBuilder[1].id
end

local function reloadWorkOrders(colony, filterField, countLabel, orderList)
    local filterText = string.lower(filterField.text or "")
    local allOrders = colony.getWorkOrders()
    local orders = filter(allOrders, function(order)
        -- do not include mine building
        return order.type ~= "WorkOrderMiner"
    end)
    local visibleOrders = filter(orders, function(order)
        return shouldShowRow(orderRow(order, colony), filterText)
    end)
    orderList.items = map(visibleOrders, function(order)
        local isCurrentWorkOrder = currentOrderIdForBuilder(order.builder, allOrders) == order.id
        return orderRow(order, colony, isCurrentWorkOrder)
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

    -- help button
    box:add(helpButton(contentWidth-4,0,"(?)",function()
        local helpWidth = contentWidth-2
        local helpHeight = contentHeight-2
        local container = UI.Box.new{
            x=1,y=1,w=helpWidth,h=helpHeight,bg=colors.lightGray
        }
        local helpText = UI.Label.new{
            x=1,y=0,w=helpWidth-2,h=helpHeight,bg=colors.lightGray,fg=colors.black,text=
            "\x7f\x7f\x7f Work Order Row \x7f\x7f\x7f\n"..
            "{bg=lightBlue}Building Name         {bg=bg}\n" ..
            "{bg=lightBlue} Type {gray}(status){fg}        {bg=bg}\n" ..
            "{bg=lightBlue} Builder              {bg=bg}\n" ..
            " Type: Build, Upgrade, etc\n" ..
            " Status:\n" ..
            "  {gray}(queued){fg}\n" ..
            "  {red}!12{fg} needed resources\n" ..
            " \n"..
            "\x7f\x7f\x7f\x7f\x7f\x7f Filter By \x7f\x7f\x7f\x7f\x7f\x7f\x7f\n"..
            " \x04 Building Name\n"..
            " \x04 Type, Target Level\n"..
            " \x04 Builder Name\n"..
            " \x04 #queued/#unclaimed\n"..
            " \x04 #needed/#ready\n"..
            ""
        }
        container:add(helpText)
        return container
    end, orderList))

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
    