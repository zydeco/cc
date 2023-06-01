function UI.label(arg)
    local view = UI.box{
        x=arg.x,
        y=arg.y,
        w=arg.w or string.len(arg.text or ""),
        h=arg.h or 1,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }
    view.text = arg.text or ""
    view.fg = arg.fg or colors.black
    view.align = arg.align or -1
    local drawSuper = view.draw
    view.draw = function(self, term, dx, dy)
        drawSuper(self, term, dx, dy)
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
    return view
end
