
local Button = require("ui/components/button")
local List = require("ui/components/list")
local Menu = setmetatable({}, {__index = Button})
Menu.__index = Menu

require("ui/utils")

local function calcMenuSize(self)
    local width = self.w
    local maxWidth = self.ui.base.w - self.abs.x + 1
    local maxHeight = self.ui.base.h - self.abs.y
    for i = 1, #self.items do
        local item = self.items[i]
        local itemWidth = UI.strlen(item.text or "") + 2
        width = math.max(width, itemWidth)
    end
    return math.min(maxWidth, width), math.min(maxHeight, #self.items)
end

local function hideMenu(self)
    self._menuView = nil
    self.ui:hideMenu()
end

local function itemPrefix(item)
    if item.marked then
        return item.mark or "\x04"
    else
        return " "
    end
end

local function showMenu(self)
    local w,h = calcMenuSize(self)
    local separator = string.rep("\x8c", w)
    self._menuView = List.new{
        x=self.abs.x-1, y=self.abs.y, w=w, h=h, items=UI.map(self.items, function(item)
            if item.text then
                return { text=itemPrefix(item) .. item.text }
            else
                -- separator
                return { text=separator, selectable=false }
            end
        end),
        fg=self.fg or self.menuTextColor,
        bg=self.menuBg or self.bg,
        bgAlternate=self.menuBgAlternate or self.bg,
        fgSelected=self.bg, bgSelected=self.fg
    }
    self._menuView.onSelect = function(list, x, y)
        -- implement onSelect to make list selectable
    end
    self._menuView.onMouseUp = function(list, x,y)
        local index = y+1
        local item = self.items[index]
        if item.onSelect then
            item:onSelect()
        end
        if item.text ~= nil then
            self:onSelect(index, item)
            hideMenu(self)
        end
    end
    self.ui:showMenu(self._menuView)
end

local function onMouseDown(self, x, y, button)
    if button == 1 then
        if self._menuView == nil or self._menuView.parent == nil then
            showMenu(self)
        else
            hideMenu(self)
        end
    end
end

function Menu.new(arg)
    local self = setmetatable(Button.new({
        text=arg.text,
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h or 1,
        bg=arg.bg or colors.black,
        fg=arg.fg or colors.white,
        align=arg.align or UI.LEFT,
        verticalAlign=arg.verticalAlign or UI.MIDDLE,
        hidden=arg.hidden,
    }), {__index=Menu})
    self.items = arg.items or {}
    self.menuBg = arg.menuBg
    self.menuBgAlternate = arg.menuBgAlternate or arg.menuBg
    self.menuTextColor = arg.menuTextColor
    self.onSelect = arg.onSelect or function() end
    self.onMouseDown = onMouseDown
    return self
end

return Menu
