require("ui/text")
local Box = require("ui/components/box")
local ProgressBar = setmetatable({}, {__index = Box})
ProgressBar.__index = ProgressBar

function ProgressBar.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h or 1,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }), {__index=ProgressBar})
    self.text = arg.text or nil
    self.progress = arg.progress or 0.0
    self.fg = arg.fg or colors.black
    self.textColor = arg.textColor or colors.gray
    self.align = arg.align or UI.LEFT
    self.verticalAlign = arg.verticalAlign or UI.TOP
    return self
end

local function drawLine(term, absX, absY, h, line)
    for y=absY,absY + h - 1 do
        term.setCursorPos(absX, y)
        term.write(line)
    end
end

function ProgressBar:setProgress(progress)
    self.progress = progress
    if self.progress > 1.0 then
        self.progress = 1.0
    elseif self.progress < 0.0 then
        self.progress = 0.0
    end
    self:redraw()
end

function ProgressBar:draw(term, dx, dy)
    local absX = self.x + dx
    local absY = self.y + dy

    -- draw full part
    term.setBackgroundColor(self.fg)
    local full = math.floor(self.progress * self.w)
    local line=string.rep(" ", full)
    drawLine(term, absX, absY, self.h, line)

    -- draw empty part
    local empty = math.floor((1.0 - self.progress) * self.w)
    line = string.rep(" ", empty)
    if full + empty < self.w then
        local diff = (self.progress * self.w) - full
        if diff >= 0.4 then
            line = "\x95" .. line
        else
            line = line .. " "
        end
    end
    term.setTextColor(self.fg)
    term.setBackgroundColor(self.bg)
    drawLine(term, absX + full, absY, self.h, line)

    -- draw text
    if self.text ~= nil and self.text ~= "" then
        local lines = UI.textLines(self.text)
        local widestLine = 0
        for i=1,math.min(self.h, #lines) do
            widestLine = math.max(widestLine, UI.strlen(lines[i]))
        end
        local textWidth = full
        local textOffset = 0
        local textBg = self.fg
        if textWidth < widestLine then
            textWidth = empty
            textOffset = self.w - empty
            textBg = self.bg
        end
        self._lines = lines
        local marginTop = 0
        if self.verticalAlign == UI.CENTER then
            marginTop = math.floor((self.h - #lines) / 2)
        elseif self.verticalAlign == UI.BOTTOM then
            marginTop = self.h - #lines
        end
        self._marginTop = marginTop
        for i=1,math.min(self.h, #lines) do
            term.setCursorPos(self.x + dx + textOffset, self.y + dy + marginTop + i - 1)
            self.ui:drawStyledText(term, lines[i], textBg, self.textColor, textWidth, self.align)
        end
    end
end

return ProgressBar
