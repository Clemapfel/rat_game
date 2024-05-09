rt.settings.battle.party_sprite = {
    font = rt.settings.font.default_small,
}

--- @class bt.PartySprite
bt.PartySprite = meta.new_type("PartySprite", bt.BattleSprite, function(entity)
    return meta.new(bt.PartySprite, {
        _entity = entity,

        _name = rt.Label("<b>" .. entity:get_name() .. "</b>"),

        _health_bar = bt.HealthBar(entity),
        _speed_value = bt.SpeedValue(entity),
        _status_bar = bt.StatusBar(entity),

        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _frame_gradient = {}, -- rt.LogGradient
    })
end)

--- @brief
function bt.PartySprite:_update_state()
    if self._state == bt.EntityState.ALIVE then
        self._backdrop:set_color(rt.settings.battle.priority_queue_element.base_color)
        self._name:set_color(rt.RGBA(1, 1,1, 1))
    elseif self._state == bt.EntityState.KNOCKED_OUT then
        self._backdrop:set_color(rt.Palette.KNOCKED_OUT)
        self._name:set_color(rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.knocked_out_shape_alpha))
    elseif self._state == bt.EntityState.DEAD then
        self._backdrop:set_color(rt.settings.battle.priority_queue_element.dead_base_color)
        self._name:set_color(rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.dead_shape_alpha))
    end

    if self._is_selected then
        self._frame:set_color(rt.settings.battle.priority_queue_element.selected_frame_color)
    end
end

--- @override
function bt.PartySprite:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._name = rt.Glyph(rt.settings.battle.party_sprite.font, self._entity:get_name(), {
        bold = true,
        is_outlined = true,
        outline_color = rt.Palette.BLACK
    })

    self._health_bar:realize()
    self._speed_value:realize()
    self._status_bar:realize()

    self._health_bar:set_use_percentage(false)
    self._status_bar:set_alignment(bt.StatusBarAlignment.LEFT)

    self._backdrop:set_is_outline(false)
    self._frame:set_is_outline(true)
    self._frame_outline:set_is_outline(true)

    self._backdrop:set_color(rt.settings.battle.priority_queue_element.base_color)
    self._frame:set_color(rt.settings.battle.priority_queue_element.frame_color)
    self._frame_outline:set_color(rt.Palette.BACKGROUND)

    self._frame_gradient = rt.LogGradient(
        rt.RGBA(0.8, 0.8, 0.8, 1),
        rt.RGBA(1, 1, 1, 1)
    )
    self._frame_gradient:set_is_vertical(true)
    for shape in range(self._backdrop, self._frame, self._frame_outline) do
        shape:set_corner_radius(rt.settings.battle.priority_queue_element.corner_radius)
    end

    for to_animate in range(self, self._health_bar, self._speed_value, self._status_bar, self._sprite) do
        to_animate:set_is_animated(true)
    end
    self:reformat()
    self:synchronize(self._entity)
end

--- @override
function bt.PartySprite:update(delta)
    -- noop
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    self._frame:set_line_width(frame_thickness)
    self._frame_outline:set_line_width(frame_outline_thickness)
    local total_frame_thickness = frame_thickness + frame_outline_thickness

    self._bounds = rt.AABB(x, y, width, height)

    x = x + total_frame_thickness
    y = y + total_frame_thickness
    width = width - 2 * total_frame_thickness
    height = height - 2 * total_frame_thickness

    height = height - 0.5 * total_frame_thickness - 1.5 * m
    local current_y = y + height - m

    local label_w, label_h = self._name:get_size()
    self._name:set_position(x + 0.5 * width - 0.5 * label_w, current_y - label_h)
    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(x + width - m - speed_value_w, current_y - label_h - speed_value_h + 0.5 * speed_value_h + 0.5 * label_h)
    self._status_bar:fit_into(x + m, current_y - label_h, width, label_h)

    current_y = current_y - label_h - m

    local hp_bar_height = rt.settings.battle.health_bar.hp_font:get_size() + m
    local hp_bar_bounds = rt.AABB(x + m, current_y - hp_bar_height, width - 2 * m, hp_bar_height)
    self._health_bar:fit_into(hp_bar_bounds)
    current_y = current_y - hp_bar_bounds.height - m

    local backdrop_bounds = rt.AABB(x, current_y, width, y + height - current_y)
    self._backdrop:resize(backdrop_bounds)

    local frame_aabb = rt.AABB(backdrop_bounds.x, backdrop_bounds.y, backdrop_bounds.width, backdrop_bounds.height)
    self._frame:resize(rt.aabb_unpack(frame_aabb))
    self._frame_outline:resize(rt.aabb_unpack(frame_aabb))
    self._frame_gradient:resize(frame_aabb.x - 0.5 * total_frame_thickness, frame_aabb.y - 0.5 * total_frame_thickness, frame_aabb.width + total_frame_thickness, frame_aabb.height + total_frame_thickness)

    -- update bounds so get_bounds only returns visible area, not allocated area
    self._bounds.y = current_y - total_frame_thickness
    self._bounds.height = frame_aabb.height + 2 * total_frame_thickness
    self:_update_state()
end

--- @override
function bt.PartySprite:draw()
    if not self._is_realized == true then return false end
    if self._is_visible == false then return end

    self._backdrop:draw()
    self._frame_outline:draw()
    self._frame:draw()

    local stencil_value = meta.hash(self) % 255
    rt.graphics.stencil(stencil_value, self._frame)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, stencil_value)
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    self._frame_gradient:draw()
    rt.graphics.set_blend_mode()
    rt.graphics.set_stencil_test()

    self._health_bar:draw()
    self._name:draw()
    self._status_bar:draw()
    self._speed_value:draw()
end

--- @brief
function bt.PartySprite:set_is_selected(b)
    self._is_selected = b
    self:_update_state()
end

--- @brief
function bt.PartySprite:get_bounds()
    return self._bounds
end

--- @brief
function bt.PartySprite:set_opacity(alpha)
    self._opacity = alpha

    for object in range(self._health_bar, self._name, self._speed_value, self._status_bar, self._backdrop, self._frame, self._frame_outline, self._frame_gradient) do
        object:set_opacity(alpha)
    end
end
