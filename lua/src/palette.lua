--- @class Palette
rt.Palette = meta.new_type(function()
    error("In rt.Palette(): Attempting to instance singleton")
end)

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