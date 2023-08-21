local Box = require("ui/components/box")
local Checkbox = setmetatable({}, {__index = Box})
Checkbox.__index = Checkbox

function Checkbox.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w or string.len(arg.text or ""),
        h=arg.h or 1,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }), {__index=Checkbox})
    self.text = arg.text or ""
    self.checked = arg.checked or false
    self.fg = arg.fg or colors.black
    self.onChange = arg.onChange
    self.checkSign = arg.checkSign or "\xd7"

    self.toggle = function(self)
        self.checked = not self.checked
        if self.onChange then
            self:onChange(self.checked)
        end
        self:redraw()
    end

    self.onMouseUp = function(self, x, y, button)
        if button == 1 then
            self:toggle()
        end
    end
    self.onTouch = function(self, x, y)
        self:toggle()
    end
    return self
end

local function textPrefix(self)
    if self.checked then
        return "[" .. self.checkSign .. "] "
    else
        return "[ ] "
    end
end

function Checkbox:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local text = textPrefix(self) .. self.text
    term.setCursorPos(self.x + dx, self.y + dy)
    self.ui:drawStyledText(term, text, self.bg, self.fg, self.w, self.align)
end

return Checkbox
