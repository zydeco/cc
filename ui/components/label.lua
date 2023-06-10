require("ui/text")
local Box = require("ui/components/box")
local Label = setmetatable({}, {__index = Box})
Label.__index = Label

function Label.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w or string.len(arg.text or ""),
        h=arg.h or 1,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }), {__index=Label})
    self.text = arg.text or ""
    self._lines = UI.textLines(self.text)
    self.fg = arg.fg or colors.black
    self.align = arg.align or UI.LEFT
    self.verticalAlign = arg.verticalAlign or UI.TOP
    return self
end

function Label:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local lines = UI.textLines(self.text or "")
    self._lines = lines
    local marginTop = 0
    if self.verticalAlign == UI.CENTER then
        marginTop = math.floor((self.h - #lines) / 2)
    elseif self.verticalAlign == UI.BOTTOM then
        marginTop = self.h - #lines
    end
    self._marginTop = marginTop
    for i=1,math.min(self.h, #lines) do
        term.setCursorPos(self.x + dx, self.y + dy + marginTop + i - 1)
        self.ui:drawStyledText(term, lines[i], self.bg, self.fg, self.w, self.align)
    end
end

function Label:onMouseDown(x, y)
    -- find link
    if self.onLink == nil then return end
    local line = self._lines[y+1-self._marginTop]
    if line == nil then return end
    local tagValue = UI.textTagAt(line, self.w, self.align, "link", x)
    if tagValue and tagValue ~= "" then
        self:onLink(tagValue)
    end
end

return Label
