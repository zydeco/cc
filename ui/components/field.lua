local function blur(ui)
    local field = ui.keyHandler
    if field ~= nil then
        if field.onBlur then
            field.onBlur(field)
        end
        field.redraw()
        ui.keyHandler = nil
    end
end

local function focus(ui, field)
    if ui.keyHandler and ui.keyHandler ~= field then
        blur(ui)
    end
    ui.keyHandler = field
    if field == nil then
        return
    end
    field.cursor = string.len(field.text)
    if field.onFocus then
        field.onFocus(field)
    end
    field.redraw()
end

local function onKeyDown(self, key)
    if key == keys.left then
        self.cursor = math.max(0, self.cursor - 1)
    elseif key == keys.right then
        self.cursor = math.min(string.len(self.text), self.cursor + 1)
    elseif key == keys.backspace and self.cursor > 0 then
        local text = self.text
        local left = string.sub(text, 1, self.cursor - 1)
        local right = string.sub(text, self.cursor + 1, -1)
        self.text = left .. right
        self.cursor = math.max(0, self.cursor - 1)
        if self.onChange then
            self.onChange(self, self.text)
        end
    elseif key == keys.delete then
        self.text = ""
        self.cursor = 0
    elseif key == keys.tab or key == keys.enter then
        focus(self.ui, self.nextField)
    elseif key == keys.home or key == keys.up then
        self.cursor = 0
    elseif key == keys["end"] or key == keys.down then
        self.cursor = string.len(self.text)
    end
    self.redraw()
end

local function onChar(self, char)
    local text = self.text
    local left = string.sub(text, 1, self.cursor)
    local right = string.sub(text, self.cursor + 1, -1)
    self.text = left .. char .. right
    self.cursor = self.cursor + 1
    if self.onChange then
        self.onChange(self, self.text)
    end
    self.redraw()
end

function UI.field(arg)
    local view = UI.label{
        text=arg.text or "",
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=arg.bg or colors.black,
        fg=arg.fg or colors.white,
        align=arg.align or UI.LEFT,
        hidden=arg.hidden,
    }
    view.placeholder = arg.placeholder
    view.onMouseUp = function(self, x, y, button)
        if button == 1 then
            focus(self.ui, self)
        end
    end
    local drawSuper = view.draw
    view.draw = function(self, term, dx, dy)
        local isActive = self.ui.keyHandler
        local text = self.text
        local fg = self.fg
        if text == "" then
            -- placeholder
            self.text = self.placeholder.text
            self.fg = self.placeholder.color
        end
        drawSuper(self, term, dx, dy)
        -- restore
        self.text = text
        self.fg = fg
    end
    view.onKeyDown = onKeyDown
    view.onChar = onChar
    view.onChange = arg.onChange
    return view
end
