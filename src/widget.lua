rt.settings.widget = {
    selection_indicator_width = 2,
    selection_indicator_outline_width = 5,
    selection_indicator_corner_radius = 5,
    selection_indicator_alpha = 1
}

--- @class rt.Alignment
rt.Alignment = meta.new_enum({
    START = "ALIGNMENT_START",
    CENTER = "ALIGNMENT_CENTER",
    END = "ALIGNMENT_END"
})

--- @class rt.Orientation
rt.Orientation = meta.new_enum({
    HORIZONTAL = "ORIENTATION_HORIZONTAL",
    VERTICAL = "ORIENTATION_VERTICAL"
})

--- @class rt.Widget
rt.Widget = meta.new_abstract_type("Widget")
rt.Widget._bounds = rt.AxisAlignedRectangle()     -- maximum area
rt.Widget._margin_top = 0
rt.Widget._margin_bottom = 0
rt.Widget._margin_left = 0
rt.Widget._margin_right = 0
rt.Widget._expand_horizontally = true
rt.Widget._expand_vertically = true
rt.Widget._horizontal_alignment = rt.Alignment.CENTER
rt.Widget._vertical_alignment = rt.Alignment.CENTER
rt.Widget._minimum_width = 1
rt.Widget._minimum_height = 1
rt.Widget._realized = false
rt.Widget._focused = true
rt.Widget._parent = nil
rt.Widget._selected = false
rt.Widget._is_hidden = false
rt.Widget._final_pos_x = 0
rt.Widget._final_pos_y = 0

--- @brief abstract method, emitted when widgets bounds should change
--- @param x Number
--- @param y Number
--- @param width Number
--- @param height Number
function rt.Widget:size_allocate(x, y, width, height)
    rt.error("" .. meta.typeof(self) .. ":size_allocate: abstract method called. Neither `rt.Widget.get_top_level_widget` nor `rt.Widget.size_allocate` are implemented for type `" .. meta.typeof(self) .. "`")
end

--- @brief method that can be overloaded by compound widgets
function rt.Widget:get_top_level_widget()
    return nil
end

--- @brief abstract method, returns minimum space that needs to be allocated
--- @return (Number, Number)
function rt.Widget:measure()

    local current = self
    local next = self:get_top_level_widget()

    if not meta.is_nil(next) then
        while next ~= nil do
            current = next
            next = current:get_top_level_widget()
        end
        return current:measure()
    else
        local min_w, min_h = self:get_minimum_size()
        return min_w + self:get_margin_left() + self:get_margin_right(), min_h + self:get_margin_top() + self:get_margin_bottom()
    end
end

--- @brief realize widget
function rt.Widget:realize()

    if self._realized then return end
    self._realized = true

    local current = self
    local next = self:get_top_level_widget()
    while next ~= nil do
        current = next
        next = current:get_top_level_widget()
    end
    current:realize()
    current:reformat()
end

--- @brief get whether widget was realized
function rt.Widget:get_is_realized()
    return self._realized
end

--- @brief resize widget
function rt.Widget:reformat()
    if not self._realized then
        return
    end

    local min_w, min_h = self:measure()
    min_w = clamp(min_w, 1)
    min_h = clamp(min_h, 1)

    local x, width = rt.Widget._calculate_size(self,
        min_w,
        self._margin_left,
        self._margin_right,
        self._horizontal_alignment,
        self._expand_horizontally,
        self._bounds.x,
        self._bounds.width
    )

    local y, height = rt.Widget._calculate_size(self,
        min_h,
        self._margin_top,
        self._margin_bottom,
        self._vertical_alignment,
        self._expand_vertically,
        self._bounds.y,
        self._bounds.height
    )

    if width < 1 or height < 1 then
        return
    end

    height = math.max(height, 1)
    width = math.max(width, 1)

    x = math.floor(x) -- align to pixelgrid to avoid rasterizer artifacting
    y = math.floor(y)

    self._final_pos_x = x
    self._final_pos_y = y

    -- if widget is compound widget, size_allocate top-level, else call virtual function


    local current = self
    local next = self:get_top_level_widget()
    while next ~= nil do
        current = next
        next = current:get_top_level_widget()
    end
    current:size_allocate(x, y, width, height)
end

--- @brief implements rt.Drawable.draw
function rt.Widget:draw()
    -- if widget is compound widget, draw top-level, else call virtual function

    local current = self:get_top_level_widget()
    local next = nil
    while next ~= nil do
        current = next
        next = next:get_top_level_widget()
    end

    if meta.is_nil(current) then
        rt.error("" .. meta.typeof(self) .. ":draw: abstract method called. Neither `rt.Widget.get_top_level_widget` nor `rt.Drawable.draw` are implemented for type `" .. meta.typeof(self) .. "`")
    else
        current:draw()
    end
end

