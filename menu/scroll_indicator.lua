--- @class mn.ScrollIndicator
mn.ScrollIndicator = meta.new_type("ScrollIndicator", rt.Drawable, function(...)
    local out = meta.new(mn.ScrollIndicator, {
        _body = nil, -- rt.Polygon
        _outline = nil, -- rt.Polygon
    })
    if select("#", ...) ~= 0 then out:reformat(...) end
    return out
end)

--- @brief
function mn.ScrollIndicator:reformat(center_x, center_y, width, thickness, angle)
    self._body = rt.Polygon(self._generate_body(center_x, center_y, width, thickness, angle))
    self._outline = rt.LineStrip(self._generate_outline(center_x, center_y, width, thickness, angle))

    self._body:set_color(rt.Palette.FOREGROUND)
    self._outline:set_color(rt.Palette.BLACK)
end

--- @override
function mn.ScrollIndicator:draw()
    self._body:draw()
    self._outline:draw()
end

--- @brief
function mn.ScrollIndicator._generate_body(center_x, center_y, angle, width, thickness)
    thickness = which(thickness, rt.settings.margin_unit)
    width = which(width, 6 * rt.settings.margin_unit)
    angle = which(angle, (2 * math.pi) / 3)
    angle = math.pi - angle

    local right_x, right_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, angle / 2)
    local left_x, left_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, -1 * (math.pi + angle / 2))

    local top = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, -1 * (math.pi / 2))
    end

    local bottom = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, math.pi / 2)
    end

    local center_top_x, center_top_y = top(center_x, center_y)
    local center_bottom_x, center_bottom_y = bottom(center_x, center_y)
    local right_top_x, right_top_y = top(right_x, right_y)
    local right_bottom_x, right_bottom_y = bottom(right_x, right_y)
    local left_top_x, left_top_y = top(left_x, left_y)
    local left_bottom_x, left_bottom_y = bottom(left_x, left_y)

    return {
        center_top_x, center_top_y,
        right_top_x, right_top_y,
        right_bottom_x, right_bottom_y,

        center_bottom_x, center_bottom_y,
        center_top_x, center_top_y,
        right_bottom_x, right_bottom_y,

        center_top_x, center_top_y,
        left_top_x, left_top_y,
        left_bottom_x, left_bottom_y,

        center_top_x, center_top_y,
        center_bottom_x, center_bottom_y,
        left_bottom_x, left_bottom_y
    }
end

--- @brief
function mn.ScrollIndicator._generate_outline(center_x, center_y, angle, width, thickness)
    thickness = which(thickness, rt.settings.margin_unit)
    width = which(width, 6 * rt.settings.margin_unit)
    angle = which(angle, (2 * math.pi) / 3)
    angle = math.pi - angle

    local right_x, right_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, angle / 2)
    local left_x, left_y = rt.translate_point_by_angle(center_x, center_y, 0.5 * width, -1 * (math.pi + angle / 2))

    local top = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, -1 * (math.pi / 2))
    end

    local bottom = function(x, y)
        return rt.translate_point_by_angle(x, y, 0.5 * thickness, math.pi / 2)
    end

    local center_top_x, center_top_y = top(center_x, center_y)
    local center_bottom_x, center_bottom_y = bottom(center_x, center_y)
    local right_top_x, right_top_y = top(right_x, right_y)
    local right_bottom_x, right_bottom_y = bottom(right_x, right_y)
    local left_top_x, left_top_y = top(left_x, left_y)
    local left_bottom_x, left_bottom_y = bottom(left_x, left_y)

    return {
        center_top_x, center_top_y,
        right_top_x, right_top_y,
        right_bottom_x, right_bottom_y,
        center_bottom_x, center_bottom_y,
        left_bottom_x, left_bottom_y,
        left_top_x, left_top_y,
        center_top_x, center_top_y,
    }
end

--- @brief
function mn.ScrollIndicator:set_color(color)
    self._body:set_color(color)
end