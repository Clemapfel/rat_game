rt.settings.widget = {}

--- @class rt.Widget
rt.Widget = meta.new_abstract_type("Widget", rt.Drawable, {
    _bounds = rt.AxisAlignedRectangle(), -- maximum area
    _margin_top = 0,
    _margin_bottom = 0,
    _margin_left = 0,
    _margin_right = 0,
    _minimum_width = 1,
    _minimum_height = 1,
    _is_realized = false,
    _opacity = 1
})

--- @brief abstract method, emitted when widgets bounds should change
--- @param x Number
--- @param y Number
--- @param width Number
--- @param height Number
function rt.Widget:size_allocate(x, y, width, height)
    rt.error("" .. meta.typeof(self) .. ":size_allocate: abstract method called")
end

--- @brief realize widget
function rt.Widget:realize()
    --rt.error("" .. meta.typeof(self) .. ":realize: abstract method called")
    self._is_realized = true
end

--- @brief draw widget
function rt.Widget:draw()
    rt.error("" .. meta.typeof(self) .. ":draw: abstract method called")
end

--- @brief abstract method, returns minimum space that needs to be allocated
--- @return (Number, Number)
function rt.Widget:measure()
    local min_w, min_h = self:get_minimum_size()
    return min_w + self:get_margin_left() + self:get_margin_right(), min_h + self:get_margin_top() + self:get_margin_bottom()
end

--- @brief resize widget
function rt.Widget:reformat()
    if not self._is_realized then
        return
    end

    local x = self._bounds.x
    x = x + self._margin_left
    x = math.floor(x)

    local y = self._bounds.y
    y = y + self._margin_top
    y = math.floor(y)

    local w = self._bounds.width
    w = w - self._margin_left - self._margin_right
    if w < self._minimum_width then w = self._minimum_width end

    local h = self._bounds.height
    h = h - self._margin_top - self._margin_bottom
    if h < self._minimum_height then h = self._minimum_height end

    self:size_allocate(x, y, w, h)
end

--- @brief resize widget such that it fits into the given bounds
--- @param aabb rt.AxisAlignedRectangle
function rt.Widget:fit_into(aabb, y, w, h)
    if meta.is_number(aabb) then
        local x = aabb
        if w == nil or h == nil then
            local target_w, target_h = self:measure()
            w = which(w, target_w)
            h = which(h, target_h)
        end
        aabb = rt.AABB(x, y, w, h)
    end

    if rt.aabb_equals(self._bounds, aabb) then return end

    self._bounds = rt.AABB(
        math.round(aabb.x), math.round(aabb.y),
        math.round(aabb.width), math.round(aabb.height)
    )
    self:reformat()
end

--- @brief
function rt.Widget:get_size()
    return self._bounds.width - self._margin_left - self._margin_right, self._bounds.height - self._margin_top - self._margin_bottom
end

--- @brief
function rt.Widget:get_position()
    return self._bounds.x + self._margin_top, self._bounds.y + self._margin_left
end

--- @brief
function rt.Widget:get_bounds()
    return rt.aabb_copy(self._bounds)
end

--- @brief set start margin
--- @param margin Number
function rt.Widget:set_margin_left(margin)

    if self._margin_left == margin then return end
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
    if self._margin_right == margin then return end
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
    if self._margin_top == margin then return end
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
    if self._margin_bottom == margin then return end
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
    if self._margin_left == margin and self._margin_right == margin then return end
    self._margin_left = margin
    self._margin_right = margin
    self:reformat()
end

--- @brief set top and bottom margin
--- @param margin Number
function rt.Widget:set_margin_vertical(margin)
    if self._margin_top == margin and self._margin_bottom == margin then return end
    self._margin_top = margin
    self._margin_bottom = margin
    self:reformat()
end

--- @brief set top, bottom, left, and right margin
--- @param margin Number
function rt.Widget:set_margin(margin)
    if self._margin_left == margin and self._margin_right == margin and self._margin_top == margin and self._margin_bottom == margin then return end
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

--- @brief set size request
--- @param width Number
--- @param height Number
function rt.Widget:set_minimum_size(width, height)
    if self._minimum_width == width and self._minimum_height == height then return end
    self._minimum_width = math.max(width, 1)
    self._minimum_height = math.max(height, 1)
    self:reformat()
end

--- @brief get size request
--- @return Number, Number
function rt.Widget:get_minimum_size()
    return self._minimum_width, self._minimum_height
end

--- @override
function rt.Widget:set_opacity(alpha)
    rt.error("In " .. meta.typeof(self) .. ":set_opacity: abstract method called")
end

function rt.Widget:get_opacity()
    return self._opacity
end

--- @brief get whether widget was realized
function rt.Widget:get_is_realized()
    return self._is_realized
end

--- @brief
function rt.Widget:draw_bounds()
    love.graphics.setLineWidth(2)
    local as_hsva = rt.HSVA((meta.hash(self) % 100) / 100, 1, 1, 1)
    local as_rgba = rt.hsva_to_rgba(as_hsva)
    love.graphics.setColor(as_rgba.r, as_rgba.g, as_rgba.b, 0.2)
    love.graphics.rectangle("fill", self._bounds.x, self._bounds.y, self._bounds.width, self._bounds.height)
    love.graphics.setColor(as_rgba.r, as_rgba.g, as_rgba.b, 1)
    love.graphics.rectangle("line", self._bounds.x, self._bounds.y, self._bounds.width, self._bounds.height)
end