--- @brief resize widget such that it fits into the given bounds
--- @param aabb rt.AxisAlignedRectangle
function rt.Widget:fit_into(aabb, y, w, h)
    if meta.is_number(aabb) then
        aabb = rt.AABB(aabb, y, w, h)
    end

    self._bounds = aabb
    self:reformat()
end

--- @brief get size of allocation
--- @return (Number, Number)
function rt.Widget:get_size()
    return self._bounds.width - self:get_margin_left() - self:get_margin_right(), self._bounds.height - self:get_margin_top() - self:get_margin_bottom()
end

--- @brief get width of size allocation
--- @return Number
function rt.Widget:get_width()
    return select(1, self:get_size())
end

--- @brief get height of size allocation
--- @return Number
function rt.Widget:get_height()
    return select(2, self:get_size())
end

--- @brief get top left of allocation
--- @return (Number, Number)
function rt.Widget:get_position()
    return self._final_pos_x, self._final_pos_y ---self._bounds.x + self:get_margin_left(), self._bounds.y + self:get_margin_top()
end

--- @brief get bounds
function rt.Widget:get_bounds()
    local x, y = self:get_position()
    local w, h = self:get_size()
    return rt.AABB(x, y, w, h)
end

--- @brief set start margin
--- @param margin Number
function rt.Widget:set_margin_left(margin)

    self._margin_left = margin
    self:reformat()
end

--- @brief get start margin
--- @return Number
function rt.Widget:get_margin_left()

    return self._margin_left
end

--- @brief set end margin
--- @param margin Number
function rt.Widget:set_margin_right(margin)

    self._margin_right = margin
    self:reformat()
end

--- @brief get end margin
--- @return Number
function rt.Widget:get_margin_right()

    return self._margin_right
end

--- @brief set top margin
--- @param margin Number
function rt.Widget:set_margin_top(margin)

    self._margin_top = margin
    self:reformat()
end

--- @brief get top margin
--- @return Number
function rt.Widget:get_margin_top()

    return self._margin_top
end

--- @brief set bottom margin
--- @param margin Number
function rt.Widget:set_margin_bottom(margin)

    self._margin_bottom = margin
    self:reformat()
end

--- @brief get bottom margin
--- @return Number
function rt.Widget:get_margin_bottom()

    return self._margin_bottom
end

--- @brief set left and right margin
--- @param margin Number
function rt.Widget:set_margin_horizontal(margin)

    self._margin_left = margin
    self._margin_right = margin
    self:reformat()
end

--- @brief set top and bottom margin
--- @param margin Number
function rt.Widget:set_margin_vertical(margin)

    self._margin_top = margin
    self._margin_bottom = margin
    self:reformat()
end

--- @brief set top, bottom, left, and right margin
--- @param margin Number
function rt.Widget:set_margin(margin)

    self._margin_top = margin
    self._margin_bottom = margin
    self._margin_left = margin
    self._margin_right = margin
    self:reformat()
end

--- @brief get all margins
--- @return (Number, Number, Number, Number) top, right, bottom, left
function rt.Widget:get_margins()
    return self._margin_top, self._margin_right, self._margin_bottom, self._margin_left
end

--- @brief set expansion along x-axis
--- @param b Boolean
function rt.Widget:set_expand_horizontally(b)


    self._expand_horizontally = b
    self:reformat()
end

--- @brief get expansion along x-axis
--- @return Number
function rt.Widget:get_expand_horizontally()

    return self._expand_horizontally
end

--- @brief set expansion along y-axis
--- @param b Boolean
function rt.Widget:set_expand_vertically(b)


    self._expand_vertically = b
    self:reformat()
end

--- @brief get expansion along y-axis
--- @return Boolean
function rt.Widget:get_expand_vertically()

    return self._expand_vertically
end

--- @brief set expansion along both axes
--- @param b Boolean
function rt.Widget:set_expand(b)


    self._expand_horizontally = b
    self._expand_vertically = b
    self:reformat()
end

--- @brief set alignment along x-axis
--- @param alignment rt.Alignment
function rt.Widget:set_horizontal_alignment(alignment)


    self._horizontal_alignment = alignment
    self:reformat()
end

--- @brief get alignment along x-axis
--- @return rt.Alignment
function rt.Widget:get_horizontal_alignment()

    return self._horizontal_alignment
end

--- @brief set alignment along y-axis
--- @param alignment rt.Alignment
function rt.Widget:set_vertical_alignment(alignment)


    self._vertical_alignment = alignment
    self:reformat()
end

--- @brief get alignment along y-axis
--- @return rt.Alignment
function rt.Widget:get_vertical_alignment()

    return self._vertical_alignment
end

--- @brief set alignment among both axes
--- @param alignment rt.Alignment
function rt.Widget:set_alignment(alignment)


    self._horizontal_alignment = alignment
    self._vertical_alignment = alignment
    self:reformat()
end

