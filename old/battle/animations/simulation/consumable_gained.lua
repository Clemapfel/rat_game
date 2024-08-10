rt.settings.battle.animations.consumable_gained = {
    collider_mass = 100,
    collider_restitution = 0.7,
    world_gravity = 5000,
    duration = 1.5
}

--- @class bt.Animation.CONSUMABLE_GAINED
bt.Animation.CONSUMABLE_GAINED = meta.new_type("CONSUMABLE_GAINED", rt.QueueableAnimation, function(target, consumable)
    return meta.new(bt.Animation.CONSUMABLE_GAINED, {
        _target = target,
        _consumable = consumable,

        _sprite = {}, -- rt.Sprite
        _sprite_pos_x = 0,
        _sprite_pos_y = 0,
        _sprite_path = {}, -- rt.Spline
        _elapsed = 0,
    })
end)

--- @override
function bt.Animation.CONSUMABLE_GAINED:start()
    local sprite_id, sprite_index = self._consumable:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()
    self._sprite:set_animation(sprite_index)
    local sprite_w, sprite_h = self._sprite:get_resolution()
    sprite_w = sprite_w * 3
    sprite_h = sprite_h * 3

    local target_bounds = self._target:get_bounds()
    self._sprite:fit_into(
        0, 0,
        sprite_w,
        sprite_h
    )

    self._sprite_path = rt.Spline({
        target_bounds.x + 0.5 * target_bounds.width - 0.5 * sprite_w, target_bounds.y + 0.75 * target_bounds.height - 0.5 * sprite_h,
        target_bounds.x + 0.5 * target_bounds.width - 0.5 * sprite_w, target_bounds.y + 0.0 * target_bounds.height - 0.5 * sprite_h,
    })
    self._sprite_pos_x, self._sprite_pos_y = self._sprite_path:at(0)
end

--- @override
function bt.Animation.CONSUMABLE_GAINED:update(delta)
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / rt.settings.battle.animations.consumable_gained.duration
    self._sprite_pos_x, self._sprite_pos_y = self._sprite_path:at(rt.sqrt_acceleration(fraction) * 0.5)

    local fade_in_cutoff = 0.2
    if fraction < fade_in_cutoff then
        self._sprite:set_opacity(fraction / fade_in_cutoff)
    end

    local fade_out_cutoff = 0.9
    if fraction > fade_out_cutoff then
        self._sprite:set_opacity(1 - ((fraction - fade_out_cutoff) / (1 - fade_out_cutoff)))
    end

    return fraction < 1
end

--- @override
function bt.Animation.CONSUMABLE_GAINED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.CONSUMABLE_GAINED:draw()

    rt.graphics.push()
    rt.graphics.translate(self._sprite_pos_x, self._sprite_pos_y)
    self._sprite:draw()
    rt.graphics.pop()
end