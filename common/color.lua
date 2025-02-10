--- @class rt.RGBA
rt.RGBA = function(r_or_string, g, b, a)
    if type(r_or_string) == "string" then --meta.is_string(r_or_string) then
        local code = r_or_string
        return rt.html_code_to_color(code)
    else
        local r = r_or_string
        if r == nil then r = 1 end
        if g == nil then g = 1 end
        if b == nil then b = 1 end
        if a == nil then a = 1 end

        local out = {}
        out.r = r
        out.g = g
        out.b = b
        out.a = a
        return out
    end
end

local _is_number = meta.is_number

--- @brief [internal] check if object is rt.RGBA
--- @param object any
function meta.is_rgba(object)
    return sizeof(object) == 4 and
        _is_number(object.r) and
        _is_number(object.g) and
        _is_number(object.b) and
        _is_number(object.a)
end

--- @brief [internal] throw if object is not rt.RGBA
function meta.assert_rgba(object)
    if not meta.is_rgba(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Expected `RGBA`, got `" .. meta.typeof(object) .. "`")
    end
end


--- @class rt.HSVA
function rt.HSVA(h, s, v, a)
    if h == nil then h = 1 end
    if s == nil then s = 1 end
    if v == nil then v = 1 end
    if a == nil then a = 1 end

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
function meta.is_hsva(object)
    return sizeof(object) == 4 and
        _is_number(object.h) and
        _is_number(object.s) and
        _is_number(object.v) and
        _is_number(object.a)
end

--- @brief [internal] throw if object is not rt.HSVA
--- @param object any
function meta.assert_hsva(object)
    if not meta.is_hsva(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Excpected `HSVA`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @class rt.LCHA
function rt.LCHA(l, c, h, a)
    if l == nil then l = 1 end
    if c == nil then c = 0 end
    if h == nil then h = 0 end
    if a == nil then a = 1 end

    return {
        l = l,
        c = c,
        h = h,
        a = a
    }
end

--- @brief
function meta.is_lcha(object)
    return sizeof(object) == 4 and
        _is_number(object.h) and
        _is_number(object.s) and
        _is_number(object.v) and
        _is_number(object.a)
end

--- @brief
function meta.assert_lcha(object)
    if not meta.is_lcha(object) then
        rt.error("In " .. debug.getinfo(2, "n").name .. ": Excpected `LCHA`, got `" .. meta.typeof(object) .. "`")
    end
end

--- @brief conver rgba to hsva
--- @param rgba rt.RGBA
--- @return rt.HSVA
function rt.rgba_to_hsva(rgba)
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
        h = 60 * (math.fmod(((g - b) / delta), 6))
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

    return rt.HSVA(h / 360, s, v, a)
end

--- @brief convert hsva to rgba
--- @param hsva rt.HSVA
--- @return rt.RGBA
function rt.hsva_to_rgba(hsva)
    -- cf. https://github.com/Clemapfel/mousetrap/blob/main/src/color.cpp#L151
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
    else
        r, g, b  = c, 0, x
    end

    local m = v - c

    r = r + m
    g = g + m
    b = b + m

    return rt.RGBA(r, g, b, a)
end

--- @brief convert lcha to rgba
function rt.lcha_to_rgba(lcha, c, h, alpha)
    local L, C, H
    if type(lcha) == "number" then
        L = lcha
        C = c
        H = h
        alpha = alpha
    else
        L = lcha.l
        C = lcha.c
        H = lcha.h
        alpha = lcha.a
    end

    L = L * 100
    C = C * 100
    H = H * 360

    local a = math.cos(math.rad(H)) * C
    local b = math.sin(math.rad(H)) * C

    local Y = (L + 16.0) / 116.0
    local X = a / 500.0 + Y
    local Z = Y - b / 200.0

    if X * X * X > 0.008856 then
        X = 0.95047 * X * X * X
    else
        X = 0.95047 * (X - 16.0 / 116.0) / 7.787
    end

    if Y * Y * Y > 0.008856 then
        Y = 1.00000 * Y * Y * Y
    else
        Y = 1.00000 * (Y - 16.0 / 116.0) / 7.787
    end

    if Z * Z * Z > 0.008856 then
        Z = 1.08883 * Z * Z * Z
    else
        Z = 1.08883 * (Z - 16.0 / 116.0) / 7.787
    end

    local R = X *  3.2406 + Y * -1.5372 + Z * -0.4986
    local G = X * -0.9689 + Y *  1.8758 + Z *  0.0415
    local B = X *  0.0557 + Y * -0.2040 + Z *  1.0570

    if R > 0.0031308 then
        R = 1.055 * R^(1.0 / 2.4) - 0.055
    else
        R = 12.92 * R
    end

    if G > 0.0031308 then
        G = 1.055 * G^(1.0 / 2.4) - 0.055
    else
        G = 12.92 * G
    end

    if B > 0.0031308 then
        B = 1.055 * B^(1.0 / 2.4) - 0.055
    else
        B = 12.92 * B
    end

    return rt.RGBA(
        clamp(R, 0.0, 1.0),
        clamp(G, 0.0, 1.0),
        clamp(B, 0.0, 1.0),
        alpha
    )
end


--- @brief convert html hexadecimal to rgba
--- @param code String "#RRGGBB(AA)"
--- @return rt.RGBA
function rt.html_code_to_color(code)
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
    rt.error("In rt.html_code_to_rgba: `" .. code .. "` is not a valid hexadecimal color identifier. Reason: " .. error_reason)
end

--- @brief convert rgba to html color code
--- @param rgba rt.RGBA
--- @param use_alpha Boolean (or nil)
--- @return String "#RRGGBB" or "#RRGGBBAA" if `use_alpha`
function rt.color_to_html_code(rgba, use_alpha)
    if use_alpha == nil then
        use_alpha = false
    end

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

--- @brief
function rt.color_darken(color, offset)
    offset = clamp(offset, 0, 1)
    if meta.is_hsva(color) then
        return rt.HSVA(color.h, color.s, color.v - offset, color.a)
    else
        return rt.RGBA(color.r - offset, color.g - offset, color.b - offset, color.a)
    end
end

--- @brief
function rt.color_lighten(color, offset)
    return rt.color_darken(color, -1 * offset)
end

--- @brief
function rt.color_unpack(color)
    if meta.is_rgba(color) then
        return color.r, color.g, color.b, color.a
    elseif meta.is_hsva(color) then
        return color.h, color.s, color.v, color.a
    elseif meta.is_lcha(color) then
        return color.l, color.c, color.h, color.a
    end
end

--- @brief
function rt.color_copy(color)
    if meta.is_rgba(color) then
        return rt.RGBA(color.r, color.g, color.b, color.a)
    elseif meta.is_hsva(color) then
        return rt.HSVA(color.h, color.s, color.v, color.a)
    elseif meta.is_lcha(color) then
        return rt.LCHA(color.l, color.c, color.h, color.a)
    end
end
--- @brief
function rt.color_mix(a, b, ratio)
    if meta.is_hsva(a) and meta.is_hsva(b) then
        return rt.HSVA(
            mix(a.h, b.h, ratio),
            mix(a.s, b.s, ratio),
            mix(a.v, b.v, ratio),
            mix(a.a, b.a, ratio)
        )
    else
        meta.assert_rgba(a)
        meta.assert_rgba(b)
        return rt.RGBA(
            mix(a.r, b.r, ratio),
            mix(a.g, b.g, ratio),
            mix(a.b, b.b, ratio),
            mix(a.a, b.a, ratio)
        )
    end
end

