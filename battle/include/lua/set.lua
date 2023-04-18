--- @class Set
Set = meta.new_type("Set", {})

--- @constructor Set
Set:add_constructor(function()

    local out = meta.new(Set)
    getmetatable(out).n_elements = 0

    out.contains = Set.contains
    out.insert = Set.insert
    out.remove = Set.remove
    out.is_empty = Set.is_empty
    out.size = Set.size

    out.__meta._index = function(this, x)
        return Set.contains(this, x)
    end

    out.__meta.__newindex = function(this, x, new)
        Set.insert(this, new)
    end

    return out
end)

--- @brief check whether element is present in Set
--- @param set
--- @returm boolean
function Set.contains(set, x)

    meta.assert_type(Set, set, "Set.erase", 1)

    return rawget(set, x) == true
end

--- @brief insert into set
--- @param set Set
--- @param x any
function Set.insert(set, x)

    meta.assert_type(Set, set, "Set.erase", 1)

    if rawget(set, x) == true then
        return
    end

    rawset(set, x, true)
    getmetatable(set).n_elements = getmetatable(set).n_elements + 1
end

--- @brief remove from set
--- @param set Set
--- @param x any
function Set.erase(set, x)

    meta.assert_type(Set, set, "Set.erase", 1)

    if rawget(set, x) ~= nil then
        rawset(set, x, nil)
        getmetatable(set).n_elements = getmetatable(set).n_elements - 1
    end
end

--- @brief get number of elements in set
--- @param set
--- @return number
function Set.size(set)

    meta.assert_type(Set, set, "Set.size", 1)
    return getmetatable(set).n_elements
end

--- @brief get number of elements in set
--- @param set
--- @return number
function Set.is_empty(set)

    meta.assert_type(Set, set,  "Set.is_empty", 1)
    return set:size() == 0
end

set = Set()
print(meta.typeof(set))
set:insert(10)
set:insert(11)
set:insert(10)
set:insert(9)
print(set)