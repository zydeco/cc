function notImplementedView(name)
    return UI.Label.new{
        x=0,y=0,w=30,h=3,
        bg=colors.white, fg=colors.red,
        text=name .. " not implemented",
    }
end

function formatTime()
    return string.format("d%dt%04.1f", os.day(), os.time())
end

function digits(n)
    return 1 + math.floor(math.log(n, 10))
end

function filter(list, keep)
    local filtered = {}
    for i=1,#list do
        if keep(list[i]) then
            filtered[#filtered] = list[i]
        end
    end
    return filtered
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
