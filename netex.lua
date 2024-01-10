require("ui")

local screen = term.current()
local tw,th = term.current().getSize()
local w,h = screen.getSize()
local ui = UI.new(screen)
local base = ui.base

local function loadPeripherals()
    local peripherals = {}
    for index, name in ipairs(peripheral.getNames()) do
        local item = {
            itemType="peripheral",
            name=name,
            type=peripheral.getType(name),
            methods=peripheral.getMethods(name),
            peripheral=peripheral.wrap(name),
        }
        item.text = name .. " {gray}" .. item.type
        table.insert(peripherals, item)
    end
    return peripherals
end

local mainList
local titleLabel = UI.Label.new{x=2,y=0,w=w-4,text=nil,align=UI.CENTER}
local backButton = UI.Button.new{x=0,y=0,w=1,h=1,text="\x11",bg=colors.red,fg=colors.white,action=nil,hidden=true}
local refreshButton = UI.Button.new{x=w-2,y=0,w=1,h=1,text="\x15",bg=colors.green,fg=colors.white,action=nil,hidden=true}

local function goToList()
    titleLabel.text = "== Peripherals == "
    backButton.hidden = true
    mainList.items = loadPeripherals()
    mainList.selected = nil
    refreshButton.hidden = false
    refreshButton.action = goToList
    base:redraw()
end

local function goToPeripheral(item)
    titleLabel.text = item.text
    backButton.hidden = false
    backButton.action = goToList
    refreshButton.hidden = false
    refreshButton.action = function()
        goToPeripheral(item)
    end
    local items = {}
    for _, method in ipairs(item.methods) do
        local peripheral = item.peripheral
        table.insert(items, {
            itemType="method",
            parent=item,
            peripheral=peripheral,
            peripheralName=item.name,
            method=method,
            text=method
        })
    end
    mainList.items = items
    mainList.selected = nil
    base:redraw()
end

local function goToMethod(item)
    titleLabel.text = item.text
    backButton.hidden = false
    backButton.action = function()
        goToPeripheral(item.parent)
    end
    refreshButton.hidden = false
    refreshButton.action = function()
        goToMethod(item)
    end
    local items = {}
    local results = {pcall(item.peripheral[item.method])}
    local ok = results[1]
    if not ok then
        table.insert(items, "{red}error")
    end
    for i = 2, #results, 1 do
        local result = results[i]
        if ok then
            table.insert(items, "{green}" .. type(result))
        end
        for _,line in ipairs(UI.textLines(textutils.serialize(result))) do
            for _, line in ipairs(UI.textLines(UI.breakPlainTextLines(line, mainList.w-1))) do
                table.insert(items, "{plain}" .. line)
            end
        end
    end
    mainList.items = items
    mainList.selected = nil
    base:redraw()
end


mainList = UI.List.new{
    x=0,y=1,w=w,h=h-2,
    onSelect = function(self, index, item)
        if item==nil or type(item) ~= "table" then
            return
        elseif item.itemType == "peripheral" then
            goToPeripheral(item)
        elseif item.itemType == "method" then
            goToMethod(item)
        end
    end,
}

base:add(backButton)
base:add(UI.Button.new{x=w-1,y=0,w=1,h=1,text="X",bg=colors.red,fg=colors.white,action=function() ui:stop() end})
base:add(refreshButton)
base:add(titleLabel)
base:add(mainList)
goToList()
ui:run()