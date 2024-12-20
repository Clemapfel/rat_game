rt.settings.battle.entity_sprite = {
    inactive_selection_opacity = 0.5,
    bar_height = 2.5 * rt.settings.margin_unit
}

bt.EntitySpriteState = meta.new_enum("EntitySpriteState", {
    IDLE = "idle",
    KNOCKED_OUT = "knocked_out",
    DEAD = "dead",
    FLINCHING = "flinching",
    ACTING = "acting"
})

--- @class bt.EntitySprite
bt.EntitySprite = meta.new_abstract_type("EntitySprite", rt.Widget, {
    _health_bar = nil, -- bt.Healthbar
    _speed_value = nil, -- bt.SpeedValue
    _status_consumable_bar = nil, -- bt.OrderedBox
    _sprite = nil, -- rt.Sprite

    _ui_visible = true,
    _snapshot_visible = true,

    _selection_state = rt.SelectionState.INACTIVE,

    _snapshot = nil, -- rt.RenderTexture
    _snapshot_position_x = 0,
    _snapshot_position_y = 0,

    _stunned_animation = nil, -- bt.StunnedParticleAnimation
    _is_stunned = false,

    _status_to_sprite = {}, -- Table<bt.StatusConfig, rt.Sprite>
    _consumable_slot_to_sprite = {}, -- Table<rt.Sprite>
    _consumable_slot_to_consumable = {}, -- Table<bt.Consumable>
})

--- @brief
function bt.EntitySprite:_realize_super(sprite_id)
    meta.assert_string(sprite_id)

    self._health_bar = bt.HealthBar(0, 0, 0)
    self._speed_value = bt.SpeedValue(0)
    self._status_consumable_bar = bt.OrderedBox()
    self._sprite = rt.Sprite(sprite_id)
    self._stunned_animation = bt.StunnedParticleAnimation()

    for widget in range(
        self._health_bar,
        self._speed_value,
        self._status_consumable_bar,
        self._sprite,
        self._stunned_animation
    ) do
        widget:realize()
    end

    local sprite_w, sprite_h = self._sprite:measure()
    self._sprite:fit_into(0, 0, sprite_w, sprite_h)
    self._snapshot = rt.RenderTexture(sprite_w, sprite_h)

    self._status_to_sprite = {}
    self._consumable_slot_to_sprite = {}
    self._consumable_slot_to_consumable = {}

    if not self._sprite:has_animation(bt.EntitySpriteState.IDLE) then
        rt.warning("In bt.EntitySprite._initialize_super: sprite `" .. sprite_id .. "` does not have animation with id \"idle\"")
    end
end

--- @brief
function bt.EntitySprite:_update_super(delta)
    for widget in range(
        self._health_bar,
        self._speed_value,
        self._status_consumable_bar,
        self._sprite
    ) do
        widget:update(delta)
    end

    if self._is_stunned then
        self._stunned_animation:update(delta)
    end

    self._snapshot:bind()
    love.graphics.clear()
    self._sprite:draw()
    self._snapshot:unbind()
end

--- @brief
function bt.EntitySprite:draw_snapshot(x, y)
    if x == nil then x = 0 end
    if y == nil then y = 0 end

    if self._selection_state == rt.SelectionState.UNSELECTED then
        love.graphics.setColor(1, 1, 1, rt.settings.battle.entity_sprite.inactive_selection_opacity)
    else
        love.graphics.setColor(1, 1, 1, 1)
    end
    love.graphics.draw(self._snapshot._native, self._snapshot_position_x + x, self._snapshot_position_y + y)
end

--- @brief
function bt.EntitySprite:set_sprite_state(state)
    meta.assert_enum(state, bt.EntitySpriteState)

    if self._sprite:has_animation(state) then
        self._sprite:set_animation(state)
    else
        rt.warning("In bt.EntitySprite.set_sprite_state: sprite `" .. self._sprite:get_id() .. "` does not have animation with id \"idle\"")
        self._sprite:set_animation(bt.EntitySpriteState.IDLE)
    end
end

--- @brief
function bt.EntitySprite:set_selection_state(state)
    meta.assert_enum(state, rt.SelectionState)
    self._selection_state = state
end

--- @brief
function bt.EntitySprite:set_is_stunned(b)
    meta.assert_boolean(b)
    self._is_stunned = b
end

--- @brief
function bt.EntitySprite:set_is_visible(b)
    meta.assert_boolean(b)
    self._ui_visible = b
    self._snapshot_visible = b
end

--- @brief
function bt.EntitySprite:set_ui_visible(b)
    meta.assert_boolean(b)
    self._ui_visible = b
end

--- @brief
function bt.EntitySprite:set_snapshot_visible(b)
    meta.assert_boolean(b)
    self._snapshot_visible = b
end

--- @brief
function bt.EntitySprite:set_animation_active(b)
    self._animation_active = b
end

--- @brief
function bt.EntitySprite:set_hp(hp_current, hp_base)
    self._health_bar:set_value(hp_current, hp_base)
end

--- @brief
function bt.EntitySprite:set_speed(value)
    self._speed_value:set_value(value)
