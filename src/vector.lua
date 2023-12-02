--- @class rt.Vector2
--- @param x Number
--- @param y Number
function rt.Vector2(x, y)
    local out = {x = x, y = y}
    out.__metatable = {
        __name = "Vector2",
        __add = function(self, other)

            return {
                x = self.x + other.x,
                y = self.y + other.y
            }
        end,
        __sub = function(self, other)

            return {
                x = self.x - other.x,
                y = self.y - other.y
            }
        end,
        __mul = function(self, other)

            return {
                x = self.x * other.x,
                y = self.y * other.y
            }
        end,
        __div = function(self, other)

            return {
                x = self.x / other.x,
                y = self.y / other.y
            }
        end,
        __eq = function(self, other)
            return self.x == other.x and self.y == other.y
        end,
        __len = function()
            return 2
        end,
        __tostring = function(self)
            return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ")"
        end
    }
    setmetatable(out, out.__metatable)
    return out
end

--- @brief [internal] check if object is rt.
--- @param object any
function meta.is_vector2(object)
    if not meta.is_table(object) then return false end
    return #object == 2 and meta.is_number(object.x) and meta.is_number(object.y)
end

--- @brief [internal] assert if object is rt.Vector2
--- @param object any
function meta.assert_vector2(object)
    if not meta.is_vector2(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Excpected `Vector2`, got `" .. meta.typeof(object) .. "`")
    end
end
meta.make_debug_only("meta.assert_vector2")

--- @class rt.Vector3
--- @param x Number
--- @param y Number
--- @param z Number
function rt.Vector3(x, y, z)
    local out = {x = x, y = y, z = z}
    out.__metatable = {
        __name = "Vector3",
        __add = function(self, other)

            return {
                x = self.x + other.x,
                y = self.y + other.y,
                z = self.z + other.z
            }
        end,
        __sub = function(self, other)

            return {
                x = self.x - other.x,
                y = self.y - other.y,
                z = self.z - other.z
            }
        end,
        __mul = function(self, other)

            return {
                x = self.x * other.x,
                y = self.y * other.y,
                z = self.z * other.z
            }
        end,
        __div = function(self, other)

            return {
                x = self.x / other.x,
                y = self.y / other.y,
                z = self.z / other.z
            }
        end,
        __eq = function(self, other)
            return self.x == other.x and self.y == other.y and self.z == other.z
        end,
        __len = function()
            return 3
        end,
        __tostring = function(self)
            return "(" .. tostring(self.x) .. ", " .. tostring(self.y) .. ", " .. tostring(self.z) .. ")"
        end
    }
    setmetatable(out, out.__metatable)
    return out
end

--- @brief [internal] check if object is rt.Vector3
--- @param object any
function meta.is_vector3(object)
    if not meta.is_table(object) then return false end
    return #object == 3 and meta.is_number(object.x) and meta.is_number(object.y) and meta.is_number(object.z)
end

--- @brief [internal] assert if object is rt.Vector3
--- @param object any
function meta.assert_vector3(object)
    if not meta.is_vector3(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Excpected `Vector3`, got `" .. meta.typeof(object) .. "`")
    end
end
meta.make_debug_only("meta.assert_vector2")

--- @brief [internal] test vector2, vector3
function rt.test.test_vector()
    do
        local a = rt.Vector2(1, 2)
        local b = rt.Vector2(3, 4)

        assert(meta.is_vector2(a) and meta.is_vector2(b))
        assert(#a == 2 and #b == 2)
        assert(a.x == 1 and a.y == 2 and b.x == 3 and b.y == 4)

        local add = a + b
        assert(add.x == 4 and add.y == 6)
        local sub = b - a
        assert(sub.x == 2 and sub.y == 2)
        local mul = a * b
        assert(mul.x == 3 and mul.y == 8)
        local div = b / a
        assert(div.x == 3 and div.y == 2)

        assert(a == a and b == b)
    end

    do
        local a = rt.Vector3(1, 2, 3)
        local b = rt.Vector3(3, 4, 5)

        assert(#a == 3 and #b == 3)
        assert(meta.is_vector3(a) and meta.is_vector3(b))
        assert(a.x == 1 and a.y == 2 and a.z == 3 and b.x == 3 and b.y == 4 and b.z == 5)

        local add = a + b
        assert(add.x == 4 and add.y == 6 and add.z == 8)
        local sub = b - a
        assert(sub.x == 2 and sub.y == 2 and sub.z == 2)
        local mul = a * b
        assert(mul.x == 3 and mul.y == 8 and mul.z == 15)
        local div = b / a
        assert(div.x == 3 and div.y == 4/2 and div.z == 5/3)

        assert(a == a and b == b)
    end
end
