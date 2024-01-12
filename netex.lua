require("ui")

local screen = term.current()
local tw,th = term.current().getSize()
local w,h = screen.getSize()
local ui = UI.new(screen)
local base = ui.base

local function loadPeripherals()
    local peripherals = {}
    for _, name in ipairs(peripheral.getNames()) do
        table.insert(peripherals, "{link=" .. name .."/}" .. name .. " {gray}" .. peripheral.getType(name))
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
    refreshButton.hidden = false
    refreshButton.action = goToList
    base:redraw()
end

local function goToPeripheral(name)
    titleLabel.text = name
    backButton.hidden = false
    backButton.action = goToList
    refreshButton.hidden = false
    refreshButton.action = function()
        goToPeripheral(name)
    end
    local items = {}
    for _, method in ipairs(peripheral.getMethods(name)) do
        local link = name .. "/" .. method
        table.insert(items, string.format("{link=%s}%s{gray}{link=%s...}(...)", link, method, link))
    end
    mainList.items = items
    base:redraw()
end

local function parseMethodPath(path)
    local slash = path:find("/")
    local name = path:sub(1, slash-1)
    local method = path:sub(slash+1)
    local withArgs = false
    if method:sub(-3) == "..." then
        withArgs = true
        method = method:sub(1,-4)
    end
    return name, method, withArgs
end

local function goToMethod(path, args, back)
    local name, method = parseMethodPath(path)
    titleLabel.text = name .. "." .. method
    backButton.hidden = false
    backButton.action = back or function()
        goToPeripheral(name)
    end
    refreshButton.hidden = false
    refreshButton.action = function()
        goToMethod(path, args)
    end
    local items = {}
    local results = {pcall(peripheral.wrap(name)[method], table.unpack(args))}
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
    if #results == 1 then
        table.insert(items, "{green}no return value")
    end
    mainList.items = items
    mainList.selected = nil
    base:redraw()
end

local callBox = nil
local argsField = nil
local argsError = nil

local function parseArgs(value)
    local ok, args = pcall(textutils.unserialise, "{" .. value .. "}")
    if ok then
        return args
    else
        return nil
    end
end

local function prepareCall(path)
    local name, method = parseMethodPath(path)
    titleLabel.text = name .. "." .. method .. "(...)"
    if callBox == nil then
        callBox = UI.Box.new{
            x=0,y=1,w=base.w,h=base.h-1,bg=colors.white
        }
        callBox:add(UI.Label.new{
            x=1,y=1,w=base.w-2,h=1,fg=colors.black,text="Args:"
        })
        argsField = UI.Field.new{
            x=1,y=2,w=base.w-2,h=1,bg=colors.lightBlue,fg=colors.black,placeholder={text="1,2,3",color=colors.lightGray}
        }
        argsError = UI.Label.new{
            x=1,y=3,w=base.w-2,h=1,fg=colors.red,text=""
        }
        local doCall = function()
            local args = parseArgs(argsField.text)
            if args == nil then
                argsError.text = "Format error!"
                argsError:redraw()
            else
                callBox:removeFromSuperview()
                goToMethod(callBox.path, args, function()
                    prepareCall(callBox.path)
                end)
            end
        end
        argsField.onEnter = doCall
        callBox:add(argsField)
        callBox:add(argsError)
        local callButtonWidth = 6
        local callButton = UI.Button.new{
            x=math.floor((base.w - callButtonWidth) / 2),y=5,w=callButtonWidth,h=3,bg=colors.green,fg=colors.white,text="Call",action=doCall
        }
        callBox:add(callButton)
    end
    backButton.action = function()
        callBox:removeFromSuperview()
        goToPeripheral(name)
    end
    refreshButton.hidden = true
    callBox.path = path
    base:add(callBox)
    base:redraw()
end

mainList = UI.List.new{
    x=0,y=1,w=w,h=h-1,
    onLink = function(self, link)
        if link:sub(-1) == "/" then
            -- peripheral
            local name = link:sub(1, -2)
            goToPeripheral(name)
        elseif link:sub(-3) == "..." then
            -- call with arguments
            prepareCall(link)
        else
            -- call without arguments
            goToMethod(link, {})
        end
    end
}

base:add(backButton)
base:add(UI.Button.new{x=w-1,y=0,w=1,h=1,text="X",bg=colors.red,fg=colors.white,action=function() ui:stop() end})
base:add(refreshButton)
base:add(titleLabel)
base:add(mainList)
goToList()
ui:run()