end

--- @brief
function bt.EntitySprite:add_status(status, n_turns_left)
    meta.assert_isa(status, bt.StatusConfig)
    if n_turns_left == nil then n_turns_left = status:get_max_duration() end
    meta.assert_number(n_turns_left)

    if self._status_to_sprite[status] ~= nil then
        self:set_status_n_turns_left(status, n_turns_left)
        return
    end

    local sprite = rt.Sprite(status:get_sprite_id())
    if n_turns_left ~= POSITIVE_INFINITY then
        sprite:set_bottom_right_child("<o>" .. n_turns_left .. "</o>")
    end
    sprite:set_minimum_size(sprite:get_resolution())

    self._status_to_sprite[status] = sprite
    self._status_consumable_bar:add(sprite, bt.OrderedBoxPositioning.LEFT)
end

--- @brief
function bt.EntitySprite:remove_status(status)
    meta.assert_isa(status, bt.StatusConfig)

    local sprite = self._status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt." .. meta.typeof(self) .. ".remove_status: status `" .. status:get_id() .. "` is not present")
        return
    end

    self._status_to_sprite[status] = nil
    self._status_consumable_bar:remove(sprite)
end

--- @brief
function bt.EntitySprite:set_status_n_turns_left(status, n_turns_left)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_number(n_turns_left)

    local sprite = self._status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt." .. meta.typeof(self) .. ".set_status_n_turns_left: status is not yet present")
        return
    end

    if n_turns_left == POSITIVE_INFINITY then
        sprite:set_bottom_right_child("")
    else
        sprite:set_bottom_right_child("<o>" .. n_turns_left .. "</o>")
    end
end

--- @brief
function bt.EntitySprite:activate_status(status, on_done_notify_f)
    meta.assert_isa(status, bt.StatusConfig)

    local sprite = self._status_to_sprite[status]
    if sprite == nil then
        rt.error("In bt." .. meta.typeof(self) .. ".activate_status: status is not yet present")
        return
    end

    self._status_consumable_bar:activate(sprite, on_done_notify_f)
end

--- @brief
function bt.EntitySprite:add_consumable(slot_i, consumable, n_uses_left)
    meta.assert_number(slot_i)
    meta.assert_isa(consumable, bt.ConsumableConfig)
    meta.assert_number(n_uses_left)

    if self._consumable_slot_to_sprite[slot_i] ~= nil then
        if self._consumable_slot_to_consumable[slot_i] == consumable then
            self:set_consumable_n_uses_left(slot_i, consumable, n_uses_left)
            return
        end
        -- else replace
    end

    local sprite = rt.Sprite(consumable:get_sprite_id())
    if n_uses_left ~= POSITIVE_INFINITY then
        sprite:set_bottom_right_child("<o>" .. n_uses_left .. "</o>")
    end
    sprite:set_minimum_size(sprite:get_resolution())

    self._status_consumable_bar:add(sprite, bt.OrderedBoxPositioning.RIGHT)
    self._consumable_slot_to_sprite[slot_i] = sprite
    self._consumable_slot_to_consumable[slot_i] = consumable
end

--- @brief
function bt.EntitySprite:remove_consumable(slot_i)
    meta.assert_number(slot_i)
    local sprite = self._consumable_slot_to_sprite[slot_i]
    if sprite == nil then
        rt.error("In bt." .. meta.typeof(self) .. ".remove_consumable: no consumable at slot `" .. slot_i .. "` present")
        return
    end

    self._consumable_slot_to_sprite[slot_i] = nil
    self._consumable_slot_to_consumable[slot_i] = nil
    self._status_consumable_bar:remove(sprite)
end

--- @brief
function bt.EntitySprite:set_consumable_n_uses_left(slot_i, n_uses_left)
    meta.assert_number(slot_i, n_uses_left)

    local sprite = self._consumable_slot_to_sprite[slot_i]
    if sprite == nil then
        rt.error("In bt." .. meta.typeof(self) .. ".set_consumable_n_uses_left: no consumable at slot `" .. slot_i .. "` present")
        return
    end

    if n_uses_left == POSITIVE_INFINITY then
        sprite:set_bottom_right_child("")
    else
        sprite:set_bottom_right_child("<o>" .. n_uses_left .. "</o>")
    end
end

--- @brief
function bt.EntitySprite:activate_consumable(slot_i, on_done_notify_f)
    meta.assert_number(slot_i)

    local sprite = self._consumable_slot_to_sprite[slot_i]
    if sprite == nil then
        rt.error("In bt." .. meta.typeof(self) .. ".activate_consumable: no consumable at slot `" .. slot_i .. "` present")
        return
    end

    self._status_consumable_bar:activate(sprite, on_done_notify_f)
end

--- @brief
function bt.EntitySprite:skip()
    for widget in range(
        self._health_bar,
        self._speed_value,
        self._status_consumable_bar,
        self._sprite
    ) do
        widget:skip()
    end
end

--- @brief
function bt.EntitySprite:get_position()
    return self._snapshot_position_x, self._snapshot_position_y
end