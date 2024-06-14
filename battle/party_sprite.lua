rt.settings.battle.party_sprite = {
    font = rt.settings.font.default_small,
    sprite_reveal_speed = 600, -- px per second
}

--- @class bt.PartySprite
bt.PartySprite = meta.new_type("PartySprite", bt.BattleSprite, function(entity)
    return meta.new(bt.PartySprite, {
        _entity = entity,

        _name = rt.Label("<b>" .. entity:get_name() .. "</b>"),

        _health_bar = bt.HealthBar(entity),
        _speed_value = bt.SpeedValue(entity),
        _status_bar = bt.StatusBar(entity),
        _consumable_bar = bt.ConsumableBar(entity),

        _frame = bt.GradientFrame(),

        _sprite = rt.Sprite(entity:get_sprite_id()),
        _sprite_stencil = {},
        _sprite_visible = false,
        _current_sprite_offset = 0,
        _target_sprite_offset = 0,
        _max_sprite_offset = 0,

        _elapsed = 0
    })
end)

--- @brief
function bt.PartySprite:_update_state()
    if self._state == bt.EntityState.ALIVE then
        self._frame:set_color(rt.settings.battle.priority_queue_element.frame_color, rt.settings.battle.priority_queue_element.base_color)
        self._name:set_color(rt.RGBA(1, 1,1, 1))
    elseif self._state == bt.EntityState.KNOCKED_OUT then
        self._frame:set_color(rt.color_lighten(rt.Palette.KNOCKED_OUT, 0.15), rt.color_darken(rt.Palette.KNOCKED_OUT, 0.3))
        self._name:set_color(rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.knocked_out_shape_alpha))
    elseif self._state == bt.EntityState.DEAD then
        self._frame:set_color(rt.settings.battle.priority_queue_element.dead_frame_color, rt.settings.battle.priority_queue_element.dead_base_color)
        self._name:set_color(rt.RGBA(1, 1,1, rt.settings.battle.priority_queue_element.dead_shape_alpha))
    end

    if self._selection_state == bt.SelectionState.SELECTED then
        self._frame:set_color(rt.Palette.SELECTION)
        self._frame:set_gradient_visible(false)
    else
        self._frame:set_gradient_visible(true)
    end

    if self._selection_state == bt.SelectionState.UNSELECTED then
        self:set_opacity(rt.settings.battle.selection.unselected_opacity)
    else
        self:set_opacity(1)
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
    self._consumable_bar:realize()
    self._sprite:realize()
    self._sprite_stencil = rt.Rectangle(0, 0, 1, 1)

    self._health_bar:set_use_percentage(false)
    self._status_bar:set_alignment(rt.Alignment.START)

    self._frame:realize()


    self:reformat()
    self:synchronize(self._entity)
end

