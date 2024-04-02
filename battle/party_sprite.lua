rt.settings.battle.party_sprite = {
    corner_radius = 3,
    frame_thickness = 5
}

--- @class bt.PartySprite
bt.PartySprite = meta.new_type("PartySprite", rt.Widget, rt.Animation, function(scene, entity)
    return meta.new(bt.PartySprite, {
        _entity = entity,
        _scene = scene,
        _is_realized = false,

        _hp_bar = bt.HealthBar(entity),
        _hp_bar_is_visible = true,

        _speed_value = bt.SpeedValue(entity),
        _speed_value_is_visible = true,

        _status_bar = bt.StatusBar(entity),
        _status_bar_is_visible = true,

        _backdrop = rt.Rectangle(0, 0, 1, 1),
        _frame = rt.Rectangle(0, 0, 1, 1),
        _frame_outline = rt.Rectangle(0, 0, 1, 1),
        _frame_gradient = {} -- rt.LogGradient
    })
end)

--- @override
function bt.PartySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

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
        shape:set_corner_radius(rt.settings.battle.party_sprite.corner_radius)
    end

    self._hp_bar:realize()
    self._hp_bar:sync()

    self._speed_value:realize()
    self._speed_value:sync()

    self._status_bar:realize()
    self._status_bar:sync()
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    if self._is_realized then
        self._backdrop:resize(x, y, width, height)

        local frame_thickness = rt.settings.battle.party_sprite.frame_thickness
        local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
        self._frame:set_line_width(frame_thickness)
        self._frame_outline:set_line_width(frame_outline_thickness)

        local frame_aabb = rt.AABB(x + frame_thickness / 2, y + frame_thickness / 2, width - frame_thickness , height - frame_thickness)
        self._frame:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
        self._frame_outline:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, frame_aabb.height)
        self._frame_gradient:resize(x, y, width, height)

        local sprite_x, sprite_y = x, y
        local sprite_w, sprite_h = width, height

        self._debug_sprite = rt.Rectangle(sprite_x, sprite_y, sprite_w, sprite_h)

        local m = 0.5 * rt.settings.margin_unit
        local hp_bar_bounds = rt.AABB(
            sprite_x + frame_thickness + m,
            sprite_y + frame_thickness + m,
            sprite_w - 2 * frame_thickness - 2 * m,
            rt.settings.battle.health_bar.hp_font:get_size() + 2 * m
        )

        self._hp_bar:fit_into(hp_bar_bounds)

        local speed_value_w, speed_value_h = self._speed_value:measure()
        self._speed_value:fit_into(
            hp_bar_bounds.x + hp_bar_bounds.width - speed_value_w - rt.settings.battle.health_bar.corner_radius,
            hp_bar_bounds.y + hp_bar_bounds.height,
            speed_value_w, speed_value_h
        )

    end
end

--- @override
function bt.PartySprite:draw()
    rt.graphics.stencil(1, self._backdrop)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 1)

    self._backdrop:draw()
    if self._hp_bar_is_visible then self._hp_bar:draw() end
    if self._speed_value_is_visible then self._speed_value:draw() end

    rt.current_scene:set_debug_draw_enabled(true)
    if self._status_bar_is_visible then self._status_bar:draw() end
    rt.current_scene:set_debug_draw_enabled(false)

    rt.graphics.set_stencil_test()
    rt.graphics.stencil()

    self._frame_outline:draw()
    self._frame:draw()

    rt.graphics.stencil(2, self._frame)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, 2)
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY)
    self._frame_gradient:draw()
    rt.graphics.set_blend_mode()
    rt.graphics.set_stencil_test()
end

--- @override
function bt.PartySprite:update(delta)
    self._hp_bar:update(delta)
    self._speed_value:update(delta)
    self._status_bar:update(delta)
end