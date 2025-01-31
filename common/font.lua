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
    meta.assert_number(size)
    meta.assert_string(regular_path)
    local out = meta.new(rt.Font, {
        _regular_path = regular_path,
        _italic_path = regular_path,
        _bold_path = regular_path,
        _bold_italic_path = regular_path,
        _size = size,
        _is_initialized = false,

        _regular = nil, -- love.Font
        _bold = nil,
        _italic = nil,
        _bold_italic = nil,

        _regular_sdf = nil, -- love.Font
        _bold_sdf = nil,
        _italic_sdf = nil,
        _bold_italic_sdf = nil
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

local _new_font = function(path, size, sdf)
    return love.graphics.newFont(path, size, {
        sdf = sdf
    })
end


--- @brief update held fonts, delayed until font is used for the first time
function rt.Font:initialize()
    if self._is_initialized == true then return end
    self._is_initialized = true

    local config = {}
    self._regular = _new_font(self._regular_path, self._size, false)
    self._bold = _new_font(self._bold_path, self._size, false)
    self._italic = _new_font(self._italic_path, self._size, false)
    self._bold_italic = _new_font(self._bold_italic_path, self._size, false)

    self._regular_sdf = _new_font(self._regular_path, self._size, true)
    self._bold_sdf = _new_font(self._bold_path, self._size, true)
    self._italic_sdf = _new_font(self._italic_path, self._size, true)
    self._bold_italic_sdf = _new_font(self._bold_italic_path, self._size, true)

    -- fallback fonts to support more symbols
    local noto_math = _new_font("assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf", self._size, false)
    local noto_math_sdf = _new_font("assets/fonts/NotoSansMath/NotoSansMath-Regular.ttf", self._size, true)

    for font in range(
        self._regular,
        self._bold,
        self._italic,
        self._bold_italic
    ) do
        font:setFallbacks(noto_math)
    end

    for font in range(
        self._regular_sdf,
        self._bold_sdf,
        self._italic_sdf,
        self._bold_italic_sdf
    ) do
        font:setFallbacks(noto_math_sdf)
    end

    --[[
    self._regular:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-Regular.ttf", self._size, false),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf", self._size, false)
    )

    self._italic:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-Italic.ttf", self._size, false),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf", self._size, false)
    )

    self._bold:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-Bold.ttf", self._size, false),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Bold.ttf", self._size, false)
    )

    self._bold_italic:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-BoldItalic.ttf", self._size, false),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Bold.ttf", self._size, false)
    )

    self._regular_sdf:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-Regular.ttf", self._size, true),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf", self._size, true)
    )

    self._italic_sdf:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-Italic.ttf", self._size, true),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Regular.ttf", self._size, true)
    )

    self._bold_sdf:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-Bold.ttf", self._size, true),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Bold.ttf", self._size, true)
    )

    self._bold_italic_sdf:setFallbacks(
        noto_math,
        _new_font("assets/fonts/NotoSans/NotoSans-BoldItalic.ttf", self._size, true),
        _new_font("assets/fonts/NotoSansJP/NotoSansJP-Bold.ttf", self._size, true)
    )
    ]]--
end

--- @brief set font size, in px
--- @param px Number
function rt.Font:set_size(px)
    self._size = px
    self._is_initialized = false
    self:initialize()
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
    function rt.Font:get_native(style, sdf)
        self:initialize()
        if sdf == nil then sdf = false end
        if sdf == false then
            if style == rt.FontStyle.REGULAR then
                return self._regular
            elseif style == rt.FontStyle.BOLD then
                return self._bold
            elseif style == rt.FontStyle.ITALIC then
                return self._italic
            elseif style == rt.FontStyle.BOLD_ITALIC then
                return self._bold_italic
            end
        else
            if style == rt.FontStyle.REGULAR then
                return self._regular_sdf
            elseif style == rt.FontStyle.BOLD then
                return self._bold_sdf
            elseif style == rt.FontStyle.ITALIC then
                return self._italic_sdf
            elseif style == rt.FontStyle.BOLD_ITALIC then
                return self._bold_italic_sdf
            end
        end
    end
end

--- @brief
function rt.Font:measure_glyph(label)
    self:initialize()
    return self._bold_italic:getWidth(label), self._bold_italic:getHeight(label)
end

--- @brief [internal] load default fonts and fallbacks
function rt.load_default_fonts()
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