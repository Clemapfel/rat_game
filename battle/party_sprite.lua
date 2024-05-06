rt.settings.battle.party_sprite = {
    idle_animation_id = "idle",
    knocked_out_animation_id = "knocked_out",
    font = rt.settings.font.default_small,
}

--- @class bt.PartySprite
bt.PartySprite = meta.new_type("PartySprite", rt.Widget, rt.Animation, function(entity)
    return meta.new(bt.PartySprite, {
        _entity = entity,
        _sprite = {}, -- rt.Glyph

        _name = rt.Label("<b>" .. entity:get_name() .. "</b>"),
        _health_bar = bt.HealthBar(entity),
        _speed_value = bt.SpeedValue(entity),
        _status_bar = bt.StatusBar(entity),

        _opacity = 1,
        _state = bt.EntityState.ALIVE,

        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _frame_gradient = {}, -- rt.LogGradient
    })
end)

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
end

--- @override
function bt.PartySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    -- todo: sprite?

    self._name = rt.Glyph(rt.settings.battle.party_sprite.font, self._entity:get_name(), {
        bold = true,
        is_outlined = true,
        outline_color = rt.Palette.BLACK
    })

    self._health_bar:realize()
    self._health_bar:set_use_percentage(false)
    self._health_bar:synchronize(self._entity)

    self._speed_value:realize()
    self._speed_value:synchronize(self._entity)

    self._status_bar:realize()
    self._status_bar:synchronize(self._entity)
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

    self:set_is_animated(true)
    self:reformat()
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local m = rt.settings.margin_unit
    local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    self._frame:set_line_width(frame_thickness)
    self._frame_outline:set_line_width(frame_outline_thickness)
    local total_frame_thickness = frame_thickness + frame_outline_thickness

    height = height - 0.5 * total_frame_thickness - 1.5 * rt.settings.margin_unit
    local current_y = y + height

    current_y = current_y - m
    local label_w, label_h = self._name:get_size()
    self._name:set_position(x + 1.5 * m, current_y - label_h)
    current_y = current_y - label_h - m

    local hp_bar_height = rt.settings.battle.health_bar.hp_font:get_size() + m
    local hp_bar_bounds = rt.AABB(x + m, current_y - hp_bar_height, width - 2 * m, hp_bar_height)
    self._health_bar:fit_into(hp_bar_bounds)
    current_y = current_y - hp_bar_bounds.height - m

    local backdrop_bounds = rt.AABB(x, current_y, width, y + height - current_y)
    self._backdrop:resize(backdrop_bounds)

    local speed_value_w = select(1, self._speed_value:measure())
    local status_bar_bounds = rt.AABB(x + m, current_y - hp_bar_height - 0.5 * total_frame_thickness, width - 2 * m - speed_value_w - m, hp_bar_height)
    self._status_bar:fit_into(status_bar_bounds)
    self._speed_value:fit_into(x + width - m - speed_value_w, status_bar_bounds.y)

    local frame_aabb = rt.AABB(backdrop_bounds.x, backdrop_bounds.y, backdrop_bounds.width, backdrop_bounds.height)
    self._frame:resize(rt.aabb_unpack(frame_aabb))
    self._frame_outline:resize(rt.aabb_unpack(frame_aabb))
    self._frame_gradient:resize(frame_aabb.x - 0.5 * total_frame_thickness, frame_aabb.y - 0.5 * total_frame_thickness, frame_aabb.width + total_frame_thickness, frame_aabb.height + total_frame_thickness)
end

--- @override
function bt.PartySprite:draw()
    if not self._is_realized == true then return false end

    self._backdrop:draw()
    self._frame_outline:draw()
    self._frame:draw()

    rt.graphics.stencil(2, self._frame)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 2)
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
function bt.PartySprite:synchronize(entity)
    self._health_bar:synchronize(self._entity)
    self._speed_value:synchronize(self._entity)
    self._status_bar:synchronize(self._entity)
end

--- @override
function bt.PartySprite:update(delta)
    self._health_bar:update(delta)
    self._speed_value:update(delta)
    self._status_bar:update(delta)
end