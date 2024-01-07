local Button = require("ui/components/Button")
local Keyboard = setmetatable({}, {__index = Button})
Keyboard.__index = Keyboard

local DOCK_BUTTON = "\x19"
local UNDOCK_BUTTON = "\x18"
local BOTTOM_LINE_END = " \x02 {dock} {fg}spc {alt}\x11\xd7\x10 rtn"
local KEY_PLANES = {
    ["ABC"] = "q w e r t y u i o p\n" ..
        " a s d f g h j k l \n" ..
        "{alt}\x12  {fg}z x c v b n m  {alt}\xab\n" ..
        "{alt}123" .. BOTTOM_LINE_END,
    ["ABC_CAPS"] = "Q W E R T Y U I O P\n" ..
        " A S D F G H J K L \n" ..
        "{alt}\x17  {fg}Z X C V B N M  {alt}\xab\n" ..
        "{alt}123" .. BOTTOM_LINE_END,
    ["123"] = "1 2 3 4 5 6 7 8 9 0\n" ..
        "- / : ; ( ) £ & @ \"\n" ..
        "{alt}#+=   {fg}. , ? ! '   {alt}\xab\n" ..
        "{alt}ABC" .. BOTTOM_LINE_END,
    ["#+="] = "[ ] \xab \xbb # % ^ * + =\n" ..
        "_ \\ | ~ < > \xa4 $ ¥ ·\n" ..
        "{alt}123 {fg}\xa6 \xb7 \xb8 \xbf \xa1 \xb4 \x60 {alt}\xab\n" ..
        "{alt}ABC" .. BOTTOM_LINE_END,
    ["\x02"] = "\xb9 \xb2 \xb3 \xbc \xbd \xbe \xa9 \xae \xaa \xb0\n" ..
        "\xad \x0b \x0c \x0e \x0f \xb5 \xa2 \xf7 \xb1 \xd7\n" ..
        "{alt}\xc2\xdf\xc7 {fg}\x01 \x02 \x03 \x04 \x05 \x06 \x07 {alt}\xab\n" ..
        "{alt}ABC" .. BOTTOM_LINE_END,
    ["\xc2\xdf\xc7"] = "\xe0 \xe1 \xe2 \xe3 \xe4 \xe5 \xe6 \xe7 \xe8 \xe9\n" ..
        "\xea \xeb \xec \xed \xee \xef \xf0 \xf1 \xf2 \xf3\n" ..
        "{alt}\x12  {fg}\xf4\xf5\xf6\xf8\xf9\xfa\xfb\xfc\xfd\xfe\xff\x14\x15  {alt}\xab\n" ..
        "{alt}ABC" .. BOTTOM_LINE_END,
    ["\xc2\xdf\xc7_CAPS"] = "\xc0 \xc1 \xc2 \xc3 \xc4 \xc5 \xc6 \xc7 \xc8 \xc9\n" ..
        "\xca \xcb \xcc \xcd \xce \xcf \xd0 \xd1 \xd2 \xd3\n" ..
        "{alt}\x17  {fg}\xd4\xd5\xd6\xd8\xd9\xda\xdb\xdc\xdd\xde\xdf\xb6\xa7  {alt}\xab\n" ..
        "{alt}ABC" .. BOTTOM_LINE_END,
}

local function getPlane(plane, docked, altColor)
    local dockButton = DOCK_BUTTON
    if docked then
        dockButton = UNDOCK_BUTTON
    end
    return string.gsub(string.gsub(KEY_PLANES[plane], "{dock}", dockButton), "{alt}", "{" .. altColor .. "}")
end

local function switchPlane(self, plane)
    if plane == "\x12" then
        -- caps
        plane = self.plane .. "_CAPS"
    elseif plane == "\x17" then
        -- no caps
        plane = string.sub(self.plane, 1, 3)
    end
    local keys = getPlane(plane, self.docked, self.altColor)
    if keys ~= nil then
        local plainText = UI.plainText(keys)
        if string.len(plainText) ~= 79 then
            error("Invalid plane len " .. string.len(plainText))
        end
        self.plane = plane
        self.text = keys
        self.plainText = plainText
        self:redraw()
    end
