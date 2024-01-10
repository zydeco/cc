local Label = require("ui/components/label")
local Button = setmetatable({}, {__index = Label})
Button.__index = Button

function Button.new(arg)
    local self = setmetatable(Label.new({
        text=arg.text,
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=arg.bg or colors.black,
        fg=arg.fg or colors.white,
        align=arg.align or UI.CENTER,
        verticalAlign=arg.verticalAlign or UI.MIDDLE,
        hidden=arg.hidden,
    }), {__index=Button})
    self.action = arg.action
    if arg.onMouseUp == nil then
        self.onMouseUp = function(self, x, y, button)
            if button == 1 and self.action then
                self.action(self)
            end
        end
    else
        self.onMouseUp = arg.onMouseUp
    end
    if arg.onTouch == nil then
        self.onTouch = function(self, x, y)
            if self.action then
                self.action(self)
            end
        end
    else
        self.onTouch = arg.onTouch
    end
    return self
end

return Button
