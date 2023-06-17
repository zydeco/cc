local Box = require("ui/components/box")
local RadioButton = setmetatable({}, {__index = Box})
RadioButton.__index = RadioButton

function RadioButton.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w or string.len(arg.text or ""),
        h=arg.h or 1,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }), {__index=RadioButton})
    self.text = arg.text or ""
    self.checked = arg.checked or false
    self.fg = arg.fg or colors.black
    self.onChange = arg.onChange
    self.checkSign = arg.checkSign or "@"
    self.group = arg.group
    self.value = arg.value

    self.select = function(self)
        self.checked = true
        for _, subview in ipairs(self.parent.subviews) do
            if subview ~= self and subview.group == self.group then
                subview.checked = false
                subview:redraw()
            end
        end
        if self.onChange then
            self:onChange(self.group, self.value)
        end
        self:redraw()
    end

    self.onMouseUp = function(self, x, y, button)
        if button == 1 then
            self:select()
        end
    end
    self.onTouch = function(self, x, y)
        self:select()
    end
    return self
end

local function textPrefix(self)
    if self.checked then
        return "(" .. self.checkSign .. ") "
    else
        return "( ) "
    end
end

function RadioButton:draw(term, dx, dy)
    Box.draw(self, term, dx, dy)
    local text = textPrefix(self) .. self.text
    term.setCursorPos(self.x + dx, self.y + dy)
    self.ui:drawStyledText(term, text, self.bg, self.fg, self.w, self.align)
end

return RadioButton
