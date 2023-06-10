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
    self.fg = arg.fg or colors.black
    self.align = arg.align or UI.LEFT
    self.verticalAlign = arg.verticalAlign or UI.TOP
    return self
end

function Label:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local lines = UI.textLines(self.text or "")
    local marginTop = 0
    if self.verticalAlign == UI.CENTER then
        marginTop = math.floor((self.h - #lines) / 2)
    elseif self.verticalAlign == UI.BOTTOM then
        marginTop = self.h - #lines
    end
    for i=1,math.min(self.h, #lines) do
        term.setCursorPos(self.x + dx, self.y + dy + marginTop + i - 1)
        self.ui:drawStyledText(term, lines[i], self.bg, self.fg, self.w, self.align)
    end
end

return Label
