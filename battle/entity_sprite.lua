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
    _status_consumable_selection_frame = rt.Frame(),
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

    _blink_animation = rt.TimedAnimation(10, 0, 0.3, rt.InterpolationFunctions.SINE_WAVE),
    _is_blinking = false,
    _blink_color = rt.Palette.WHITE,
    _blink_opacity = 0,
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
    self._status_consumable_selection_frame:realize()
    self._status_consumable_selection_frame:set_selection_state(rt.SelectionState.ACTIVE)
    self._status_consumable_selection_frame:set_base_color(rt.RGBA(0, 0, 0, 0))

    self._blink_animation:set_should_loop(true)

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

    if self._is_blinking then
        self._blink_animation:update(delta)
        self._blink_opacity = self._blink_animation:get_value()
    end

    self._snapshot:bind()
    love.graphics.clear()
    self._sprite:draw()

    if self._is_blinking then
        local strength = self._blink_opacity
        love.graphics.setColor(
            strength * self._blink_color.r,
            strength * self._blink_color.g,
            strength * self._blink_color.b,
            1
        )

        love.graphics.setBlendState(
            rt.BlendOperation.ADD,  -- rgb
            rt.BlendOperation.ADD,  -- alpha
            rt.BlendFactor.ONE,  -- source rgb
            rt.BlendFactor.ZERO, -- source alpha
            rt.BlendFactor.ONE, -- dest rgb
            rt.BlendFactor.ONE  -- dest alpha
        )
        local sprite_bounds = self._sprite:get_bounds()
        love.graphics.rectangle("fill", 0, 0, sprite_bounds.width, sprite_bounds.height)
        rt.graphics.set_blend_mode()
    end

    self._snapshot:unbind()
end

--- @brief
function bt.EntitySprite:_draw_super()
    if self._is_stunned then
        self._stunned_animation:draw()
    end
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
    meta.assert_enum_value(state, rt.SelectionState)
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
            self:set_consumable_n_uses_left(slot_i, n_uses_left)
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

--- @brief
function bt.EntitySprite:get_sprite_selection_node()
    local x, y = self:get_position()
    local w, h = self:measure()
    local out = rt.SelectionGraphNode(rt.AABB(x, y, w, h))
    assert(meta.isa(self._entity, bt.Entity), "In bt.EntitySprite:get_sprite_selection_node: _entity is not set")
    out.object = self._entity
    return out
end

--- @brief
function bt.EntitySprite:get_status_consumable_selection_nodes()
    local nodes = {}
    local n = 0
    for status, sprite in pairs(self._status_to_sprite) do
        local bounds = self._status_consumable_bar:get_widget_bounds(sprite)
        bounds.x = bounds.x
        bounds.y = bounds.y
        local node = rt.SelectionGraphNode(bounds)
        node.object = status
        table.insert(nodes, node)
        n = n + 1
    end

    for slot_i, sprite in pairs(self._consumable_slot_to_sprite) do
        local consumable = self._consumable_slot_to_consumable[slot_i]
        local bounds = self._status_consumable_bar:get_widget_bounds(sprite)
        local padding = rt.settings.frame.thickness * 2
        bounds.x = bounds.x - padding
        bounds.y = bounds.y - padding
        bounds.width = bounds.width + 2 * padding
        bounds.height = bounds.height + 2 * padding
        local node = rt.SelectionGraphNode(bounds)
        node.object = self._consumable_slot_to_consumable[slot_i]
        table.insert(nodes, node)
        n = n + 1
    end

    table.sort(nodes, function(a, b)
        return a:get_bounds().x < b:get_bounds().x
    end)

    return nodes
end

--- @brief
function bt.EntitySprite:get_selection_nodes()
    local nodes = self:get_status_consumable_selection_nodes()
    table.insert(nodes, 1, self:get_sprite_selection_node())
    return nodes
end

--- @brief
function bt.EntitySprite:set_is_blinking(b)
    if b ~= self._is_blinking then self._blink_animation:reset() end
    self._is_blinking = b
end

--- @brief
function bt.EntitySprite:get_is_blinking()
    return self._is_blinking
end

--- @brief
function bt.EntitySprite:set_blink_color(color)
    self._blink_color = color
end

--- @brief
function bt.EntitySprite:get_blink_color()
    return self._blink_color
end
