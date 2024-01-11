require("ui")

local tw,th = term.current().getSize()
local screen = window.create(term.current(), 1,1,tw,th)
local ui = UI.new(screen)
ui.debug = window.create(term.current(), 1,th,tw,1)
local base = ui

local args = {...}
if #args == 1 then
    -- monitor on side
    base = ui:attachMonitor(args[1], 1.0)
end

local label = UI.Label.new{
    text="Hello, world", 
    x=0, y=0, w=20, h=1, bg=colors.blue, fg=colors.yellow}
base:add(label)

local timeLabel = UI.Label.new{text="1", x=2, y=25, w=5, h=1, bg=colors.red}
timeLabel.align = UI.RIGHT
base:add(timeLabel)
local x = 1
ui:addTimer(1.0, nil, function()
    x = x + 1
    timeLabel.text = x
    timeLabel:redraw()
end)

local charWidth = 1.0 / (tw - 2)
local pbar = UI.ProgressBar.new{
    x=1, y=1, w=tw-2, h=1,
    bg=colors.gray, fg=colors.green, textColor=colors.white, align=UI.LEFT,
    progress=charWidth*6.5, text="x%"
}
pbar.onScroll=function(self, x, y, direction)
    if direction > 0 then
        self:setProgress(self.progress + (charWidth * 0.2))
    else
        self:setProgress(self.progress - (charWidth * 0.2))
    end
    self.text = tostring(math.floor(self.progress * 100)) .. "%"
end
base:add(pbar)

local field = UI.Field.new{
    placeholder={
        text="Hello, world",
        color=colors.lightGray
    },
    text = "hell",
    x=2, y=2, w=16, h=1, 
    bg=colors.blue, fg=colors.yellow,
    onChange=function(self, text)
        label.text = text
        label:redraw()
    end
}
base:add(field)

local btn = UI.Button.new{
    text="{green}By{fg}e{red}!", bg=colors.orange, fg=colors.black, align=UI.CENTER,
    x=15, y=4, w=10, h=3,
    action=function(self)
        ui:stop()
    end}
base:add(btn)

btn:add(
    UI.Label.new{
        x=1, y=2, w=7, h=1,
        text="for now", bg=colors.red, fg=colors.black
    }
)

local menu = UI.Menu.new{
    x=15, y=8, w=10, text="Menu",
    items = {
        { text="New" },
        { text="Old" },
        { text="{red}Red", marked=true, },
        { text="{lightBlue}Choose me!", marked=false },
        { },
        { text="Quit", onSelect = function()
            ui:stop()
        end}
    },
    onSelect = function(self, index, item)
        label.text = item.text
        label.dirty = true
        if item.marked ~= nil then
            item.marked = not item.marked
        end
    end
}
base:add(menu)

base:add(UI.List.new{
    x=4, y=4, w=10, h=7,
    rowHeight=2,
    items={
    "Lorem",
    "ipsum\n{orange}dolor",
    "sit",
    "amet,",
    "consec",
    "adipiscing",
    "elit.",
    "In",
    "out",
    "leo",
    "gravida,",
    "facilisis ",
    "odio",
    "sed,",
    "lobortis",
    "tellus."
    },
    onSelect = function(self, index, text)
        label.text = text
        label:redraw()
        self.ui.msg = text
    end,
    bg=colors.black, bgAlternate=colors.gray, fg=colors.white,
    bgSelected=colors.red,
    fgSelected=colors.black
})

base:add(UI.Label.new{
    x=1, y=12, w=24, h=5,
    bg=colors.lightGray,
    text="Multi{purple}line\n" ..
        "label {blue}with {bg=white}{green}c{orange}o{red}l{yellow}o{black}u{lightBlue}r{brown}s{gray}!\n" ..
        "{align=center}and {brown}different\n" ..
        "alignment\n" ..
        "{align=right}on different lines"
})

base:add(UI.Checkbox.new{
    x=2, y=17, w=10, text="A Checkbox!"
})

base:add(UI.RadioButton.new{
    x=2, y=18, w=8, text="One", group="x", value=1, checked=true
})
base:add(UI.RadioButton.new{
    x=10, y=18, w=8, text="Two", group="x", value=2
})
base:add(UI.RadioButton.new{
    x=18, y=18, w=8, text="Tres", group="x", value=3
})

ui:run()
