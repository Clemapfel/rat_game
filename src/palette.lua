--- @class Palette
rt.Palette = {
    LIGHT_GREEN_1 = rt.RGBA("#76ffc1"), -- light mint
    LIGHT_GREEN_2 = rt.RGBA("#12ff8d"), -- mint
    GREEN_1 = rt.RGBA("#04e838"), -- green
    GREEN_2 = rt.RGBA("#03ba2d"),
    GREEN_3 = rt.RGBA("#079e30"),
    GREEN_4 = rt.RGBA("#008040"),
    GREEN_5 = rt.RGBA("#00542e"),
    GREEN_6 = rt.RGBA("#022e0e"), -- dark green

    NEON_RED_1 = rt.RGBA("#ff71a9"),
    NEON_RED_2 = rt.RGBA("#ff408c"),
    NEON_RED_3 = rt.RGBA("#ff0065"), -- neon red
    NEON_RED_4 = rt.RGBA("#b20047"),
    NEON_RED_5 = rt.RGBA("#900039"),
    NEON_RED_6 = rt.RGBA("#6d002c"),

    LIGHT_RED_1 = rt.RGBA("#f9b9b9"),
    LIGHT_RED_2 = rt.RGBA("#ffa0a0"), -- light red
    LIGHT_RED_3 = rt.RGBA("#fe5a5a"),

    RED_1 = rt.RGBA("#ff001e"), -- red
    RED_2 = rt.RGBA("#cf0018"),
    RED_3 = rt.RGBA("#9c001a"),
    RED_4 = rt.RGBA("#6c0012"),
    RED_5 = rt.RGBA("#4c000d"),

    LIGHT_BLUE_1 = rt.RGBA("#79eaff"),
    LIGHT_BLUE_2 = rt.RGBA("#00d6fe"), -- light blue

    BLUE_1 = rt.RGBA("#53bbff"),
    BLUE_2 = rt.RGBA("#009afe"),
    BLUE_3 = rt.RGBA("#0074fe"),
    BLUE_4 = rt.RGBA("#0053ed"), -- blue
    BLUE_5 = rt.RGBA("#0e30ad"),
    BLUE_6 = rt.RGBA("#06185a"),

    PINK_1 = rt.RGBA("#f8a6dc"),
    PINK_2 = rt.RGBA("#f272bd"), -- pink
    PINK_3 = rt.RGBA("#ff21b3"),
    PINK_4 = rt.RGBA("#c20c83"),
    PINK_5 = rt.RGBA("#7a1056"),

    PURPLE_1 = rt.RGBA("#e565ff"),
    PURPLE_2 = rt.RGBA("#cc34e1"),
    PURPLE_3 = rt.RGBA("#ae00c6"), -- purple
    PURPLE_4 = rt.RGBA("#7b048a"),
    PURPLE_5 = rt.RGBA("#53065d"),

    LILAC_1 = rt.RGBA("#b674f7"),
    LILAC_2 = rt.RGBA("#9b53e2"),
    LILAC_3 = rt.RGBA("#7b34cc"), -- lilac
    LILAC_4 = rt.RGBA("#6919c5"),
    LILAC_5 = rt.RGBA("#470296"),

    YELLOW_1 = rt.RGBA("#ffeda3"),
    YELLOW_2 = rt.RGBA("#ffe200"), -- yellow
    YELLOW_3 = rt.RGBA("#ddb60a"),

    ORANGE_1 = rt.RGBA("#ffa544"), -- orange
    ORANGE_2 = rt.RGBA("#ff8400"),
    ORANGE_3 = rt.RGBA("#ce6300"),

    BROWN_1 = rt.RGBA("#914803"),
    BROWN_2 = rt.RGBA("#693100"),
    BROWN_3 = rt.RGBA("#4c2300"),
    BROWN_4 = rt.RGBA("#2f1600"),

    LIGHT_SKIN_1 = rt.RGBA("#faddcf"),
    LIGHT_SKIN_2 = rt.RGBA("#f8d0b8"),
    LIGHT_SKIN_3 = rt.RGBA("#dba27a"),
    LIGHT_SKIN_4 = rt.RGBA("#d08e64"),

    DARK_SKIN_1 = rt.RGBA("#8f593a"),
    DARK_SKIN_2 = rt.RGBA("#693b1f"),
    DARK_SKIN_3 = rt.RGBA("#392825"),
    DARK_SKIN_4 = rt.RGBA("#1f1717"),

    WHITE = rt.RGBA("#fafaff"),
    GREY_1 = rt.RGBA("#dcdce1"),
    GREY_2 = rt.RGBA("#c0c0c5"),
    GREY_3 = rt.RGBA("#a0a0a7"),
    GREY_4 = rt.RGBA("#737378"),
    GREY_5 = rt.RGBA("#404045"),
    GREY_6 = rt.RGBA("#202025"),
    BLACK = rt.RGBA("#0b0b10"),

    PURE_WHITE = rt.RGBA("#ffffff"),
    PURE_RED = rt.RGBA("#ff0000"),
    PURE_GREEN = rt.RGBA("#00ff00"),
    PURE_BLUE = rt.RGBA("#0000ff"),
    PURE_CYAN = rt.RGBA("#00ffff"),
    PURE_YELLOW = rt.RGBA("#ffff00"),
    PURE_MAGENTA = rt.RGBA("#ff00ff"),
    PURE_BLACK = rt.RGBA("#000000")
}

