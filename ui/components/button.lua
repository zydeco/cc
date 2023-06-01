function UI.button(arg)
    local view = UI.label{
        text=arg.text,
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=arg.bg or colors.black,
        fg=arg.fg or colors.white,
        align=arg.align or 0,
        hidden=arg.hidden,
    }
    if arg.action then
        view.onMouseUp = function(self, x, y, button)
            if button == 1 then
                arg.action(self)
            end
        end
        view.onTouch = function(self, x, y)
            arg.action(self)
        end
    else
        view.onMouseUp = arg.onMouseUp
        view.onTouch = arg.onTouch
    end
    return view
end
