local Box = require("ui/components/box")
local TabBar = setmetatable({}, {__index = Box})
TabBar.__index = TabBar

function TabBar.new(arg)
    local self = setmetatable(Box.new({
        x=arg.x,
        y=arg.y,
        w=arg.w,
        h=arg.h,
        bg=arg.bg or colors.white,
        hidden=arg.hidden
    }), {__index=TabBar})
    local tabs = arg.tabs or {}
    if #tabs == 0 then
        return self
    end
    -- calculate tab sizes
    local tabWidth = math.floor(arg.w / #tabs)
    local tabMargin = math.floor((arg.w - (tabWidth * #tabs)) / 2)
    if tabMargin < 0 then
        error("Too many tabs for box width")
    end

    -- add selection label
    self.label = UI.Label.new{
        x=0, y=1, w=arg.w, h=1,
        text="Tab Bar", align=UI.CENTER,
    }
    self:add(self.label)
    self.label.onMouseDown = function()
        if self.currentTab and self.currentTab.onShow then
            self.currentTab:onShow()
        end
    end
    self.label.onTouch = self.label.onMouseDown
    self.tabs=tabs

    -- add content view
    -- holds content views for all tabs, switches hiding/showing them
    self.contentView = UI.Box.new{
        x=0, y=2, w=arg.w, h=arg.h-2, bg=colors.red
    }
    self:add(self.contentView)
    self.currentTab=tabs[1].content

    -- add buttons
    local x = tabMargin
    for i=1,#tabs do
        local tab = tabs[i]
        local button = UI.Button.new{
            x=x, y=0, w=tabWidth, h=1,
            text=tab.key,
            bg=tab.bg,
            fg=tab.fg,
            action=function()
                self:selectTab(i)
            end
        }
        self:add(button)
        if tab.content then
            tab.content.hidden = true
            self.contentView:add(tab.content)
        end
        x = x + tabWidth
    end

    -- select first tab
    self:selectTab(1)
    return self
end

function TabBar:selectTab(i)
    if self.selectedTab == i then
        if self.currentTab.onShow then
            self.currentTab:onShow()
        end
        return
    end
    self.selectedTab = i
    local tab = self.tabs[i]
    self.label.text=tab.name
    self.label.bg=tab.bg
    self.label.fg=tab.fg
    self.label:redraw()
    -- hide current tab
    self.currentTab.hidden = true
    if self.currentTab.onHide then
        self.currentTab:onHide()
    end
    self.currentTab = tab.content
    if tab.content then
        -- show new tab
        self.currentTab.hidden = false
        if self.currentTab.onShow then
            self.currentTab:onShow()
        end
    end
    self.contentView:redraw()
end

return TabBar
