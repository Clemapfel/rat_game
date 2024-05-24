rt.settings.scrollbar = {
    corner_radius = 2
}

--- @class
rt.Scrollbar = meta.new_type("Scrollbar", rt.Widget, function()
    return meta.new(rt.Scrollbar, {
        _base = rt.Rectangle(0, 0, 1, 1),
        _base_outline = rt.Rectangle(0, 0, 1, 1),
        _cursor = rt.Rectangle(0, 0, 1, 1),
        _cursor_outline = rt.Rectangle(0, 0, 1, 1),

        _page_index = 1,
        _n_pages = 100,
        _page_size = 1,
    })
end)

--- @brief
function rt.Scrollbar:realize()
    if self._is_realized == true then return end
    self._base:set_color(rt.Palette.BACKGROUND)
    self._base_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    self._base_outline:set_is_outline(true)

    self._cursor:set_color(rt.Palette.FOREGROUND)
    self._cursor_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)
    self._cursor_outline:set_is_outline(true)

    for shape in range(self._base, self._base_outline, self._cursor, self._cursor_outline) do
        shape:set_corner_radius(rt.settings.scrollbar.corner_radius)
    end
    self._is_realized = true
end

--- @brief
function rt.Scrollbar:set_n_pages(value)
    if self._n_pages == value then return end
    self._n_pages = value
    if self._is_realized then
        self:reformat()
    end
end

--- @brief
function rt.Scrollbar:set_page_index(value, n_pages_maybe)
    local i_before, n_before = self._page_index, self._n_pages

    self._page_index = value
    if n_pages_maybe ~= nil then
        self._n_pages = n_pages_maybe
    end

    if self._is_realized and i_before ~= self._page_index or n_before ~= self._n_pages then
        self:reformat()
    end
end

--- @brief
function rt.Scrollbar:size_allocate(x, y, w, h)
    if self._is_realized == false then return end
    self._base:resize(x, y, w, h)
    self._base_outline:resize(x, y, w, h)

    local cursor_h = self._page_size / self._n_pages * h
    local cursor_y = y + self._page_index / self._n_pages * h - cursor_h

    self._cursor:resize(x, cursor_y, w, cursor_h)
    self._cursor:resize(x, cursor_y, w, cursor_h)
end

--- @brief
function rt.Scrollbar:draw()
    if self:get_is_visible() then
        self._base:draw()
        self._base_outline:draw()
        self._cursor_outline:draw()
        self._cursor:draw()
    end
end

--- @brief
function rt.Scrollbar:set_opacity(alpha)
    self._opacity = alpha
    self._base:set_opacity(alpha)
    self._base_outline:set_opacity(alpha)
    self._cursor:set_opacity(alpha)
    self._cursor_outline:set_opacity(alpha)
end

--- @brief
function rt.Scrollbar:set_color(color)
    if meta.is_hsva(color) then color = rt.hsva_to_rgba(color) end
    self._cursor:set_color(color)
end