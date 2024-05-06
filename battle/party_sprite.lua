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

        _backdrop = {}, -- rt.Frame
        _backdrop_backing = {}, -- rt.Spacer
    })
end)

--- @override
function bt.PartySprite:realize()
    if self._is_realized then return end
    self._is_realized = true

    -- todo: sprite?

    self._name = rt.Glyph(rt.settings.battle.party_sprite.font, self._entity:get_name(), {
        bold = true
    })

    self._health_bar:realize()
    self._health_bar:set_use_percentage(false)
    self._health_bar:synchronize(self._entity)

    self._speed_value:realize()
    self._speed_value:synchronize(self._entity)

    self._status_bar:realize()
    self._status_bar:synchronize(self._entity)
    self._status_bar:set_alignment(bt.StatusBarAlignment.LEFT)

    self._backdrop_backing = rt.Spacer()
    self._backdrop = rt.Frame()
    self._backdrop:set_child(self._backdrop_backing)

    self._backdrop_backing:realize()
    self._backdrop:realize()

    self._backdrop:set_opacity(1)
    self._backdrop_backing:set_opacity(1)

    self:set_is_animated(true)
    self:reformat()
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local current_y = y + height

    local m = rt.settings.margin_unit
    local hp_bar_height = rt.settings.battle.health_bar.hp_font:get_size() + 2 * 0.5 * m
    local hp_bar_bounds = rt.AABB(
        x + m,
        y + height - m - hp_bar_height,
        width - 2 * m,
        hp_bar_height
    )
    self._health_bar:fit_into(hp_bar_bounds)
    current_y = current_y - m - hp_bar_bounds.height - m

    local label_h = select(2, self._name:get_size())
    self._name:set_position(x + 1.5 * m, current_y - label_h)
    current_y = current_y - label_h - m

    self._backdrop:fit_into(x, current_y, width, y + height - current_y)

    local speed_value_w = select(1, self._speed_value:measure())
    local status_bar_bounds = rt.AABB(
        x + m,
        current_y - self._backdrop:get_thickness() - hp_bar_height,
        width - 2 * m - speed_value_w - m,
        hp_bar_height
    )
    self._status_bar:fit_into(status_bar_bounds)
    self._speed_value:fit_into(x + width - m - speed_value_w, status_bar_bounds.y)
end

--- @override
function bt.PartySprite:draw()
    if not self._is_realized == true then return false end
    --self._sprite:draw()
    self._backdrop:draw()
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