end

local function dockKeyboard(self)
    self.docked = not self.docked
    self.text = getPlane(self.plane, self.docked, self.altColor)
    self.parent:redraw()
end

local function doKeyDown(self, key)
    if key == nil then
        return
    elseif type(key) == "string" and string.len(key) == 1 and self.ui.keyHandler ~= nil then
        self.ui.keyHandler:onChar(key)
    elseif type(key) == "number" and self.ui.keyHandler ~= nil then
        self.ui.keyHandler:onKeyDown(key)
    elseif type(key) == "table" and type(key.action) == "function" then
        key.action(self, key.arg)
    end
end

local function findKey(self, x, y)
    local plainText = self.plainText
    if y == 0 or y == 1 then
        -- character
        local pos = x + 1
        if y == 1 then pos = pos + 20 end
        local key = string.sub(plainText, pos, pos)
        if key ~= " " then
            return key
        else
            return nil
        end
    elseif y == 2 then
        -- special keys on left and right 3-char sides, otherwise character
        if x <= 2 then
            -- switch plane
            return {action=switchPlane, arg=string.match(string.sub(plainText, 41, 43), "[^ ]+")}
        elseif x >= 17 then
            -- delete
            return keys.backspace
        else
            -- actually a key
            local key = string.sub(plainText, x + 41, x + 41)
            if key ~= " " then
                return key
            else
                return nil
            end
        end
        return nil
    elseif y == 3 then
        -- special keys
        if x <= 2 then
            -- switch plane
            return {action=switchPlane, arg=string.sub(plainText, 61, 63)}
        elseif x == 4 then
            -- switch plane
            return {action=switchPlane, arg=string.sub(plainText, 65, 65)}
        elseif x == 6 then
            -- dock
            return {action=dockKeyboard}
        elseif x == 8 or x == 9 or x == 10 then
            -- space
            return " "
        elseif x == 12 then
            -- arrow left
            return keys.left
        elseif x == 13 then
            -- close field
            return {action=function() self.ui.keyHandler:blur() end}
        elseif x == 14 then
            -- arrow right
            return keys.right
        elseif x >= 16 then
            -- return
            return keys.enter
        end
        return nil
    end
end

local function onTouch(self, x, y, monitor)
    doKeyDown(self, findKey(self, x, y))
end

local function onMouseDown(self, x, y, button)
    doKeyDown(self, findKey(self, x, y))
end

function Keyboard.new(arg)
    local self = setmetatable(Button.new({
        x=arg.x,
        y=arg.y,
        w=19,
        h=4,
        bg=arg.bg or colors.black,
        fg=arg.fg or colors.white,
        align=UI.LEFT,
        verticalAlign=UI.TOP,
        hidden=arg.hidden,
        text=getPlane("ABC", false, arg.altColor or colors.yellow)
    }), {__index=Keyboard})
    self.altColor = arg.altColor or colors.yellow
    self.plane = "ABC"
    self.plainText = UI.plainText(self.text)
    self.docked = false
    self.onMouseDown = onMouseDown
    self.onMouseUp = function() end
    self.onTouch = onTouch
    return self
end

function Keyboard.show(ui, term, field)
    if ui.keyboard == nil then
        ui.keyboard = UI.Keyboard.new({x=field.x, y=field.y})
    end
    local kbd = ui.keyboard
    if kbd.docked then
        -- bottom middle of screen
        kbd.x = math.floor((field.parent.w - kbd.w) / 2)
        kbd.y = field.parent.h - kbd.h
    else
        -- under field, on the right side
        kbd.x = field.x + field.w - kbd.w
        kbd.y = field.y + 1
    end
    field.parent:add(kbd)
end

function Keyboard.hide(ui)
    if ui.keyboard ~= nil then
        ui.keyboard:removeFromSuperview()
    end
end

return Keyboard
