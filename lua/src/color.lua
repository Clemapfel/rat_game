--- @class rt.RGBA
rt.RGBA = function(r, g, b, a)
    if meta.is_nil(r) then r = 1 end
    if meta.is_nil(g) then g = 1 end
    if meta.is_nil(b) then b = 1 end
    if meta.is_nil(a) then a = 1 end

    local out = {}
    out.r = r
    out.g = g
    out.b = b
    out.a = a
    return out
end

--- @brief [internal]
function rt.is_rgba(object)
    return sizeof(object) == 4 and
        meta.is_number(object.r) and
        meta.is_number(object.g) and
        meta.is_number(object.b) and
        meta.is_number(object.a)
end

--- @brief [internal] check if object is RGBA
function rt.assert_rgba(object)
    if not rt.is_rgba(object) then
        error("In " .. debug.getinfo(2, "n").name .. ": Excpected `RGBA`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @class rt.HSVA
function rt.HSVA(h, s, v, a)
    if meta.is_nil(h) then h = 1 end
    if meta.is_nil(s) then s = 1 end
    if meta.is_nil(v) then v = 1 end
    if meta.is_nil(a) then a = 1 end

    local out = {}
    out.h = h
    out.s = s
    out.v = v
    out.a = a
    return out
end

--- @brief [internal]
function rt.is_hsva(object)
    return sizeof(object) == 4 and
        meta.is_number(object.h) and
        meta.is_number(object.s) and
        meta.is_number(object.v) and
        meta.is_number(object.a)
end

--- @brief [internal] check if object is RGBA
function rt.assert_hsva(object)
    if not rt.is_hsva(object) then
        error("In " .. debug.getinfo(2, "n").name .. ": Excpected `HSVA`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @brief conver rgba to hsva
--- @param rgba rt.RGBA
function rt.rgba_to_hsva(rgba)
    rt.assert_rgba(rgba)

    -- cf. https://github.com/Clemapfel/mousetrap/blob/main/src/color.cpp#L112
    local r = rgba.r
    local g = rgba.g
    local b = rgba.b
    local a = rgba.a

    local h, s, v

    local min = 0

    if r < g then min = r else min = g end
    if min < b then min = min else min = b end

    local max = 0

    if r > g then max = r else max = g end
    if max > b then max = max else max = b end

    local delta = max - min

    if delta == 0 then
        h = 0
    elseif max == r then
        h = 60 * (fmod(((g - b) / delta), 6))
    elseif max == g then
        h = 60 * (((b - r) / delta) + 2)
    elseif max == b then
        h = 60 * (((r - g) / delta) + 4)
    end

    if (max == 0) then
        s = 1
    else
        s = delta / max
    end

    v = max

    if (h < 0) then
        h = h + 360
    end

    return HSVA(h / 360, s, v, a)
end

--- @brief convert hsva to rgba
--- @param hsva rt.HSVA
function rt.hsva_to_rgba(hsva)
    rt.assert_hsva(hsva)

    --- cf https://github.com/Clemapfel/mousetrap/blob/main/src/color.cpp#L151
    local h = hsva.h * 360
    local s = hsva.s
    local v = hsva.v
    local a = hsva.a

    local c = v * s
    local h_2 = h / 60.0
    local x = c * (1 - math.abs(math.fmod(h_2, 2) - 1))

    local r, g, b

    if (0 <= h_2 and h_2 < 1) then
        r, g, b = c, x, 0
    elseif (1 <= h_2 and h_2 < 2) then
        r, g, b  = x, c, 0
    elseif (2 <= h_2 and h_2 < 3) then
        r, g, b  = 0, c, x
    elseif (3 <= h_2 and h_2 < 4) then
        r, g, b  = 0, x, c
    elseif (4 <= h_2 and h_2 < 5) then
        r, g, b  = x, 0, c
    elseif (5 <= h_2 and h_2 <= 6) then
        r, g, b  = c, 0, x
    end
    
    local  m = v - c

    r = r + m
    g = g + m
    b = b + m

    return rt.RGBA(r, g, b, a)
end

--- @brief
function rt.compare_rgba(c1, c2)
    rt.assert_rgba(c1)
    rt.assert_rgba(c2)
    return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b and c1.a == c2.a
end

--- @brief [internal] test colors
function rt.test.colors()
    -- TODO
end
rt.test.colors()