
--- @class bt.PartySprite
bt.PartySprite = meta.new_type("BattlePartySprite", bt.EntitySprite, function(entity)

    local entity_id_to_sprite_id = {
        ["RAT"] = "battle/rat_battle",
        ["GIRL"] = "battle/girl_battle",
        ["MC"] = "battle/mc_battle",
        ["PROF"] = "battle/prof_battle",
        ["WILDCARD"] = "battle/wildcard_battle"
    }

    return meta.new(bt.PartySprite, {
        _frame = rt.Frame(),

        _health_bar = bt.HealthBar(0, entity:get_hp_base(), entity:get_hp()),
        _speed_value = bt.SpeedValue(entity:get_speed()),
        _status_consumable_bar = bt.OrderedBox(),
        _name = rt.Label("<o>" .. entity:get_name() .. "</o>"),

        _sprite = rt.Sprite(entity_id_to_sprite_id[entity:get_id()]),
        _sprite_is_visible = false,
    })
end)

--- @override
function bt.PartySprite:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._frame:realize()
    self._health_bar:realize()
    self._speed_value:realize()
    self._status_consumable_bar:realize()
    self._sprite:realize()
    self._name:realize()
    self._name:set_justify_mode(rt.JustifyMode.LEFT)

    --self._frame:set_thickness(0.5 * rt.settings.margin_unit)
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local xm, ym = rt.settings.margin_unit, rt.settings.margin_unit
    local frame_thickness = self._frame:get_thickness()

    local name_w, name_h = self._name:measure()
    local speed_w, speed_h = self._name:measure()
    local row_h = math.max(name_h, speed_h)

    local current_x = x + xm + frame_thickness
    local current_y = y + height - frame_thickness - ym  - row_h

    self._name:fit_into(current_x, current_y + 0.5 * row_h - 0.5 * name_h, name_w, name_h)
    self._speed_value:fit_into(current_x + width - xm - frame_thickness - speed_w, current_y + 0.5 * row_h - 0.5 * speed_h, speed_w, speed_h)

    current_y = current_y - ym - row_h
    self._health_bar:fit_into(current_x, current_y, width - 2 * xm - 2 * frame_thickness, row_h)

    current_y = current_y - ym
    local frame_h = y + height - current_y + 2 * frame_thickness
    self._frame:fit_into(x, y + height - frame_h, width, frame_h)

    current_y = current_y - frame_thickness - row_h
    self._status_consumable_bar:fit_into(x, current_y, width, row_h)
end

--- @override
function bt.PartySprite:draw()
    self._sprite:draw()
    self._frame:draw()
    self._name:draw()
    self._speed_value:draw()
    self._health_bar:draw()
    self._status_consumable_bar:draw()

    self._speed_value:draw_bounds()
    self._status_consumable_bar:draw_bounds()
end

--- @override
function bt.PartySprite:update(delta)
    self._health_bar:update()
    self._speed_value:update()
    self._status_consumable_bar:update()
    self._sprite:update()
end