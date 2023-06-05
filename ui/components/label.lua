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
    local marginLeft = 0
    local marginTop = math.floor(self.h / 2)
    local visibleText = string.sub(self.text or "", 1, self.w)
    if self.align == 0 then
        -- center
        marginLeft = math.max(0, math.floor((self.w - string.len(self.text)) / 2))
    elseif self.align == 1 then
        -- right
        marginLeft = math.max(0, math.floor((self.w - string.len(self.text))))
    end
    term.setCursorPos(self.x + dx + marginLeft, self.y + dy + marginTop)
    term.setTextColor(self.fg)
    term.setBackgroundColor(self.bg)
    term.write(visibleText)
end

return Label
