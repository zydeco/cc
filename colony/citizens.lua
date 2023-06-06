return function(colony, contentWidth, contentHeight)

local box = UI.Box.new{
    x=0,y=0,w=contentWidth,h=contentHeight,bg=colors.white
}

-- sizes
local margin = 2
local labelX = margin
local labelW = 11
local valueX = labelX + labelW + 1
local valueW = contentWidth - valueX - (2 * margin)
local infoW = contentWidth - (2*margin)
local y = 1

-- filter

-- list

-- detail?

return box
end
