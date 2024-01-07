UI = {
    LEFT=-1,
    CENTER=0,
    RIGHT=1,
    TOP=-1,
    MIDDLE=0,
    BOTTOM=1,
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

local function drawViews(term, views, dx, dy, drawAll)
    local isAfterDirty = drawAll or false
    for i=1,#views do
        local view = views[i]
        view.abs = {
            x = view.x + dx,
            y = view.y + dy
        }
        -- draw this view
        if not view.hidden then
            if view.dirty or isAfterDirty then
                view:draw(term, dx, dy)
                view.dirty = false
                -- TODO: only redraw overlapping siblings
                isAfterDirty = true
            end
            -- draw subviews
            drawViews(term, view.subviews or {}, view.x + dx, view.y + dy, isAfterDirty)
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

local function normalizeKey(k)
    if k == keys.rightCtrl then
        return keys.leftCtrl
    elseif k == keys.rightAlt then
        return keys.leftAlt
    elseif k == keys.rightShift then
        return keys.leftShift
    else
        return k
    end
end

local function modifierKeysDown(keysDown)
    -- returns true if alt or ctrl are down
    for kc,_ in pairs(keysDown) do
        if kc == keys.leftCtrl or kc == keys.leftAlt then
            return true
        end
    end
    return false
end

local function handleKeyboardShortcut(ui)
    if ui.keyHandler == nil or modifierKeysDown(ui.keysDown) then
        local keyList = {}
        for k, _ in pairs(ui.keysDown) do
            table.insert(keyList, k)
        end
        table.sort(keyList)
        local shortcut = ui.keyboardShortcuts[table.concat(keyList, "+")]
        if shortcut then
            shortcut()
            return true
        end
    end
    return false
end

local function handleEvent(ui)
    local event, p1, p2, p3 = os.pullEvent()
    if ui.debug and string.sub(event, 1, 6) ~= "_CCPC_" then
        ui.msg = (event or "") .. "," .. tostring(p1) .. "," .. tostring(p2) .. "," .. tostring(p3)
    end
    if event == "mouse_click" or event == "mouse_up" or event == "monitor_touch" or event == "mouse_scroll" or event == "mouse_drag" then
        -- mouse event
        local subviews = {}
        if event == "monitor_touch" then
            -- touch event on a monitor
            subviews = ui.monitors[p1].base.subviews
        else
            -- actual mouse event - use main screen
            subviews = ui.base.subviews
        end
        local hit, hitX, hitY = hitTest(subviews, p2-1, p3-1)
        if event ~= "mouse_scroll" and hit ~= nil and hit ~= ui.keyboard then
            ui.keyHandler = nil
            ui.keysDown = {}
        end
        local hideMenu = false
        if event == "mouse_click" and ui._menu and hit ~= ui._menu then
            hideMenu = true
        end
        if hit then
            -- onEVENT(self, x, y, ...)
            if event == "mouse_click" and hit.onMouseDown then
                hit.onMouseDown(hit, hitX, hitY, p1)
            elseif event == "mouse_up" and hit.onMouseUp then
                hit.onMouseUp(hit, hitX, hitY, p1)
            elseif event == "monitor_touch" and hit.onTouch then
                hit.onTouch(hit, hitX, hitY, p1) -- monitor
            elseif event == "mouse_scroll" and hit.onScroll then
                hit.onScroll(hit, hitX, hitY, p1) -- direction
            elseif event == "mouse_drag" and hit.onMouseDrag then
                hit.onMouseDrag(hit, hitX, hitY, p1)
            end
        end
        if hideMenu then
            ui:hideMenu()
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
    elseif event == "key" then
        -- onKeyDown(self, key, held)
        if not p2 then
            ui.keysDown[normalizeKey(p1)] = true
            if handleKeyboardShortcut(ui) then
                ui.keyHandler = nil
                return
            end
        end
        if ui.keyHandler and ui.keyHandler.onKeyDown then
            ui.keyHandler.onKeyDown(ui.keyHandler, p1, p2)
        end
    elseif event == "key_up" then
        -- onKeyUp(self, key)
        ui.keysDown[p1] = nil
        if ui.keyHandler and ui.keyHandler.onKeyUp then
            ui.keyHandler.onKeyUp(ui.keyHandler, p1)
        end
    elseif event == "char" and ui.keyHandler and ui.keyHandler.onChar then
        -- onChar(self, char)
        ui.keyHandler.onChar(ui.keyHandler, p1)
    end
end

local function handleField(ui)
    local term = ui.term
    local kh = ui.keyHandler
    if kh and kh ~= ui then
        term = kh.term
        term.setTextColor(kh.cursorColor or kh.fg)
        term.setCursorPos(kh.abs.x + kh.cursor, kh.abs.y)
        term.setCursorBlink(true)
        if term ~= ui.term then
            UI.Keyboard.show(ui, term, kh)
        else
            UI.Keyboard.hide(ui)
        end
    else
        for _, monitor in pairs(ui.monitors) do
            monitor.term.setCursorBlink(false)
        end
        ui.term.setCursorBlink(false)
        UI.Keyboard.hide(ui)
    end
end

local function drawAllViews(ui)
    -- draw base
    drawViews(ui.term, {ui.base}, 0, 0)
    ui.term.flush()
    -- draw monitors
    for _, monitor in pairs(ui.monitors) do
        drawViews(monitor.term, {monitor.base}, 0, 0)
        monitor.term.flush()
    end
end

local function clearScreen(term)
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.white)
    term.setCursorPos(1,1)
    term.clear()
    if term.flush then
        term.flush()
    end
end

function UI:run()
    local ui = self
    if self == nil then error("nil self") end
    local term = ui.term
    term.setCursorBlink(false)
    ui.running = true
    ui.msg = "started"
    ui.keysDown = {}
    clearScreen(term)
    while ui.running do
        drawAllViews(ui)
        showDebugMsg(ui)
        handleField(ui)
        handleEvent(ui)
        handleField(ui)
    end
    clearScreen(term)
    for side, monitor in pairs(ui.monitors) do
        clearScreen(monitor.term)
    end
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
require("ui/term")

function UI.new(term)
    local self = setmetatable({
        running=false,
        term=wrapTerm(term),
        timers={},
        keyboardShortcuts={},
        monitors={}
    }, {__index=UI})
    local w, h = term.getSize()
    self.base = UI.Box.new{x=1, y=1, w=w, h=h, bg=colors.white}
    self.base.ui = self
    self.base.term = self.term
    return self
end

function UI:attachMonitor(side, textScale)
    local monitor = peripheral.wrap(side)
    if textScale ~= nil then
        monitor.setTextScale(textScale)
    end
    local w,h = monitor.getSize()
    local base = UI.Box.new{x=1, y=1, w=w, h=h, bg=colors.white}
    base.ui = self
    base.term = monitor
    self.monitors[side] = {
        base=base,
        term=wrapTerm(monitor)
    }
    clearScreen(monitor)
    return base
end

function UI:add(subview)
    self.base:add(subview)
end

function UI:stop()
    self.running = false
end

function UI:showMenu(menu, rootView)
    (rootView or self.base):add(menu)
    self._menu=menu
end

function UI:hideMenu()
    if self._menu then
        self._menu:removeFromSuperview()
        self._menu = nil
    end
end

function UI:registerKeyboardShortcut(keyList, shortcut)
    table.sort(keyList)
    self.keyboardShortcuts[table.concat(keyList, "+")] = shortcut
end
