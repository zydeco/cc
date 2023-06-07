-- handle strings with color tags
-- example: "hello, {red}world{fg}!" -> {"hello, ", {tag="red"}, "world", {tag="fg"}, "!"}
local function stringTags(str, defaultTagName)
    defaultTagName = defaultTagName or "tag"
    local parts = {}
    local parseTag = function(tag)
        local equalsPos = string.find(tag, "=")
        if equalsPos == nil then
            return {[defaultTagName]=tag}
        else
            return {[string.sub(tag, 1, equalsPos-1)]=string.sub(tag, equalsPos+1)}
        end
    end
    for nonTag, tag in string.gfind(str .. "{end}", "([^{]-)({[%a=]+})") do
        if string.len(nonTag) > 0 then
            table.insert(parts, nonTag)
        end
        local tagValue = string.sub(tag, 2, -2)
        if tagValue ~= "end" then
            table.insert(parts, parseTag(tagValue))
        end
    end
    return parts
end

local function colorByName(name, bg, fg)
    if name == "bg" then
        return bg
    elseif name == "fg" then
        return fg
    else
        return colors[name]
    end
end

local function setTermStyle(term, tag, bg, fg)
    if tag.fg then
        term.setTextColor(colorByName(tag.fg, bg, fg))
    end
    if tag.bg then
        term.setBackgroundColor(colorByName(tag.bg, bg, fg))
    end
end

local function styledLength(items)
    local length = 0
    for i=1,#items do
        local item = items[i]
        if type(item) == "string" then
            length = length + string.len(item)
        end
    end
    return length
end

local function trimStyledTextBeginning(items, n)
    local toTrim = n
    for i=1,#items do
        if type(items[i]) == "string" then
            local itemLen = string.len(items[i])
            if itemLen <= toTrim then
                -- replace with empty tag
                toTrim = toTrim - itemLen
                items[i] = {}
                if toTrim == 0 then
                    return
                end
            else
                -- trim string
                items[i] = string.sub(items[i], 1 + toTrim)
                return
            end
        end
    end
end

local function trimStyledTextEnd(items, n)
    local toTrim = n
    for i=#items,1,-1 do
        if type(items[i]) == "string" then
            local itemLen = string.len(items[i])
            if itemLen <= toTrim then
                -- replace with empty tag
                toTrim = toTrim - itemLen
                items[i] = {}
                if toTrim == 0 then
                    return
                end
            else
                -- trim string
                items[i] = string.sub(items[i], 1, itemLen - toTrim)
                return
            end
        end
    end
end

local function trimStyledText(items, n, align)
    if align == UI.LEFT then
        trimStyledTextEnd(items, n)
    elseif align == UI.RIGHT then
        trimStyledTextBeginning(items, n)
    elseif align == UI.CENTER then
        trimStyledTextBeginning(items, math.ceil(n/2))
        trimStyledTextEnd(items, math.floor(n/2))
    end
end

-- draw styled text at current position
function UI:drawStyledText(term, str, bg, fg, width, align)
    if str == nil then
        return
    end
    term.setTextColor(fg)
    term.setBackgroundColor(bg)
    local items = stringTags(str, "fg")
    local length = styledLength(items)
    if length > width then
        trimStyledText(items, length - width, align)
    elseif length < width and align ~= UI.LEFT then
        local x,y = term.getCursorPos()
        if align == UI.RIGHT then
            x = x + (width - length)
        elseif align == UI.CENTER then
            x = x + (width - length) / 2
        end
        term.setCursorPos(x, y)
    end
    for i=1,#items do
        local item = items[i]
        if type(item) == "string" then
            term.write(item)
        elseif type(item) == "table" then
            setTermStyle(term, item, bg, fg)
        end
    end
end