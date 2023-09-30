--- @class Palette
rt.Palette = meta.new_type("Palette", function()
    error("In rt.Palette(): Attempting to instance singleton")
end)

--- @brief
function rt.html_code_to_color(code)
    meta.assert_string(code)

    function hex_char_to_int(c)
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

    local as_hex = {}
    local start_i = ternary(string.sub(code, 1, 1) == '#', 2, 1)
    for i = start_i, #code do
        local to_push = hex_char_to_int(string.sub(code, i, i))
        if to_push == -1 then goto error end
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
        goto error
    end

    ::error::
      error("[rt] In rt.html_code_to_rgba: `" .. code .. "` is not a valid hexadecimal color identifier")
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

--- @brief
function rt.Palette.lighten(color, offset)
    offset = offset or 0.3
    if rt.is_hsva(color) then
        return rt.HSVA(
            color.h,
            color.s,
            clamp(0, 1, color.v + offset),
            color.a
        )
    else
        rt.assert_rgba()
        return rt.RGBA(
            clamp(color.r + offset),
            clamp(color.g + offset),
            clamp(color.b + offset),
            clamp(color.r)
        )
    end
end

--- @brief
function rt.Palette.darken(color, offset)
    offset = offset or 0.3
    if rt.is_hsva(color) then
        return rt.HSVA(
            color.h,
            color.s,
            clamp(0, 1, color.v - offset),
            color.a
        )
    else
        rt.assert_rgba()
        return rt.RGBA(
            clamp(color.r - offset),
            clamp(color.g - offset),
            clamp(color.b - offset),
            clamp(color.r)
        )
    end
end

--- @brief
function rt.Palette.hue_shift(color, offset)
    meta.assert_number(offser)
    if rt.is_hsva(color) then
        return rt.HSVA(
            math.fmod(color.h + offset, 1),
            color.s,
            color.v,
            color.a
        )
    else
        as_hsva = rt.rgba_to_hsva(color)
        as_hsva.h = math.fmod(as_hsva.h + offset, 1)
        return rt.hsva_to_rgba(as_hsva)
    end
end

--- @brief [internal] test palette
function rt.test.palette()
    -- TODO
end
rt.test.palette()