require("ui/text")
local Box = require("ui/components/box")
local List = setmetatable({}, {__index = Box})
List.__index = List

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

function textLinesForItem(item)
    if type(item) == "string" then
        return UI.textLines(item)
    elseif type(item) == "table" then
        return UI.textLines(item.text)
    else
        error("unexpected item type " .. type(item))
    end
end

function List:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local items = self.items
    local rowHeight = self.rowHeight
    local contentHeight = #items * rowHeight
    local itemsPerPage = math.floor(self.h / rowHeight)
    self.maxScroll = math.max(1, 1 + #items - itemsPerPage)
    if self.scrollIndex > self.maxScroll then
        self.scrollIndex = self.maxScroll
    end
    if self.selected and self.selected > #items then
        self.selected = nil
    end
    local needBar = contentHeight > self.h
    local contentWidth = self.w
    if needBar then
        contentWidth = contentWidth - 2
    end
    local bg = self.bg
    local fg = self.fg
    for y = 0, self.h-1 do
        local index = self.scrollIndex + math.floor(y / rowHeight)
        local item = self.items[index] or ""
        local textLines = textLinesForItem(item)
        local text = (textLines[1 + y % rowHeight] or "") -- .. pad
        term.setCursorPos(self.x + dx, self.y + dy + y)
        if index == self.selected then
            fg = self.fgSelected
            bg = self.bgSelected
        else
            fg = self.fg
            if index % 2 == 0 and index <= #items then
                bg = self.bgAlternate
            else
                bg = self.bg
            end
        end
        self.ui:drawStyledText(term, text, bg, fg, contentWidth, UI.LEFT)
        if needBar then
            local bar = "\x7f"
            local barSize = self.h - 2
            local scrollPos = 1
            if self.scrollIndex >= self.maxScroll then
                scrollPos = self.h - 2
            elseif self.scrollIndex > 1 then
                scrollPos = 1 + math.floor((self.scrollIndex / self.maxScroll) * barSize)
            end
            if y == 0 then
                bar = "\x1e"
            elseif y == self.h-1 then
                bar = "\x1f"
            elseif y == scrollPos then
                bar = "\x08"
            end

            term.setTextColor(self.fg)
            term.setBackgroundColor(bg)
            term.setCursorPos(self.x + dx + self.w - 2, self.y + dy + y)
            term.write(" " .. bar)
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
        local item = nil
        if index <= #self.items then
            item = self.items[index]
            self.selected = index
        else
            self.selected = nil
        end
        if item.selectable == false then
            self.selected = nil
            item = nil
        end
        self:onSelect(self.selected, item)
    elseif self.onLink then
        -- links
        local index = self.scrollIndex + math.floor(y / self.rowHeight)
        if index > #self.items then return end
        self.ui.msg = "onLink " .. index
        local item = self.items[index]
        local textLines = textLinesForItem(item)
        local line = textLines[1 + (y % self.rowHeight)]
        if line == nil then return end
        local tagValue = UI.textTagAt(line, self.w, self.align, "link", x)
        if tagValue and tagValue ~= "" then
            self:onLink(tagValue)
        end
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