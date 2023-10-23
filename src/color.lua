--- @class rt.RGBA
--- @param r Number (or String)
--- @param g Number (or nil)
--- @param b Number (or nil)
--- @param a Number (or nil)
rt.RGBA = function(r_or_string, g, b, a)

    if meta.is_string(r_or_string) then
        local code = r_or_string
        return rt.html_code_to_color(code)
    else
        local r = r_or_string
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
end

--- @brief [internal] check if object is rt.RGBA
--- @param object any
function rt.is_rgba(object)
    return sizeof(object) == 4 and
        meta.is_number(object.r) and
        meta.is_number(object.g) and
        meta.is_number(object.b) and
        meta.is_number(object.a)
end

--- @brief [internal] throw if object is not rt.RGBA
function rt.assert_rgba(object)
    if not rt.is_rgba(object) then
        error("In " .. debug.getinfo(2, "n").name .. ": Excpected `RGBA`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @class rt.HSVA
--- @param h Number
--- @param s Number
--- @param v Number
--- @param a Number
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

--- @brief [internal] check if object is rt.HSVA
--- @param object any
--- @return Boolean
function rt.is_hsva(object)
    return sizeof(object) == 4 and
        meta.is_number(object.h) and
        meta.is_number(object.s) and
        meta.is_number(object.v) and
        meta.is_number(object.a)
end

--- @brief [internal] throw if object is not rt.HSVA
--- @param object any
function rt.assert_hsva(object)
    if not rt.is_hsva(object) then
        error("In " .. debug.getinfo(2, "n").name .. ": Excpected `HSVA`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @brief conver rgba to hsva
--- @param rgba rt.RGBA
--- @return rt.HSVA
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
--- @return rt.RGBA
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

--- @brief compare colors
--- @param c1 rt.RGBA
--- @param c2 rt.RGBA
--- @return Boolean
function rt.compare_rgba(c1, c2)
    rt.assert_rgba(c1)
    rt.assert_rgba(c2)
    return c1.r == c2.r and c1.g == c2.g and c1.b == c2.b and c1.a == c2.a
end


--- @brief
function rt.html_code_to_color(code)
    meta.assert_string(code)

    function hex_char_to_int(c)
        c = string.upper(c)
        if c == '0' then return 0
        elseif c == '1' then return 1
        elseif c == '2' then return 2
        elseif c == '3' then return 3
        elseif c == '4' then return 4
        elseif c == '5' then return 5
        elseif c == '6' then return 6
        elseif c == '7' then return 7
        elseif c == '8' then return 8
        elseif c == '9' then return 9
        elseif c == 'A' then return 10
        elseif c == 'B' then return 11
        elseif c == 'C' then return 12
        elseif c == 'D' then return 13
        elseif c == 'E' then return 14
        elseif c == 'F' then return 15
        else return -1 end
    end

    function hex_component_to_int(left, right)
        meta.assert_number(left, right)
        return left * 16 + right
    end

    local error_reason = ""

    local as_hex = {}
    if string.sub(code, 1, 1) ~= '#' then
        code = "#" .. code
    end
    for i = 2, #code do
        local to_push = hex_char_to_int(string.sub(code, i, i))
        if to_push == -1 then
            error_reason = "character `" .. string.sub(code, i, i) .. "` is not a valid hexadecimal digit"
            goto error
        end
        table.insert(as_hex, to_push)
    end

    if sizeof(as_hex) == 6 then
        return rt.RGBA(
                hex_component_to_int(as_hex[1], as_hex[2]) / 255.0,
                hex_component_to_int(as_hex[3], as_hex[4]) / 255.0,
                hex_component_to_int(as_hex[5], as_hex[6]) / 255.0,
                1
        )
    elseif sizeof(as_hex) == 8 then
        return rt.RGBA(
                hex_component_to_int(as_hex[1], as_hex[2]) / 255.0,
                hex_component_to_int(as_hex[3], as_hex[4]) / 255.0,
                hex_component_to_int(as_hex[5], as_hex[6]) / 255.0,
                hex_component_to_int(as_hex[7], as_hex[8]) / 255.0
        )
    else
        error_reason = "more than 6 or 8 digits specified"
        goto error
    end

    ::error::
    error("[rt][ERROR] In rt.html_code_to_rgba: `" .. code .. "` is not a valid hexadecimal color identifier. Reason: " .. error_reason)
end

--- @brief
function rt.color_to_html_code(rgba, use_alpha)
    rt.assert_rgba(rgba)

    if meta.is_nil(use_alpha) then
        use_alpha = false
    end
    meta.assert_boolean(use_alpha)

    rgba.r = clamp(rgba.r, 0, 1)
    rgba.g = clamp(rgba.g, 0, 1)
    rgba.b = clamp(rgba.b, 0, 1)
    rgba.a = clamp(rgba.a, 0, 1)

    function to_hex(x)
        local out = string.upper(string.format("%x", x))
        if #out == 1 then out = "0" .. out end

        return out
    end

    local r = to_hex(math.round(rgba.r * 255))
    local g = to_hex(math.round(rgba.g * 255))
    local b = to_hex(math.round(rgba.b * 255))
    local a = to_hex(math.round(rgba.a * 255))

    local out = "#" .. r .. g .. b
    if use_alpha then
        out = out .. a
    end
    return out
end

--- @brief [internal] test colors
function rt.test.colors()
    -- TODO
    local as_rgba = rt.html_code_to_color("#123456")
    assert(rt.color_to_html_code(as_rgba) == "#123456")
    as_rgba = rt.html_code_to_color("#ABCDEF")
    assert(rt.color_to_html_code(as_rgba) == "#ABCDEF")
end
rt.test.colors()