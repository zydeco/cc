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
    return self
end

function Label:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local marginTop = math.floor(self.h / 2)
    term.setCursorPos(self.x + dx, self.y + dy + marginTop)
    self.ui:drawStyledText(term, self.text or "", self.bg, self.fg, self.w, self.align)
end

return Label
