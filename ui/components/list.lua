local Box = require("ui/components/box")
local List = setmetatable({}, {__index = Box})
List.__index = List

local function stringLines(str)
    local lines = {}
    for line in string.gmatch(str, "[^\n]+") do
        lines[#lines + 1] = line
    end
    return lines
end

function List.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w or string.len(arg.text or ""),
        h=arg.h or 1,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }), {__index=List})
    self.fg = arg.fg or colors.black
    self.onSelect = arg.onSelect
    self.items = arg.items
    self.rowHeight = arg.rowHeight or 1
    self.bgAlternate = arg.bgAlternate or arg.bg or colors.lightGray
    self.bgSelected = arg.bgSelected or colors.black
    self.fgSelected = arg.fgSelected or colors.white
    self.scrollIndex = 1 -- first item displayed
    self.selected = nil
    return self
end

function List:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local items = self.items
    local rowHeight = self.rowHeight
    local contentHeight = #items * rowHeight
    local itemsPerPage = math.floor(self.h / rowHeight)
    self.maxScroll = 1 + #items - itemsPerPage
    term.setTextColor(self.fg)
    local pad = string.rep(" ", self.w)
    local needBar = contentHeight > self.h
    for y = 0, self.h-1 do
        local index = self.scrollIndex + math.floor(y / rowHeight)
        local item = self.items[index] or ""
        local textLines = stringLines(item)
        local text = string.sub((textLines[1 + y % rowHeight] or "") .. pad, 1, self.w)
        local bg = self.bg
        if index % 2 == 1 and index <= #items then
            bg = self.bgAlternate
        end
        if needBar then
            local bar = "|"
            local barSize = self.h - 2
            local scrollPos = 1
            if self.scrollIndex >= self.maxScroll then
                scrollPos = self.h - 2
            elseif self.scrollIndex > 1 then
                scrollPos = 1 + math.floor((self.scrollIndex / self.maxScroll) * barSize)
            end
            if y == 0 then
                bar = "^"
            elseif y == self.h-1 then
                bar = "v"
            elseif y == scrollPos then
                bar = "#"
            end
            text = string.sub(text, 1, self.w - 2) .. " " .. bar
        end
        term.setCursorPos(self.x + dx, self.y + dy + y)
        term.setBackgroundColor(bg)
        if index == self.selected then
            term.setTextColor(self.fgSelected)
            term.setBackgroundColor(self.bgSelected)
            if needBar then
                term.write(string.sub(text, 1, self.w - 1))
            else
                term.write(text)
            end
            term.setTextColor(self.fg)
            if needBar then
                term.setBackgroundColor(self.bg)
                term.setCursorPos(self.x + dx + self.w - 1, self.y + dy + y)
                term.write(string.sub(text, self.w, self.w))
            end
        else
            if needBar then
                term.write(string.sub(text, 1, self.w - 1))
                term.setBackgroundColor(self.bg)
                term.setCursorPos(self.x + dx + self.w - 1, self.y + dy + y)
                term.write(string.sub(text, self.w, self.w))
            else
                term.write(text)
            end
        end
    end
end

function List:onMouseDown(x, y, button)
    if button ~= 1 then
        return
    end
    if x == self.w - 1 then
        -- scroll bar
        self:redraw()
        if y == 0 then
            self:scrollUp()
        elseif y == self.h - 1 then
            self:scrollDown()
        elseif y == 1 then
            self.scrollIndex = 1
        elseif y == self.h - 2 then
            self.scrollIndex = self.maxScroll
        else
            local barSize = self.h - 2
            self.scrollIndex = math.floor(self.maxScroll * (y / barSize))
        end
    elseif self.onSelect then
        -- select item
        self:redraw()
        local index = self.scrollIndex + math.floor(y / self.rowHeight)
        if index <= #self.items then
            self.selected = index
        else
            self.selected = nil
        end
        self:onSelect(self.selected, self.items[self.selected])
    end
end

function List:scrollDown()
    self:redraw()
    self.scrollIndex = math.min(self.scrollIndex + 1, self.maxScroll)
end

function List:scrollUp()
    self:redraw()
    self.scrollIndex = math.max(1, self.scrollIndex - 1)
end

function List:onScroll(direction)
    if direction == -1 then
        self:scrollUp()
    elseif  direction == 1 then
        self:scrollDown()
    end
end

return List