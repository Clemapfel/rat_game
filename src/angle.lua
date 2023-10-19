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

--- @brief convert radians to degrees
--- @param rads Number
--- @return Number
function rt.radians_to_degrees(rads)
    meta.assert_number(rads)
    return rads * (180 / math.pi)
end

--- @brief convert degrees to radians
--- @param dgs Number
--- @return Number
function rt.degrees_to_radians(dgs)
    meta.assert_number(dgs)
    return dgs * (math.pi / 180)
end

--- @brief create `Angle` from number of degrees
--- @param dgs Number
--- @return rt.Angle
function rt.degrees(dg)
    return rt.Angle(rt.degrees_to_radians(dg))
end

--- @brief create `Angle` from number of radians
--- @param rads Number
--- @return rt.Angle
function rt.radians(rads)
    return rt.Angle(rads)
end

--- @brief convert `Angle` to degrees
--- @return Number
function rt.Angle:as_degrees()
    meta.assert_isa(self, rt.Angle)
    return rt.radians_to_degrees(self._rads)
end

--- @brief convert `Angle` to radians
--- @return Number
function rt.Angle:as_radians()
    meta.assert_isa(self, rt.Angle)
    return self._rads
end

--- @brief [internal]
function rt.test.angle()
    local dgs = 180
    local rads = rt.degrees_to_radians(dgs)
    assert(dgs == rt.radians_to_degrees(rads))

    local angle_dgs = rt.degrees(dgs)
    local angle_rads = rt.radians(rads)

    assert(angle_dgs:as_degrees() == dgs)
    assert(angle_rads:as_radians() == rads)
end
rt.test.angle()