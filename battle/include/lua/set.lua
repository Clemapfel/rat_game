--- @class Set
Set = meta.new_type("Set", {})

--- @constructor Set
--- @param to_add table
meta.set_constructor(Set, function(this, to_add)

    local out = meta.new(Set)
    getmetatable(out).n_elements = 0

    out.__meta.elements = {}
    out.contains = Set.contains
    out.insert = Set.insert
    out.erase = Set.erase
    out.is_empty = Set.is_empty
    out.size = Set.size

    out.__meta.__index = function(this, x)
        return this:contains(x)
    end

    out.__meta.__newindex = function(this, x, new)
        if meta.is_boolean(new) then
            getmetatable(this).elements[x] = new
        else
            error("[ERROR] In Set.__newindex: Argument #2 has to bool")
        end
    end

    out.__meta.__pairs = function(this)
        return pairs(this.__meta.elements)
    end

    out.__meta.__ipairs = function(this)
        return pairs(this.__meta.elements) --sic
    end

    if meta.is_table(to_add) then
        for _, value in ipairs(to_add) do
            out:insert(value)
        end
    elseif to_add ~= nil then
        out:insert(to_add)
    end

    return out
end)

--- @brief check whether element is present in Set
--- @param set
--- @returm boolean
function Set.contains(set, x)

    meta.assert_type(Set, set, "Set.erase", 1)
    return getmetatable(set).elements[x] == true
end

--- @brief insert into set
--- @param set Set
--- @param x any
--- @return boolean
function Set.insert(set, x)

    meta.assert_type(Set, set, "Set.erase", 1)

    if getmetatable(set).elements == true then
        return false
    end

    getmetatable(set).elements[x] = true
    getmetatable(set).n_elements = getmetatable(set).n_elements + 1
    return true
end

--- @brief remove from set
--- @param set Set
--- @param x any
--- @return boolean
function Set.erase(set, x)

    meta.assert_type(Set, set, "Set.erase", 1)

    if getmetatable(set).elements[x] ~= nil then
        getmetatable(set).elements[x] = nil
        getmetatable(set).n_elements = getmetatable(set).n_elements - 1
        return true
    end

    return false
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
