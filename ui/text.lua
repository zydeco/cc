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
    for nonTag, tag in string.gfind(str .. "{end}", "([^{]-)({[^}]+})") do
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
    elseif colors[name] ~= nil then
        return colors[name]
    else
        error("invalid color " .. name)
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

-- length of string without counting style tags
function UI.strlen(str)
    return string.len(string.gsub(str, "{[^}]+}", ""))
end

local UI_TEXT_DEFAULT_TAG = "fg"

-- draw styled text at current position
function UI:drawStyledText(term, str, bg, fg, width, align)
    if str == nil then
        return
    end
    term.setTextColor(fg)
    term.setBackgroundColor(bg)
    local items = stringTags(str, UI_TEXT_DEFAULT_TAG)
    local length = styledLength(items)
    local pad = nil
    -- first item can override alignment
    if type(items[1]) == "table" and items[1].align then
        align = UI[string.upper(items[1].align)] or align
    end
    if length > width then
        trimStyledText(items, length - width, align)
    elseif length < width then
        if align == UI.RIGHT then
            term.write(string.rep(" ", width - length))
        elseif align == UI.CENTER then
            local padSize = math.floor((width - length) / 2)
            term.write(string.rep(" ", padSize))
            pad = string.rep(" ", math.ceil((width - length) / 2))
        elseif align == UI.LEFT then
            pad = string.rep(" ", width - length)
        end
    end
    for i=1,#items do
        local item = items[i]
        if type(item) == "string" then
            term.write(item)
        elseif type(item) == "table" then
            setTermStyle(term, item, bg, fg)
        end
    end
    if pad ~= nil then
        term.write(pad)
    end
end

function UI.textLines(str)
    local lines = {}
    for line in string.gmatch(str, "[^\n]+") do
        lines[#lines + 1] = line
    end
    return lines
end

function UI.textTagAt(str, width, align, tagName, col)
    local items = stringTags(str, UI_TEXT_DEFAULT_TAG)
    local length = styledLength(items)
    local x = 0
    local tagValue = nil
    -- first item can override alignment
    if type(items[1]) == "table" and items[1].align then
        align = UI[string.upper(items[1].align)] or align
    end
    if length > width then
        trimStyledText(items, length - width, align)
    elseif length < width and align ~= UI.LEFT then
        if align == UI.RIGHT then
            x = (width - length)
        elseif align == UI.CENTER then
            x = math.floor((width - length) / 2)
        end
    end
    if x > col then
        return tagValue
    end
    for i=1,#items do
        local item = items[i]
        if type(item) == "string" then
            x = x + string.len(item)
            if x > col then
                return tagValue
            end
        elseif type(item) == "table" and item[tagName] then
            tagValue = item[tagName]
        end
    end
end
