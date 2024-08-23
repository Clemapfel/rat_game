rt.settings.font = {
    default_size = 23,
    default_size_tiny = 14,
    default_size_small = 20,
    default_size_large = 40,
    default = {},       -- rt.Font
    default_large = {},
    default_small = {},
    default_tiny = {},
    default_mono = {},  -- rt.Font
    default_mono_large = {},
    default_mono_small = {},
    default_mono_tiny = {},
    regular_fallbacks = {},     -- Table<love.Font>
    italic_fallbacks = {},      -- Table<love.Font>
    bold_italic_fallbacks = {}, -- Table<love.Font>
    bold_fallbacks = {},        -- Table<love.Font>
}

N_FONTS = 0

--- @class rt.Font
--- @param regular_path String
--- @param bold_path String (or nil)
--- @param italic_path String (or nil)
--- @param bold_italic_path String (or nil)
rt.Font = meta.new_type("Font", function(size, regular_path, bold_path, italic_path, bold_italic_path)
    local out = meta.new(rt.Font, {
        _regular_path = regular_path,
        _italic_path = regular_path,
        _bold_path = regular_path,
        _bold_italic_path = regular_path,
        _size = size,
        _regular_rasterizer = {},
        _italic_rasterizer = {},
        _bold_rasterizer = {},
        _bold_italic_rasterizer = {}
    })

    if not meta.is_nil(bold_path) then
        out._bold_path = bold_path
    end

    if not meta.is_nil(italic_path) then
        out._italic_path = italic_path
    end

    if not meta.is_nil(bold_italic_path) then
        out._bold_italic_path = bold_italic_path
    end

    out:_update()
    return out
end)

--- @class love.Font
---
--- @class rt.FontStyle
rt.FontStyle = meta.new_enum({
    REGULAR = "FONT_STYLE_REGULAR",
    ITALIC = "FONT_STYLE_ITALIC",
    BOLD = "FONT_STYLE_BOLD",
    BOLD_ITALIC = "FONT_STYLE_BOLD_ITALIC"
})

rt.Font[rt.FontStyle.REGULAR] = love.graphics.getFont()
rt.Font[rt.FontStyle.BOLD] = love.graphics.getFont()
rt.Font[rt.FontStyle.ITALIC] = love.graphics.getFont()
rt.Font[rt.FontStyle.BOLD_ITALIC] = love.graphics.getFont()

--- @brief [internal] update held fonts
function rt.Font:_update()
    self[rt.FontStyle.REGULAR] = love.graphics.newFont(self._regular_path, self._size)
    self[rt.FontStyle.BOLD] = love.graphics.newFont(self._bold_path, self._size)
    self[rt.FontStyle.ITALIC] = love.graphics.newFont(self._italic_path, self._size)
    self[rt.FontStyle.BOLD_ITALIC] = love.graphics.newFont(self._bold_italic_path, self._size)

    self[rt.FontStyle.REGULAR]:setFallbacks(splat(rt.settings.font.regular_fallbacks))
    self[rt.FontStyle.BOLD]:setFallbacks(splat(rt.settings.font.bold_fallbacks))
    self[rt.FontStyle.ITALIC]:setFallbacks(splat(rt.settings.font.italic_fallbacks))
    self[rt.FontStyle.BOLD_ITALIC]:setFallbacks(splat(rt.settings.font.bold_italic_fallbacks))

    self._regular_rasterizer = love.font.newRasterizer(self._regular_path, self._size)
    self._bold_rasterizer = love.font.newRasterizer(self._bold_path, self._size)
    self._italic_rasterizer = love.font.newRasterizer(self._italic_path, self._size)
    self._bold_italic_rasterizer = love.font.newRasterizer(self._bold_italic_path, self._size)
end

--- @brief set font size, in px
--- @param px Number
function rt.Font:set_size(px)
    self._size = px
    self:_update()
end

--- @brief get font size, in px
--- @return Number
function rt.Font:get_size()
    return self._size
end

--- @brief get regular version of font
--- @return love.Font
function rt.Font:get_regular()
    return self[rt.FontStyle.REGULAR]
end

--- @brief get bold version of font
--- @return love.Font
function rt.Font:get_bold()
    return self[rt.FontStyle.BOLD]
end

--- @brief get italic version of font
--- @return love.Font
function rt.Font:get_italic()
    return self[rt.FontStyle.ITALIC]
end

--- @brief get bold-italic version of font
--- @return love.Font
function rt.Font:get_bold_italic()
    return self[rt.FontStyle.BOLD_ITALIC]
end

--- @brief [internal] load default fonts and fallbacks
function rt.load_default_fonts()
    -- fallback fonts to support more symbols
    local noto_math = love.graphics.newFont("assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf")
    local gnu_unifont = love.graphics.newFont("assets/fonts/fallback.otf")

    rt.settings.font.regular_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Regular.ttf"),
        noto_math,
        gnu_unifont
    }

    rt.settings.font.italic_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Italic.ttf"),
        noto_math,
        gnu_unifont
    }

    rt.settings.font.bold_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Bold.ttf"),
        noto_math,
        gnu_unifont
    }

    rt.settings.font.bold_italic_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-BoldItalic.ttf"),
        noto_math,
        gnu_unifont
    }

    rt.settings.font.default = rt.Font(rt.settings.font.default_size,
            "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )
    rt.settings.font.default_mono = rt.Font(rt.settings.font.default_size,
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Regular.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Bold.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Italic.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-BoldItalic.ttf"
    )

    rt.settings.font.default_small = rt.Font(rt.settings.font.default_size_small,
            "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )
    rt.settings.font.default_mono_small = rt.Font(rt.settings.font.default_size_small,
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Regular.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Bold.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Italic.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-BoldItalic.ttf"
    )

    rt.settings.font.default_tiny = rt.Font(rt.settings.font.default_size_tiny,
        "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )
    rt.settings.font.default_mono_tiny = rt.Font(rt.settings.font.default_size_tiny,
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-Regular.ttf",
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-Bold.ttf",
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-Italic.ttf",
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-BoldItalic.ttf"
    )

    rt.settings.font.default_large = rt.Font(rt.settings.font.default_size_large,
            "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
            "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )
    rt.settings.font.default_mono_large = rt.Font(rt.settings.font.default_size_large,
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Regular.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Bold.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-Italic.ttf",
            "assets/fonts/DejaVuSansMono/DejaVuSansMono-BoldItalic.ttf"
    )
end
rt.load_default_fonts()