function UI.box(arg)
    local view = {
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=arg.bg,
        hidden=arg.hidden or false,
        dirty=true,
        subviews={},
        parent=nil
    }
    view.draw = function(self, term, dx, dy)
        if self.bg then
            local absX = self.x + dx
            local absY = self.y + dy
            term.setBackgroundColor(self.bg)
            local line=string.rep(" ", self.w)
            for y=absY,absY + self.h - 1 do
                term.setCursorPos(absX, y)
                term.write(line)
            end
            --paintutils.drawFilledBox(absX, absY, absX + self.w - 1, absY + self.h - 1, self.bg)
        end
    end
    view.add = function(subview)
        if subview.parent == view then
            return
        elseif subview.parent then
            subview.removeFromSuperview()
        end
        table.insert(view.subviews, subview)
        subview.parent=view
    end
    view.remove = function(subview)
        if subview.parent == view then
            subview.parent = nil
        end
        for i=#view.subviews,1,-1 do
            if view.subviews[i] == subview then
                view.dirty=true
                table.remove(view.subviews, i)
            end
        end
    end
    view.removeFromSuperview = function()
        if view.parent then
            view.parent.remove(view)
        end
    end
    view.hide = function()
        view.hidden = true
        if view.onHide then
            view.onHide()
        end
    end
    view.show = function()
        view.hidden = false
        if view.onShow then
            view.onShow()
        end
    end
    view.redraw = function()
        view.dirty = true
        for i=1,#view.subviews do
            view.subviews[i].redraw()
        end
    end
    return view
end
