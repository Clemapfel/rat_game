--- @class rt.TabLayout
rt.TabLayout = meta.new_type("TabLayout", function()
    local out = meta.new(rt.TabLayout, {
        _pages = rt.List(),
        _content_area_backdrop = rt.Rectangle(0, 0, 1, 1),
        _content_area_backdrop_outline = rt.Rectangle(0, 0, 1, 1),
        _tab_content_area_divider = rt.Line(0, 0, 1, 1),
        _current_page = 1,
    }, rt.Drawable, rt.Widget)

    out._content_area_backdrop:set_color(rt.Palette.BACKGROUND)
    out._content_area_backdrop_outline:set_color(rt.Palette.BACKGROUND_OUTLINE)
    out._content_area_backdrop_outline:set_is_outline(true)
    out._tab_content_area_divider:set_color(rt.Palette.BACKGROUND_OUTLINE)
    
    return out
end)

--- @overload rt.Drawable.draw
function rt.TabLayout:draw()
    meta.assert_isa(self, rt.TabLayout)
    if self:get_is_visible() then
        self._content_area_backdrop:draw()
        for _, page in pairs(self._pages) do
            page.label_backdrop:draw()
            page.label_backdrop_outline:draw()
            page.label:draw()
        end

        self._content_area_backdrop_outline:draw()
        self._tab_content_area_divider:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.TabLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.TabLayout)


    local tab_height = NEGATIVE_INFINITY
    for _, page in pairs(self._pages) do
        local w, h = page.label:measure()
        tab_height = math.max(tab_height, ({page.label:measure()})[2])
    end

    local tab_x = x
    local tab_y = y
    for _, page in pairs(self._pages) do
        local tab_width = ({page.label:measure()})[1] + 2 * 10

        local label_bounds = rt.AABB(tab_x, tab_y, tab_width, tab_height)
        page.label:set_margin_horizontal(10)
        page.label:fit_into(rt.AABB(tab_x, tab_y, tab_width, tab_height))
        page.label_backdrop:resize(label_bounds)
        page.label_backdrop_outline:resize(label_bounds)

        tab_x = tab_x + tab_width
    end
end

--- @overload rt.Widget.realize
function rt.TabLayout:realize()
    for _, page in pairs(self._pages) do
        page.child:realize()
        page.label:realize()
    end
    rt.Widget.realize(self)
end

--- @brief
--- @param title rt.Widget
--- @param child rt.Widget
function rt.TabLayout:add_page(title, child)
    meta.assert_isa(self, rt.TabLayout)
    meta.assert_isa(title, rt.Widget)
    meta.assert_isa(child, rt.Widget)

    self:insert_page(self._pages:size(), title, child)
end

--- @brief
function rt.TabLayout:insert_page(index, title, child)
    meta.assert_isa(self, rt.TabLayout)
    meta.assert_number(index)
    meta.assert_isa(title, rt.Widget)
    meta.assert_isa(child, rt.Widget)

    local to_push = {
        label = title,
        child = child,
        label_backdrop = rt.Rectangle(0, 0, 1, 1),
        label_backdrop_outline = rt.Rectangle(0, 0, 1, 1)
    }

    to_push.label_backdrop:set_color(self._content_area_backdrop:get_color())
    to_push.label_backdrop_outline:set_color(self._content_area_backdrop_outline:get_color())
    to_push.label_backdrop_outline:set_is_outline(true)

    self._pages:insert(index, to_push)
    child:set_parent(self)
    title:set_parent(self)
    if self:get_is_realized() then
        child:realize()
        title:realize()
    end

    self:reformat()
end

--- @brief
function rt.TabLayout:remove_page(index)
    meta.assert_isa(self, rt.TabLayout)
    if index > self._n_pages or index < 1 then
        rt.error("In rt.TabLayout.remove_page: index `" .. tostring(index) .. "` is out of bounds for a TabLayout with `" .. tostring(self._n_pages) .. "` pages")
    end

    local page = self._pages:erase(index)
    page.child:set_parent(nil)
    page.title:set_parent(nil)
end

--- @brief
function rt.TabLayout:set_page(index)
    meta.assert_isa(self, rt.TabLayout)
    if index > self._n_pages or index < 1 then
        rt.error("In rt.TabLayout.set_page: index `" .. tostring(index) .. "` is out of bounds for a TabLayout with `" .. tostring(self._n_pages) .. "` pages")
    end

    self._current_page = index
    self:reformat()
end

--- @brief
function rt.TabLayout:next_page()
    meta.assert_isa(self, rt.TabLayout)
    if self._n_pages <= 1 then return end

    local next = self._current_page + 1
    if next <= self._n_pages then
        self:set_page(next)
    end
end

--- @brief
function rt.TabLayout:previous_page()
    meta.assert_isa(self, rt.TabLayout)
    if self._n_pages <= 1 then return end

    local next = self._current_page - 1
    if next >= 1 then
        self:set_page(next)
    end
end

--- @brief
function rt.TabLayout:get_n_pages()
    meta.assert_isa(self, rt.TabLayout)
    return self._n_pages
end