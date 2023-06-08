UI = {
    LEFT=-1,
    CENTER=0,
    RIGHT=1,
}
UI.__index = UI

local function hitTest(views, x, y)
    if #views == 0 then
        return nil
    end
    for i=#views, 1, -1 do
        local view = views[i]
        if view.hidden == false then
            local subviewHit, shX, shY = hitTest(view.subviews or {}, x - view.x, y - view.y)
            if subviewHit then
                return subviewHit, shX, shY
            elseif x >= view.x and y >= view.y and x < view.x+view.w and y < view.y+view.h then
                return view, x - view.x, y - view.y
            end
        end
    end
    return nil
end

local function hasView(views, target)
    if #views == 0 then
        return nil
    end
    for i=1, #views do
        local view = views[i]
        if view == target then
            return true
        elseif hasView(view.subviews, target) then
            return true
        end
    end
    return false
end

local function drawViews(ui, views, dx, dy)
    local term = ui.term
    for i=1,#views do
        local view = views[i]
        view.abs = {
            x = view.x + dx,
            y = view.y + dy
        }
        -- draw this view
        if not view.hidden then
            if view.dirty then
                view:draw(term, dx, dy)
                view.dirty = false
            end
            -- draw subviews
            drawViews(ui, view.subviews or {}, view.x + dx, view.y + dy)
        end
    end
end

local function showDebugMsg(ui)
    if ui.msg and type(ui.debug) == "table" then
        local term = ui.debug
        local x,y=term.getSize()
        term.setCursorPos(1,1)
        term.write(ui.msg .. string.rep(" ", x - string.len(ui.msg)))
    end
end

local function handleEvent(ui)
    local event, p1, p2, p3 = os.pullEvent()
    if string.sub(event, 1, 6) ~= "_CCPC_" then
        ui.msg = (event or "") .. "," .. (p1 or "") .. "," .. (p2 or "") .. "," .. (p3 or "")
    end
    if event == "mouse_click" or event == "mouse_up" or event == "monitor_touch" or event == "mouse_scroll" then
        -- mouse event
        local hit, hitX, hitY = hitTest(ui.base.subviews, p2-1, p3-1)
        if event ~= "mouse_scroll" then
            ui.keyHandler = nil
        end
        if hit then
            -- onEVENT(self, x, y, ...)
            if event == "mouse_click" and hit.onMouseDown then
                hit.onMouseDown(hit, hitX, hitY, p1)
            elseif event == "mouse_up" and hit.onMouseUp then
                hit.onMouseUp(hit, hitX, hitY, p1)
            elseif event == "monitor_touch" and hit.onTouch then
                hit.onTouch(hit, hitX, hitY)
            elseif event == "mouse_scroll" and hit.onScroll then
                hit.onScroll(hit, hitX, hitY, p1) -- direction
            end
        end
    elseif event == "timer" and ui.timers[p1] then
        local timer = ui.timers[p1]
        ui.timers[p1] = nil
        -- fire
        if timer.view == nil or (timer.view.hidden == false and hasView(ui.views, timer.view)) then
            timer.action(timer.arg)
        end
        -- reschedule
        if timer.times ~= nil then
            timer.times = timer.times - 1
        end
        if timer.times == nil or timer.times > 0 then
            ui.timers[os.startTimer(timer.interval)] = timer
        end
    elseif event == "key" and ui.keyHandler and ui.keyHandler.onKeyDown then
        -- onKeyDown(self, key, held)
        ui.keyHandler.onKeyDown(ui.keyHandler, p1, p2)
    elseif event == "key_up" and ui.keyHandler and ui.keyHandler.onKeyUp then
        -- onKeyUp(self, key)
        ui.keyHandler.onKeyUp(ui.keyHandler, p1)
    elseif event == "char" and ui.keyHandler and ui.keyHandler.onChar then
        -- onChar(self, char)
        ui.keyHandler.onChar(ui.keyHandler, p1)
    end
end

local function handleField(ui)
    local term = ui.term
    local kh = ui.keyHandler
    if kh then
        term.setTextColor(kh.cursorColor or kh.fg)
        term.setCursorPos(kh.abs.x + kh.cursor, kh.abs.y)
        term.setCursorBlink(true)
    else
        term.setCursorBlink(false)
    end
end

function UI:run()
    local ui = self
    if self == nil then error("nil self") end
    local term = ui.term
    term.setCursorBlink(false)
    ui.running = true
    ui.msg = "started"
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    while ui.running do
        drawViews(ui, ui.base.subviews, 1, 1)
        showDebugMsg(ui)
        handleField(ui)
        handleEvent(ui)
        handleField(ui)
    end
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1,1)
    term.clear()
    if type(ui.debug) == "table" then
        ui.debug.clear()
    end
    term.setCursorBlink(true)
end

function UI:addTimer(interval, times, action, arg, view)
    local timerID = os.startTimer(interval)
    local timer = {
        interval=interval,
        times=times,
        action=action,
        arg=arg,
        view=view
    }
    self.timers[timerID] = timer
    return timer
end

require("ui/components")

function UI.new(term)
    local self = setmetatable({
        running=false,
        term=term,
        timers={},
    }, {__index=UI})
    local w, h = term.getSize()
    self.base = UI.Box.new{x=1, y=1, w=w, h=h, bg=colors.white}
    self.base.ui = self
    return self
end

function UI:add(subview)
    self.base:add(subview)
end

function UI:stop()
    self.running = false
end