--- @brief set size request
--- @param width Number
--- @param height Number
function rt.Widget:set_minimum_size(width, height)


    self._minimum_width = width
    self._minimum_height = height
    self:reformat()
end

--- @brief get size request
--- @return Number, Number
function rt.Widget:get_minimum_size()

    return self._minimum_width, self._minimum_height
end

--- @brief get whether widget currently holds input focus
function rt.Widget:get_has_focus()

    return self._focused
end

--- @brief set the parent property of the child. If it already has a parent, print a warning
function rt.Widget:set_parent(other)


    if meta.is_nil(other) then
        self._parent = nil
        return
    end


    if not meta.is_nil(self._parent) then
        rt.warning("In Widget:set_parent: replacing parent of child `" .. meta.typeof(self) .. "`, which already has a parent")
    end

    self._parent = other
end

--- @brief get parent
function rt.Widget:get_parent()

    return self._parent
end

--- @brief [internal] calulcate size along one axis
--- @param self rt.Widget
--- @param width Number
--- @param margin_start Number
--- @param margin_end Number
--- @param align rt.Alignment
--- @param expand Boolean
--- @param range_start Number minimum x
--- @param range_size Number maximum width
--- @return (Number, Number) x, width
function rt.Widget._calculate_size(self, width, margin_start, margin_end, align, expand, range_start, range_size)

    local x = range_start
    local w = width
    local m0 = margin_start
    local m1 = margin_end
    local L = range_size

    if align == rt.Alignment.START and expand == false then
        return x + m0, w
    elseif align == rt.Alignment.CENTER and expand == false then
        return x + (L - w) / 2, w
    elseif align == rt.Alignment.END and expand == false then
        return x + L - m1 - w, w
    elseif align == rt.Alignment.START and expand == true then
        return x + m0, L - m0 - m1
    elseif align == rt.Alignment.CENTER and expand == true then
        return x + m0, math.max(w, L - m0 - m1)
    elseif align == rt.Alignment.END and expand == true then
        local w_out = math.max(w, (L - m0 - m1) / 2)
        return x + L - m1 - w_out, w_out
    end
end

--- @brief
function rt.Widget:draw_selection_indicator()

    local x, y = self:get_position()
    local w, h = self:get_size()

    local color = rt.Palette.SELECTION_OUTLINE
    local width = rt.settings.widget.selection_indicator_outline_width
    local corner_radius = rt.settings.widget.selection_indicator_corner_radius
    local alpha = rt.settings.widget.selection_indicator_alpha
    love.graphics.setColor(color.r, color.g, color.b, alpha)
    love.graphics.setLineWidth(width)
    love.graphics.rectangle("line", x - 0.5 * width, y - 0.5 * width, w + width, h + width, corner_radius, corner_radius)

    color = rt.Palette.SELECTION
    love.graphics.setColor(color.r, color.g, color.b, alpha)
    love.graphics.setLineWidth(rt.settings.widget.selection_indicator_width)
    love.graphics.rectangle("line", x - 0.5 * width, y - 0.5 * width, w + width, h + width, corner_radius, corner_radius)
end

--- @brief
function rt.Widget:set_is_selected(b)


    self._selected = b
end

--- @brief
function rt.Widget:get_is_selected()

    return self._selected
end

--- @brief
function rt.Widget:set_has_focus(b)
    self._focused = b
end

--- @brief
function rt.Widget:get_has_focus()

    return self._focused
end

--- @brief [internal] draw allocation component as wireframe
function rt.Widget:draw_bounds()

    local x, y = self:get_position()
    local w, h = self:get_size()

    love.graphics.setLineWidth(1)
    love.graphics.setLineStyle("smooth")

    -- outer bounds with margin
    love.graphics.setColor(0, 1, 1, 1)
    love.graphics.line(
        x + self._margin_left, y + self._margin_top,
        x + self._margin_left + w - self._margin_right, y + self._margin_top,
        x + self._margin_left + w - self._margin_right, y + self._margin_top + h - self._margin_bottom,
        x + self._margin_left, y + self._margin_top + h - self._margin_bottom,
        x + self._margin_left, y + self._margin_top
    )

    -- outer bounds
    love.graphics.setColor(1, 0, 1, 1)
    love.graphics.line(
        x, y,
        x + w, y ,
        x + w, y + h,
        x, y + h,
        x, y
    )

    -- final size
    love.graphics.setColor(1, 1, 0, 1)
    local allocation = self:get_bounds()
    love.graphics.line(
        allocation.x, allocation.y,
        allocation.x + allocation.width, allocation.y,
        allocation.x + allocation.width, allocation.y + allocation.height,
        allocation.x, allocation.y + allocation.height,
        allocation.x, allocation.y
    )

    love.graphics.setColor(0, 1, 0, 1)
    love.graphics.setPointSize(4)
    love.graphics.points(x + w / 2, y + h / 2)
end

--- @brief [internal] test widget
function rt.test.test_widget()
    error("TODO")
end
