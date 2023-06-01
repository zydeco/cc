function UI.tabBar(arg)
    local box=UI.box(arg)
    local tabs = arg.tabs or {}
    if #tabs == 0 then
        return box
    end
    -- calculate tab sizes
    local tabWidth = math.floor(box.w / #tabs)
    local tabMargin = math.floor((box.w - (tabWidth * #tabs)) / 2)
    if tabMargin < 0 then
        error("Too many tabs for box width")
    end

    -- add selection bar
    local bar = UI.label{
        x=0, y=1, w=box.w, h=1,
        text="Tab Bar", align=0,
    }
    box.add(bar)
    bar.tabs=tabs

    -- add content view
    -- holds content views for all tabs, switches hiding/showing them
    bar.contentView = UI.box{
        x=0, y=2, w=box.w, h=box.h-2, bg=colors.red
    }
    box.add(bar.contentView)

    box.currentTab=tabs[1].content
    bar.selectTab = function(i)
        if bar.selectedTab == i then
            return
        end
        bar.selectedTab=i
        local tab = bar.tabs[i]
        bar.text=tab.name
        bar.bg=tab.bg
        bar.fg=tab.fg
        bar.redraw()
        -- hide current tab
        box.currentTab.hidden = true
        if box.currentTab.onHide then
            box.currentTab.onHide(box.currentTab)
        end
        box.currentTab = tab.content
        if tab.content then
            -- show new tab
            box.currentTab.hidden = false
            box.currentTab.parent.redraw()
            if box.currentTab.onShow then
                box.currentTab.onShow(bar.currentTab)
            end
        end
    end

    -- add buttons
    local selector = UI.label{
        x=0, y=1, 
    }
    local x = tabMargin
    for i=1,#tabs do
        local tab = tabs[i]
        local button = UI.button{
            x=x, y=0, w=tabWidth, h=1,
            text=tab.key,
            bg=tab.bg,
            fg=tab.fg,
            action=function()
                bar.selectTab(i)
            end
        }
        box.add(button)
        if tab.content then
            tab.content.hidden = true
            bar.contentView.add(tab.content)
        end
        x = x + tabWidth
    end

    -- select first tab
    bar.selectTab(1)
    return box
end
