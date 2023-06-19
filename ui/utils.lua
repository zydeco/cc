function UI.map(list, mapper)
    local mappedList = {}
    for i=1,#list do
        mappedList[1+#mappedList] = mapper(list[i])
    end
    return mappedList
end
