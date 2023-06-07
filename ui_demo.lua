require("ui")

local tw,th = term.current().getSize()
local screen = window.create(term.current(), 1,1,tw,th)
local w,h = screen.getSize()
local ui = UI.new(screen)
ui.debug = window.create(term.current(), 1,th,tw,1)

local label = UI.Label.new{
    text="Hello, world", 
    x=0, y=0, w=20, h=1, bg=colors.blue, fg=colors.yellow}
ui:add(label)

local timeLabel = UI.Label.new{text="1", x=2, y=25, w=5, h=1, bg=colors.red}
timeLabel.align = UI.RIGHT
ui:add(timeLabel)
local x = 1
ui:addTimer(1.0, nil, function()
    x = x + 1
    timeLabel.text = x
    timeLabel:redraw()
end)

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
ui:add(field)

local btn = UI.Button.new{
    text="{green}By{fg}e{red}!", bg=colors.orange, fg=colors.black, align=UI.CENTER,
    x=3, y=14, w=10, h=3,
    action=function(self)
        ui:stop() 
    end}
ui:add(btn)

btn:add(
    UI.Label.new{
        x=1, y=2, w=7, h=1,
        text="for now", bg=colors.red, fg=colors.black
    }
)

ui:add(UI.List.new{
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
    fgSelected=colors.black})

ui:run()