--- @override
function bt.PartySprite:update(delta)
    self._elapsed = self._elapsed + delta

    bt.BattleSprite.update(self, delta)

    if self._state == bt.EntityState.KNOCKED_OUT then
        local offset = rt.settings.battle.priority_queue_element.knocked_out_pulse(self._elapsed)
        local color = rt.rgba_to_hsva(rt.Palette.KNOCKED_OUT)
        color.v = clamp(color.v + offset, 0, 1)
        self._frame:set_color(nil, color)
    end

    if self._sprite_visible == true and self._current_sprite_offset > 0 then
        self._current_sprite_offset = self._current_sprite_offset - delta * rt.settings.battle.party_sprite.sprite_reveal_speed
        self._current_sprite_offset = clamp(self._current_sprite_offset, 0, self._max_sprite_offset)
    elseif self._sprite_visible == false and self._current_sprite_offset < self._target_sprite_offset then
        self._current_sprite_offset = self._current_sprite_offset + delta * rt.settings.battle.party_sprite.sprite_reveal_speed
        self._current_sprite_offset = clamp(self._current_sprite_offset, 0, self._max_sprite_offset)
    end
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    local xm, ym = rt.settings.margin_unit, rt.settings.margin_unit
    local frame_thickness = rt.settings.battle.priority_queue_element.frame_thickness
    local frame_outline_thickness = math.max(frame_thickness * 1.1, frame_thickness + 2)
    local total_frame_thickness = frame_thickness + 2 * frame_outline_thickness

    height = height - 0.5 * total_frame_thickness - 1.5 * ym
    local current_y = y + height - ym

    local label_w, label_h = self._name:get_size()
    self._name:set_position(x + 0.5 * width - 0.5 * label_w, current_y - label_h)
    local speed_value_w, speed_value_h = self._speed_value:measure()
    self._speed_value:fit_into(x + width - xm - speed_value_w, current_y - label_h - speed_value_h + 0.5 * speed_value_h + 0.5 * label_h)
    self._status_bar:fit_into(x + xm, current_y - label_h, width - 2 * xm, label_h)
    current_y = current_y - label_h - ym

    local hp_bar_height = rt.settings.battle.health_bar.hp_font:get_size() + ym
    local hp_bar_bounds = rt.AABB(x + xm, current_y - hp_bar_height, width - 2 * xm, hp_bar_height)
    self._health_bar:fit_into(hp_bar_bounds)
    current_y = current_y - hp_bar_bounds.height - ym

    local backdrop_bounds = rt.AABB(x, current_y, width, y + height - current_y)
    local frame_aabb = rt.AABB(backdrop_bounds.x, backdrop_bounds.y, backdrop_bounds.width, backdrop_bounds.height)
    self._frame:fit_into(frame_aabb)

    local consumable_aabb = rt.AABB(x + xm, frame_aabb.y - hp_bar_height, frame_aabb.width, hp_bar_height)
    self._consumable_bar:fit_into(consumable_aabb)

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

    self._sprite_stencil:resize(frame_aabb.x, frame_aabb.y, frame_aabb.width, 1000 * frame_aabb.height) -- infinity high

    self._target_sprite_offset = 0
    self._max_sprite_offset = sprite_h
    self._current_sprite_offset = sprite_h

    self._bounds.y = current_y - total_frame_thickness
    self._bounds.height = frame_aabb.height + 2 * total_frame_thickness
    self:_update_state()
end

--- @override
function bt.PartySprite:draw()
    if not self._is_realized == true then return false end
    if self._is_visible == false then return end

    local stencil_value = meta.hash(self) % 255
    rt.graphics.stencil(stencil_value, self._sprite_stencil)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.NOT_EQUAL, stencil_value)
    rt.graphics.translate(0, self._current_sprite_offset)
    self._sprite:draw()
    rt.graphics.translate(0, -1 * self._current_sprite_offset)
    rt.graphics.stencil()
    rt.graphics.set_stencil_test()

    self._frame:draw()

    self._health_bar:draw()
    self._name:draw()
    self._status_bar:draw()
    self._consumable_bar:draw()
    self._speed_value:draw()
end

--- @brief
function bt.PartySprite:set_selection_state(state)
    self._selection_state = state
    self:_update_state()
end

--[[
--- @brief
function bt.PartySprite:get_bounds()
    return rt.aabb_copy(self._frame:get_bounds())
end
]]--

--- @brief
function bt.PartySprite:set_opacity(alpha)
    self._opacity = alpha

    for object in range(
        self._health_bar,
        self._name,
        self._speed_value,
        self._status_bar,
        self._frame,
        self._sprite
    ) do
        object:set_opacity(alpha)
    end
end

--- @brief
function bt.PartySprite:set_state(state)
    bt.BattleSprite.set_state(self, state)
    self:_update_state()
end

--- @brief
function bt.PartySprite:set_sprite_visible(b)
    self._sprite_visible = b
    if b == true then
        self._target_sprite_offset = 0
    else
        self._target_sprite_offset = self._max_sprite_offset
    end
end

--- @brief
function bt.PartySprite:get_sprite_visible()
    return self._sprite_visible
end

bt.PartySpriteSpriteState = meta.new_enum({
    IDLE = "idle_front",
    IDLE_BACK = "idle_back",
    THINKING = "thinking",
    FLINCHING = "flinching"
})

--- @brief
function  bt.PartySprite:set_sprite_state(state)
    meta.assert_enum(state, bt.PartySpriteSpriteState)
    self._sprite:set_animation(state)
end
