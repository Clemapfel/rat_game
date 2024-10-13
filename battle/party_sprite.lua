
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
        _gradient = rt.VertexRectangle(0, 0, 1, 1),

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

    local top_color = rt.RGBA(1, 1, 1, 1)
    local bottom_color = rt.RGBA(0.4, 0.4, 0.4, 1)
    self._gradient:set_vertex_color(1, top_color)
    self._gradient:set_vertex_color(2, top_color)
    self._gradient:set_vertex_color(3, bottom_color)
    self._gradient:set_vertex_color(4, bottom_color)
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local xm, ym = rt.settings.margin_unit, rt.settings.margin_unit
    local frame_thickness = self._frame:get_thickness()
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    local total_frame_thickness = frame_thickness + 2 * frame_outline_thickness
    local current_y = y + height - ym

    local label_w, label_h = self._name:measure()
    self._name:set_justify_mode(rt.JustifyMode.CENTER)
    self._name:fit_into(x, current_y - label_h, width)
    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(x + width - xm - speed_value_w, current_y - label_h - speed_value_h + 0.5 * speed_value_h + 0.5 * label_h)
    current_y = current_y - label_h - ym

    local hp_bar_height = label_h
    local hp_bar_bounds = rt.AABB(x + xm, current_y - hp_bar_height, width - 2 * xm, hp_bar_height)
    self._health_bar:fit_into(hp_bar_bounds)
    current_y = current_y - hp_bar_bounds.height - ym

    local backdrop_bounds = rt.AABB(x, current_y, width, y + height - current_y)
    local frame_aabb = rt.AABB(backdrop_bounds.x, backdrop_bounds.y, backdrop_bounds.width, backdrop_bounds.height)
    self._frame:fit_into(frame_aabb)
    self._gradient:reformat(
        frame_aabb.x, frame_aabb.y,
        frame_aabb.x + frame_aabb.width, frame_aabb.y,
        frame_aabb.x + frame_aabb.width, frame_aabb.y + frame_aabb.height,
        frame_aabb.x, frame_aabb.y + frame_aabb.height
    )

    local consumable_aabb = rt.AABB(x + xm, frame_aabb.y - hp_bar_height, frame_aabb.width - 2 * xm, hp_bar_height)
    self._status_consumable_bar:fit_into(consumable_aabb)

    local sprite_overlap = 0.3;
    local sprite_w, sprite_h = self._sprite:get_resolution()
    sprite_w = sprite_w * 3
    sprite_h = sprite_h * 3
    self._sprite:fit_into(
        frame_aabb.x + 0.5 * frame_aabb.width - 0.5 * sprite_w - 0.25 * frame_aabb.width,
        frame_aabb.y - (1 - sprite_overlap) * sprite_h,
        sprite_w,
        sprite_h
    )
end

--- @override
function bt.PartySprite:draw()
    self._sprite:draw()
    self._frame:draw()

    local value = meta.hash(self) % 254 + 1
    rt.graphics.stencil(value, self._frame._frame)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.EQUAL, value)
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.NORMAL)
    self._gradient:draw()
    rt.graphics.set_stencil_test()
    rt.graphics.set_blend_mode()

    self._name:draw()
    self._speed_value:draw()
    self._health_bar:draw()
    self._status_consumable_bar:draw()

    self._speed_value:draw_bounds()
    self._status_consumable_bar:draw_bounds()
end

--- @override
function bt.PartySprite:update(delta)
    self._health_bar:update(delta)
    self._speed_value:update(delta)
    self._status_consumable_bar:update(delta)
    self._sprite:update(delta)
end
