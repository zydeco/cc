local blitMap = {
    [ colors.white ] = "0",
    [ colors.orange ] = "1",
    [ colors.magenta ] = "2",
    [ colors.lightBlue ] = "3",
    [ colors.yellow ] = "4",
    [ colors.lime ] = "5",
    [ colors.pink ] = "6",
    [ colors.gray ] = "7",
    [ colors.lightGray ] = "8",
    [ colors.cyan ] = "9",
    [ colors.purple ] = "a",
    [ colors.blue ] = "b",
    [ colors.brown ] = "c",
    [ colors.green ] = "d",
    [ colors.red ] = "e",
    [ colors.black ] = "f",
}

local function createFill(w, h, fg, bg, fillChar)
    local lines = {}
    local text = string.rep(fillChar or " ", w)
    local fgText = string.rep(blitMap[fg], w)
    local bgText = string.rep(blitMap[bg], w)
    while #lines < h do
        table.insert(lines, {text, fgText, bgText})
    end
    return lines
end

local function stringInsert(base, pos, replacement)
    assert(pos > 0, "Insertion position must be > 0")
    local len = string.len(replacement)
    assert(string.len(base) >= pos + len - 1, "Insertion out of bounds")
    return string.sub(base, 1, pos-1) .. replacement .. string.sub(base, pos + len)
end

function wrapTerm(term)
    local wt = {
        term=term,
        blink=term.getCursorBlink(),
        bg=term.getBackgroundColor(),
        fg=term.getTextColor(),
        direct=false,
        dirty=false
    }

    wt.x, wt.y = term.getCursorPos()
    wt.w, wt.h = term.getSize()
    wt.lines = createFill(wt.w, wt.h, wt.fg, wt.bg)
    wt.previousLines = createFill(wt.w, wt.h, wt.fg, wt.bg, "x")

    function wt.clear()
        wt.lines = createFill(wt.w, wt.h, wt.fg, wt.bg)
        wt.dirty = true
        if wt.direct then
            term.clear()
        end
    end

    function wt.getCursorPos()
        return wt.x, wt.y
    end

    function wt.setCursorPos(x, y)
        assert(x > 0 and y > 0, "cursorPos out of bounds (small)")
        wt.x = x
        wt.y = y
        if wt.direct then
            term.setCursorPos(x, y)
        end
    end

    function wt.getCursorBlink()
        return wt.blink
    end

    function wt.setCursorBlink(blink)
        wt.blink = blink
        if blink then
            term.setTextColor(wt.fg)
            term.setCursorPos(wt.x, wt.y)
        end
        term.setCursorBlink(blink)
    end

    function wt.getBackgroundColor()
        return wt.bg
    end

    function wt.setBackgroundColor(color)
        wt.bg = color
        if wt.direct then
            term.setBackgroundColor(color)
        end
    end

    function wt.getTextColor()
        return wt.fg
    end

    function wt.setTextColor(color)
        wt.fg = color
        if wt.direct then
            term.setTextColor(color)
        end
    end

    function wt.getSize()
        return wt.w, wt.h
    end

    function wt.write(text)
        if wt.direct then
            term.write(text)
        end
        if wt.lines[wt.y] == nil then
            return
        end
        local len = string.len(text)
        local maxLen = wt.w - wt.x + 1
        if len > maxLen then
            len = maxLen
            text = string.sub(text, 1, len)
        end
        local fg = string.rep(blitMap[wt.fg], len)
        local bg = string.rep(blitMap[wt.bg], len)
        wt.lines[wt.y][1] = stringInsert(wt.lines[wt.y][1], wt.x, text)
        wt.lines[wt.y][2] = stringInsert(wt.lines[wt.y][2], wt.x, fg)
        wt.lines[wt.y][3] = stringInsert(wt.lines[wt.y][3], wt.x, bg)
        wt.x = wt.x + len
        wt.dirty = true
    end

    function wt.blit(text, fg, bg)
        if wt.direct then
            term.blit(text, fg, bg)
        end
        if wt.lines[wt.y] == nil then
            return
        end
        local w = wt.w - wt.x + 1
        wt.lines[wt.y][1] = stringInsert(wt.lines[wt.y][1], wt.x, text:sub(1,w))
        wt.lines[wt.y][2] = stringInsert(wt.lines[wt.y][2], wt.x, fg:sub(1,w))
        wt.lines[wt.y][3] = stringInsert(wt.lines[wt.y][3], wt.x, bg:sub(1,w))
        wt.dirty = true
    end

    local function hasChangedLine(y)
        local line = wt.lines[y]
        local prev = wt.previousLines[y]
        return line[1] ~= prev[1] or line[2] ~= prev[2] or line[3] ~= prev[3]
    end

    function wt.draw()
        for y = 1, wt.h do
            if hasChangedLine(y) then
                local line = wt.lines[y]
                term.setCursorPos(1, y)
                term.blit(line[1], line[2], line[3])
                wt.previousLines[y] = {line[1], line[2], line[3]}
            end
        end
        if wt.blink then
            term.setTextColor(wt.fg)
            term.setCursorPos(wt.x, wt.y)
        end
        wt.dirty = false
    end

    function wt.flush(force)
        if force or (wt.dirty and not wt.direct) then
            wt.draw()
        end
    end

    return wt
end
