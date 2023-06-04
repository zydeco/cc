UI = {
    LEFT=-1,
    CENTER=0,
    RIGHT=1,
}

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

local function drawViews(term, views, dx, dy)
    for i=1,#views do
        local view = views[i]
        -- draw this view
        if not view.hidden then
            if view.dirty then
                view.draw(view, term, dx, dy)
                view.dirty = false
            end
            -- draw subviews
            drawViews(term, view.subviews or {}, view.x + dx, view.y + dy)
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

local function run(ui)
    local term = ui.term
    term.setCursorBlink(false)
    ui.running = true
    ui.msg = "started"
    term.setBackgroundColor(colors.white)
    term.setTextColor(colors.black)
    term.clear()
    while ui.running do
        -- draw
        drawViews(ui.term, ui.base.subviews, 1, 1)
        showDebugMsg(ui)
        local event, p1, p2, p3 = os.pullEvent()
        if string.sub(event, 1, 6) ~= "_CCPC_" then
            ui.msg = (event or "") .. "," .. (p1 or "") .. "," .. (p2 or "") .. "," .. (p3 or "")
        end
        if event == "mouse_click" or event == "mouse_up" or event == "monitor_touch" or event == "mouse_scroll" then
            -- mouse event
            local hit, hitX, hitY = hitTest(ui.base.subviews, p2-1, p3-1)
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
        end
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

local function timer(ui, interval, times, action, arg, view)
    local timerID = os.startTimer(interval)
    local timer = {
        interval=interval,
        times=times,
        action=action,
        arg=arg,
        view=view
    }
    ui.timers[timerID] = timer
    return timer
end

require("ui/components")

function UI.new(term)
    local ui = {
        running=false,
        term=term,
        timers={},
    }
    local w, h = term.getSize()
    ui.base = UI.box({x=1, y=1, w=w, h=h, bg=colors.white})
    ui.run = function()
        run(ui)
    end
    ui.stop = function()
        ui.running = false
    end
    ui.add = ui.base.add
    ui.timer = function(interval, times, action, arg, view)
        timer(ui, interval, times, action, arg, view)
    end
    return ui
end
