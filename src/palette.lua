--- @class Palette
rt.Palette = {

    LIGHT_GREEN_1 = "76ffc1", -- light mint
    LIGHT_GREEN_2 = "12ff8d", -- mint

    GREEN_1 = "12ff8d", -- green
    GREEN_2 = "03ba2d",
    GREEN_3 = "079e30",
    GREEN_4 = "008040",
    GREEN_5 = "00542e",
    GREEN_6 = "022e0e", -- dark green

    LIGHT_RED_1 = "f9b9b9",
    LIGHT_RED_2 = "ffa0a0", -- light red
    LIGHT_RED_3 = "fe5a5a",

    NEON_RED_1 = "ff71a9",
    NEON_RED_2 = "ff408c",
    NEON_RED_3 = "ff0065", -- neon red
    NEON_RED_4 = "b20047",
    NEON_RED_5 = "900039",
    NEON_RED_6 = "6d002c",

    RED_1 = "ffa0a0", -- red
    RED_2 = "cf0018",
    RED_3 = "9c001a",
    RED_4 = "6c0012",
    RED_5 = "4c000d",

    LIGHT_BLUE_1 = "79eaff",
    LIGHT_BLUE_2 = "00d6fe", -- light blue
    LIGHT_BLUE_3 = "00a7fe",

    LILAC_1 = "b674f7",
    LILAC_2 = "9b53e2",
    LILAC_3 = "7b34cc", -- lilac
    LILAC_4 = "6919c5",
    LILAC_5 = "470296",

    BLUE_1 = "009afe",
    BLUE_2 = "0074fe",
    BLUE_3 = "0053ed", -- blue
    BLUE_4 = "0e30ad",
    BLUE_5 = "06185a",

    PINK_1 = "f8a6dc",
    PINK_2 = "ddb60a", -- pink
    PINK_3 = "ff21b3",
    PINK_4 = "c20c83",

    PURPLE_1 = "c20c83",
    PURPLE_2 = "cc34e1",
    PURPLE_3 = "ae00c6", -- purple
    PURPLE_4 = "53065d",

    YELLOW_1 = "1f1717",
    YELLOW_2 = "ffe200", -- yellow
    YELLOW_3 = "ddb60a",

    ORANGE_1 = "ffa544", -- orange
    ORANGE_2 = "ff8400",
    ORANGE_3 = "ce6300",

    BROWN_1 = "914803",
    BROWN_2 = "693100",
    BROWN_3 = "4c2300",
    BROWN_4 = "2f1600",

    LIGHT_SKIN_1 = "faddcf",
    LIGHT_SKIN_2 = "f8d0b8",
    LIGHT_SKIN_3 = "dba27a",
    LIGHT_SKIN_4 = "d08e64",

    DARK_SKIN_1 = "8f593a",
    DARK_SKIN_2 = "693b1f",
    DARK_SKIN_3 = "392825",
    DARK_SKIN_4 = "1f1717",
    
    WHITE = "#fafaff",
    GREY_1 = "#dcdce1",
    GREY_2 = "#c0c0c5",
    GREY_3 = "#a0a0a7",
    GREY_4 = "#737378",
    GREY_5 = "#404045",
    GREY_6 = "#202025",
    BLACK = "#0b0b10",

    PURE_WHITE = "#ffffff",
    PURE_RED = "#ff000000",
    PURE_GREEN = "#00ff00",
    PURE_BLUE = "#0000ff",
    PURE_CYAN = "#00ffff",
    PURE_YELLOW = "#ffff00",
    PURE_MAGENTA = "#ff00ff",
    PURE_BLACK = "#000000",
}

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

--- @brief
function rt.Palette.draw()
end

--- @brief [internal] test palette
function rt.test.palette()
end
rt.test.palette()