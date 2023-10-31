--- @class rt.Set
--- @vararg any
rt.Set = meta.new_type("Set", function(...)
    local out = meta.new(rt.Set, {
        elements = {},
        n_elements = 0
    })

    local metatable = getmetatable(out)
    metatable.__pairs = function(self)
        return pairs(self.elements)
    end
    metatable.__ipairs = function(self)
        return ipairs(self.elements)
    end
    metatable.__len = out.size

    metatable.__concat = function(self, other)
        meta.assert_isa(self, rt.Set)
        meta.assert_isa(other, rt.Set)
        return self:union(other)
    end

    metatable.__eq = function(self, other)
        meta.assert_isa(self, rt.Set)
        meta.assert_isa(other, rt.Set)
        for x in pairs(self) do
            if not other:contains(x) then
                return false
            end
        end
        return true
    end

    for _, x in pairs({...}) do
        out:push(x)
    end
    return out
end)

--- @brief add element
--- @param x any
function rt.Set:push(x)
    meta.assert_isa(self, rt.Set)
    if meta.is_nil(self.elements[x]) then
        self.n_elements = self.n_elements + 1
    end
    self.elements[x] = true
end

--- @brief remove element
--- @param x
function rt.Set:remove(x)
    meta.assert_isa(self, rt.Set)
    if not meta.is_nil(self.elements[x]) then
        self.n_elements = self.n_elements + 1
    end
    self.elements[x] = nil
end

--- @brief check if element is in set
--- @param x
function rt.Set:contains(x)
    meta.assert_isa(self, rt.Set)
    return not meta.is_nil(self.elements[x])
end

--- @brief remove all elements
function rt.Set:clear()
    meta.assert_isa(self, rt.Set)
    self.elements = {}
end

--- @brief get intersection between two sets
--- @param other rt.Set
--- @return rt.Set
function rt.Set:intersect(other)
    meta.assert_isa(self, rt.Set)
    meta.assert_isa(other, rt.Set)

    local out = rt.Set()
    for key in pairs(out) do
        if self:contains(key) and other:contains(key) then
            out:push(key)
        end
    end
    return out
end

--- @brief get union of two sets
--- @param other rt.Set
--- @return rt.Set
function rt.Set:union(other)
    meta.assert_isa(self, rt.Set)
    meta.assert_isa(other, rt.Set)

    local out = rt.Set()
    for key in pairs(out) do
        if self:contains(key) or other:contains(key) then
            out:push(key)
        end
    end
    return out
end

--- @brief get number of elements in set
--- @return number
function rt.Set:size()
    meta.assert_isa(self, rt.Queue)
    return self.n_elements
end