rt.Palette.BACKGROUND = rt.Palette.GREY_5
rt.Palette.BACKGROUND_OUTLINE = rt.Palette.BLACK

rt.Palette.FOREGROUND = rt.Palette.WHITE
rt.Palette.FOREGROUND_OUTLINE = rt.Palette.BACKGROUND_OUTLINE

rt.Palette.HIGHLIGHT = rt.Palette.BLUE_2
rt.Palette.HIGHLIGHT_OUTLINE = rt.Palette.BLUE_4

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
function rt.Palette:export()
    meta.assert_table(self)

    local ordered = {
        "LIGHT_GREEN_1",
        "LIGHT_GREEN_2",
        "GREEN_1",
        "GREEN_2",
        "GREEN_3",
        "GREEN_4",
        "GREEN_5",
        "GREEN_6",

        "NEON_RED_1",
        "NEON_RED_2",
        "NEON_RED_3",
        "NEON_RED_4",
        "NEON_RED_5",
        "NEON_RED_6",

        "LIGHT_RED_1",
        "LIGHT_RED_2",
        "LIGHT_RED_3",
        "RED_1",
        "RED_2",
        "RED_3",
        "RED_4",
        "RED_5",

        "LIGHT_BLUE_1",
        "LIGHT_BLUE_2",
        "BLUE_1",
        "BLUE_2",
        "BLUE_3",
        "BLUE_4",
        "BLUE_5",
        "BLUE_6",

        "PINK_1",
        "PINK_2",
        "PINK_3",
        "PINK_4",
        "PINK_5",

        "PURPLE_1",
        "PURPLE_2",
        "PURPLE_3",
        "PURPLE_4",
        "LILAC_1",
        "LILAC_2",
        "LILAC_3",
        "LILAC_4",
        "LILAC_5",

        "YELLOW_1",
        "YELLOW_2",
        "YELLOW_3",
        "ORANGE_1",
        "ORANGE_2",
        "ORANGE_3",
        "BROWN_1",
        "BROWN_2",
        "BROWN_3",

        "BROWN_4",
        "LIGHT_SKIN_1",
        "LIGHT_SKIN_2",
        "LIGHT_SKIN_3",
        "LIGHT_SKIN_4",
        "DARK_SKIN_1",
        "DARK_SKIN_2",
        "DARK_SKIN_3",
        "DARK_SKIN_4",

        "WHITE",
        "GREY_1",
        "GREY_2",
        "GREY_3",
        "GREY_4",
        "GREY_5",
        "GREY_6",
        "BLACK",

        "PURE_WHITE",
        "PURE_RED",
        "PURE_GREEN",
        "PURE_BLUE",
        "PURE_CYAN",
        "PURE_YELLOW",
        "PURE_MAGENTA",
        "PURE_BLACK"
    }

    local image = rt.Image(sizeof(ordered)+1, 1)
    for i, key in ipairs(ordered) do
        local color = rt.Palette[key]
        if not meta.is_nil(color) then
            image:set_pixel(i, 1, color)
        end
    end

    image:save_to_file("palette.png")
    local from = love.filesystem.getAppdataDirectory() .. "love/rat_game/palette.png"
    local to = love.filesystem.getSourceBaseDirectory() .. "/rat_game/art/palette.png"
    os.execute("mv " .. from .. " " .. to)
    love.filesystem.remove("palette.png")
    println("[rt][LOG] Exported palette to " .. to)
end

--- @brief [internal] test palette
function rt.test.palette()
end
rt.test.palette()