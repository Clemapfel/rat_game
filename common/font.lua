rt.settings.font = {
    default_size = 23,
    default_size_tiny = 14,
    default_size_small = 20,
    default_size_large = 40,
    default_size_huge = 60,
    min_font_size = 12,
    default = {},       -- rt.Font
    default_huge = {},
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
        _regular = nil, -- love.Font
        _bold = nil,
        _italic = nil,
        _bold_italic = nil
    })

    if bold_path ~= nil then
        out._bold_path = bold_path
    end

    if italic_path ~= nil then
        out._italic_path = italic_path
    end

    if bold_italic_path ~= nil then
        out._bold_italic_path = bold_italic_path
    end

    out:_update()
    return out
end)

--- @class love.Font
---
--- @class rt.FontStyle
rt.FontStyle = meta.new_enum("FontStyle", {
    REGULAR = 0,
    ITALIC = 1,
    BOLD = 2,
    BOLD_ITALIC = 3
})

rt.Font._regular = love.graphics.getFont()
rt.Font._bold = love.graphics.getFont()
rt.Font._italic = love.graphics.getFont()
rt.Font._bold_italic = love.graphics.getFont()

--- @brief [internal] update held fonts
function rt.Font:_update()
    self._regular = love.graphics.newFont(self._regular_path, self._size)
    self._bold = love.graphics.newFont(self._bold_path, self._size)
    self._italic = love.graphics.newFont(self._italic_path, self._size)
    self._bold_italic = love.graphics.newFont(self._bold_italic_path, self._size)

    self._regular:setFallbacks(splat(rt.settings.font.regular_fallbacks))
    self._bold:setFallbacks(splat(rt.settings.font.bold_fallbacks))
    self._italic:setFallbacks(splat(rt.settings.font.italic_fallbacks))
    self._bold_italic:setFallbacks(splat(rt.settings.font.bold_italic_fallbacks))

    --[[
    for font in range(self._regular, self._bold, self._italic, self._bold_italic) do
        font:setLineHeight(0)
    end
    ]]--
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

do
    local _font_style_to_field = {
        [rt.FontStyle.REGULAR] = "_regular",
        [rt.FontStyle.BOLD] = "_bold",
        [rt.FontStyle.ITALIC] = "_italic",
        [rt.FontStyle.BOLD_ITALIC] = "_bold_italic"
    }
    --- @brief
    function rt.Font:get_native(style)
        return self[_font_style_to_field[style]]
    end
end

--- @brief
function rt.Font:measure_glyph(label)
    return self._bold_italic:getWidth(label), self._bold_italic:getHeight(label)
end

--- @brief [internal] load default fonts and fallbacks
function rt.load_default_fonts()
    -- fallback fonts to support more symbols
    local noto_math = love.graphics.newFont("assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf")
    local gnu_unifont = love.graphics.newFont("assets/fonts/fallback.otf")

    rt.settings.font.regular_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Regular.ttf"),
        love.graphics.newFont("assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf"),
        noto_math,
        gnu_unifont
    }

    rt.settings.font.italic_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Italic.ttf"),
        love.graphics.newFont("assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf"), -- no italic in japanese
        noto_math,
        gnu_unifont
    }

    rt.settings.font.bold_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-Bold.ttf"),
        love.graphics.newFont("assets/fonts/NotoSansJP/NotoSansJP-Bold.ttf"),
        noto_math,
        gnu_unifont
    }

    rt.settings.font.bold_italic_fallbacks = {
        love.graphics.newFont("assets/fonts/NotoSans/NotoSans-BoldItalic.ttf"),
        love.graphics.newFont("assets/fonts/NotoSansJP/NotoSansJP-Bold.ttf"), -- no italic in japanese
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

    rt.settings.font.default_huge = rt.Font(rt.settings.font.default_size_huge,
        "assets/fonts/DejaVuSans/DejaVuSans-Regular.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Bold.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-Italic.ttf",
        "assets/fonts/DejaVuSans/DejaVuSans-BoldItalic.ttf"
    )

    rt.settings.font.default_mono_huge = rt.Font(rt.settings.font.default_size_huge,
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-Regular.ttf",
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-Bold.ttf",
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-Italic.ttf",
        "assets/fonts/DejaVuSansMono/DejaVuSansMono-BoldItalic.ttf"
    )
end
rt.load_default_fonts()