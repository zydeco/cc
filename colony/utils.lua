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

function table.keys(t)
    local keyset={}
    for k,v in pairs(t) do
      keyset[1+#keyset]=k
    end
    return keyset
end

function table.shallowCopy(t)
    local copy={}
    for k,v in pairs(t) do
        copy[k] = v
    end
    return copy
end

function table.flatten(t)
    local flattened={}
    for i,v in ipairs(t) do
        if type(v) == "table" then
            for j,w in ipairs(table.flatten(v)) do
               table.insert(flattened, w)
            end
        else
           table.insert(flattened, v)
        end
    end
    return flattened
end

function table.rep(value, number)
    local result={}
    while #result < number do
        table.insert(result, value)
    end
    return result
end

function table.removeOneValue(list, value)
    for i = 1, #list do
        if list[i] == value then
            table.remove(list, i)
            return true
        end
    end
    return false
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
function translate(key, highlight_missing)
    if type(key) ~= "string" then
        return "{bg=red}{white}TABLE?{bg=bg}{fg}"
    end
    if key == nil then
        return "{bg=red}{white}nil{bg=bg}{fg}"
    end
    local translated = STRINGS[key]
    if translated == nil then
        if highlight_missing then
            translated = "{bg=red}{white}" .. key .. "{bg=bg}{fg}"
        else
            translated = key
        end
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

function getRateColor(rate)
    if rate < 0.4 then
        return "red"
    elseif rate < 0.6 then
        return "orange"
    elseif rate < 0.9 then
        return "green"
    else
        return "blue"
    end
end

function getById(list, id)
    for index, item in ipairs(list) do
        if item.id == id then
            return item
        end
    end
    error("item with id " .. id .. " not found in list")
end

function shouldShowRow(row, filterText)
    if filterText == "" then
        return true
    end
    -- match all tags
    for word in string.gmatch(filterText, "([^%s]+)") do
        word = string.lower(word)
        local tagMatch = false
        for index, tag in ipairs(row.tags) do
            if tag == nil or tag == "" then
                -- skip empty tag
            elseif string.sub(tag, 1, 1) == "#" then
                -- match whole tag?
                if word == tag then
                    tagMatch = true
                    break
                end
            elseif string.find(string.lower(tag), word) ~= nil then
                -- match partial
                tagMatch = true
                break
            end
        end
        if not tagMatch then
            return false
        end
    end
    return true
end

