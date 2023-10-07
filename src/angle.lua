--- @class rt.Angle
rt.Angle = meta.new_type("Angle", function(rads)
    if meta.is_nil(rads) then rads = 0 end
    meta.assert_number(rads)
    local out = meta.new(rt.Angle, {
        _rads = rads
    })
    local metatable = getmetatable(out)
    metatable.__add = function(self, other)
        meta.assert_isa(self, rt.Angle)
        meta.assert_isa(other, rt.Angle)
        return rt.Angle(math.fmod(self._rads + other._rads, 2 * math.pi))
    end
    metatable.__sub = function(self, other)
        meta.assert_isa(self, rt.Angle)
        meta.assert_isa(other, rt.Angle)
        return rt.Angle(math.fmod(self._rads - other._rads, 2 * math.pi))
    end
    return out
end)

--- @brief
function rt.radians_to_degrees(rads)
    return rads * (180 / math.pi)
end

--- @brief
function rt.degrees_to_radians(rads)
    return rads * (math.pi / 180)
end

--- @brief
function rt.degrees(dg)
    return rt.Angle(rt.degrees_to_radians(dg))
end

--- @brief
function rt.radians(rad)
    return rt.Angle(rad)
end

--- @brief
function rt.Angle:as_degrees()
    return rt.radians_to_degrees(self._rads)
end

--- @brief
function rt.Angle:as_radians()
    return self._rads
end

--- @brief [internal]
function rt.test.angle()
end
rt.test.angle()