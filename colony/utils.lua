function notImplementedView(name)
    return UI.Label.new{
        x=0,y=0,w=30,h=3,
        bg=colors.white, fg=colors.red,
        text=name .. " not implemented",
    }
end

function formatPos(pos)
    return string.format("%d,%d,%d", pos.x, pos.y, pos.z)
end

function formatTime()
    return string.format("d%dt%04.1f", os.day(), os.time())
end

function digits(n)
    return 1 + math.floor(math.log(n, 10))
end

function sameLocation(a, b)
    return a.x == b.x and a.y == b.y and a.z == b.z
end

function filter(list, keep)
    local filtered = {}
    for i=1,#list do
        if keep(list[i]) then
            filtered[1+#filtered] = list[i]
        end
    end
    return filtered
end

function map(list, mapper)
    local mappedList = {}
    for i=1,#list do
        mappedList[1+#mappedList] = mapper(list[i])
    end
    return mappedList
end

function flatMap(list, mapper)
    local mappedList = {}
    for i=1,#list do
        local mapped = mapper(list[i])
        if mapped ~= nil then
            mappedList[1+#mappedList] = mapped
        end
    end
    return mappedList
end

function countMatching(list, matcher)
    local n = 0
    for i=1,#list do
        if matcher(list[i]) then
            n = n + 1
        end
    end
    return n
end

function countNilValues(list, key)
    return countMatching(list, function(x)
        return x[key] == nil
    end)
end

function countTrueValues(list, key)
    return countMatching(list, function(x)
        return x[key]
    end)
end

function distanceSquared(pos1, pos2)
    local dx = pos1.x - pos2.x
    local dy = pos1.y - pos2.y
    local dz = pos1.z - pos2.z
    return (dx * dx) + (dy * dy) + (dz * dz)
end

function distance(pos1, pos2)
    return math.sqrt(distanceSquared(pos1, pos2))
end

local STRINGS=require("colony/strings")
function translate(key)
    if key == nil then
        return "{bg=red}{white}nil{bg=bg}{fg}"
    end
    local translated = STRINGS[key]
    if translated == nil then
        translated = "{bg=red}{white}" .. key .. "{bg=bg}{fg}"
    end
    return translated
end

function formatWithLevel(name, level, width)
    if string.len(name) > width - 2 then
        if string.sub(name, width-1, width-1) == " " then
            return string.sub(name, 1, width-1) .. level
        end
        name = string.sub(name, 1, width - 2)
        if string.sub(name, -1) == " " then
            return name .. level
        elseif string.sub(name, -2, -2) == " " then
            return string.sub(name, 1, width - 3) .. level
        else
            return string.sub(name, 1, width - 3)  .. ". " .. level
        end
    end
    return name .. " " .. level
end

function formatBuilding(building, width)
    return formatWithLevel(translate(building.name or ("com.minecolonies.building." .. building.type)), building.level, width)
end
