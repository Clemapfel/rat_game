--- @class bt.GradientFrame
bt.GradientFrame = meta.new_type("GradientFrame", rt.Widget, function()
    return meta.new(bt.GradientFrame, {
        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _frame_gradient = {}, -- rt.LogGradient
        _frame_color = rt.settings.battle.priority_queue_element.frame_color,
        _backdrop_color = rt.settings.battle.priority_queue_element.base_color,
        _gradient_visible = true
    })
end)

--- @brief
function bt.GradientFrame:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(self._backdrop_color)
    self._frame:set_color(self._frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    self._frame_gradient = rt.LogGradient(
        rt.RGBA(0.8, 0.8, 0.8, 1),
        rt.RGBA(1, 1, 1, 1)
    )
    self._frame_gradient:set_is_vertical(true)
    for shape in range(self._backdrop, self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.priority_queue_element.corner_radius)
    end
end

--- @brief
function bt.GradientFrame:size_allocate(x, y, width, height)
    local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    self._frame:set_line_width(frame_thickness)
    self._frame_outline:set_line_width(frame_outline_thickness)
    local total_frame_thickness = frame_thickness + frame_outline_thickness

    local backdrop_bounds = rt.AABB(x, y, width, height)
    self._backdrop:resize(backdrop_bounds)

    local frame_aabb = rt.AABB(backdrop_bounds.x, backdrop_bounds.y, backdrop_bounds.width, backdrop_bounds.height)
    self._frame:resize(rt.aabb_unpack(frame_aabb))
    self._frame_outline:resize(rt.aabb_unpack(frame_aabb))
    self._frame_gradient:resize(frame_aabb.x - 0.5 * total_frame_thickness, frame_aabb.y - 0.5 * total_frame_thickness, frame_aabb.width + total_frame_thickness, frame_aabb.height + total_frame_thickness)
end

--- @brief
function bt.GradientFrame:draw()
    if not self._is_realized == true then return false end
    if self._is_visible == false then return end
    self._backdrop:draw()
    self._frame_outline:draw()
    self._frame:draw()

    if self._gradient_visible == true then
        local stencil_value = meta.hash(self) % 255
        rt.graphics.stencil(stencil_value, self._frame)
        rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
        rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
        self._frame_gradient:draw()
        rt.graphics.set_blend_mode()
        rt.graphics.set_stencil_test()
    end
end

--- @brief
function bt.GradientFrame:set_color(frame_color, backdrop_color)
    self._frame_color = which(frame_color, self._frame_color)
    self._backdrop_color = which(backdrop_color, self._backdrop_color)

    if self._is_realized then
        self._frame:set_color(self._frame_color)
        self._backdrop:set_color(self._backdrop_color)
    end
end

--- @brief
function bt.GradientFrame:set_opacity(alpha)
    self._opacity = alpha
    self._backdrop:set_opacity(alpha)
    self._frame:set_opacity(alpha)
    self._frame_outline:set_opacity(alpha)
    self._frame_gradient:set_opacity(alpha)
end

--- @brief
function bt.GradientFrame:set_gradient_visible(b)
    self._gradient_visible = b
end

--- @brief
function bt.GradientFrame:get_frame_thickness()
    local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    return frame_thickness + 2 * frame_outline_thickness
end
