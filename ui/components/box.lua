local Box = {}
Box.__index = Box

local function forEachSubview(view, f)
    f(view)
    local subviews = view.subviews or {}
    for i=1, #subviews do
        forEachSubview(subviews[i], f)
    end
end

function Box.new(arg)
    local self = setmetatable({
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=arg.bg,
        hidden=arg.hidden or false,
        dirty=true,
        subviews={},
        parent=nil
    }, Box)
    return self
end

function Box:add(subview)
    if subview.parent == self then
        return
    elseif subview.parent then
        subview:removeFromSuperview()
    end
    table.insert(self.subviews, subview)
    subview.parent = self
    subview.term = self.term
    forEachSubview(self, function(view)
        view.ui = self.ui
        view.dirty = true
    end)
end

function Box:draw(term, dx, dy)
    if self.bg then
        local absX = self.x + dx
        local absY = self.y + dy
        term.setBackgroundColor(self.bg)
        local line=string.rep(" ", self.w)
        for y=absY,absY + self.h - 1 do
            term.setCursorPos(absX, y)
            term.write(line)
        end
    end
end

function Box:remove(subview)
    if subview.parent == self then
        subview.parent = nil
    end
    for i=#self.subviews,1,-1 do
        if self.subviews[i] == subview then
            table.remove(self.subviews, i)
        end
    end
    forEachSubview(self, function (view)
        view.dirty=true
    end)
end

function Box:removeFromSuperview()
    if self.parent then
        self.parent:remove(self)
    end
end

    
function Box:hide()
    self.hidden = true
    if self.onHide then
        self.onHide()
    end
end

function Box:show()
    self.hidden = false
    if self.onShow then
        self.onShow()
    end
end

function Box:redraw()
    self.dirty = true
    for i=1,#self.subviews do
        self.subviews[i]:redraw()
    end
end

return Box