rt.settings.battle.animations.consumable_lost = {
    collider_mass = 100,
    collider_restitution = 0.7,
    world_gravity = 5000,
    duration = 1.5
}

--- @class bt.Animation.CONSUMABLE_LOST
bt.Animation.CONSUMABLE_LOST = meta.new_type("CONSUMABLE_LOST", rt.QueueableAnimation, function(target, consumable)
    return meta.new(bt.Animation.CONSUMABLE_LOST, {
        _target = target,
        _consumable = consumable,

        _sprite = {}, -- rt.Sprite

        _world = {},    -- rt.PhysicsWorld
        _collider = {}, -- rt.CircleCollider
        _floor = {},    -- rt.LineCollider

        _elapsed = 0,
    })
end)

--- @override
function bt.Animation.CONSUMABLE_LOST:start()
    local sprite_id, sprite_index = self._consumable:get_sprite_id()
    self._sprite = rt.Sprite(sprite_id)
    self._sprite:realize()
    self._sprite:set_animation(sprite_index)
    local sprite_w, sprite_h = self._sprite:get_resolution()
    sprite_w = sprite_w * 2
    sprite_h = sprite_h * 2

    local target_bounds = self._target:get_bounds()
    self._sprite:fit_into(
        -0.5 * sprite_w, -0.5 * sprite_h,
        sprite_w,
        sprite_h
    )

    local sprite_radius = self._sprite:measure()
    local sprite_bounds = self._sprite:get_bounds()

    self._world = rt.PhysicsWorld(0, rt.settings.battle.animations.consumable_lost.world_gravity)
    self._collider = rt.CircleCollider(self._world, rt.ColliderType.DYNAMIC,
        target_bounds.x + target_bounds.width * 0.5, target_bounds.y + target_bounds.height * 0.5,
        math.min(sprite_bounds.width / 2, sprite_bounds.height / 2)
    )

    self._floor = rt.LineCollider(self._world, rt.ColliderType.STATIC,
        0, target_bounds.y + target_bounds.height,
        rt.graphics.get_width(), target_bounds.y + target_bounds.height
    )

    self._collider:set_mass(rt.settings.battle.animations.consumable_lost.collider_mass)
    self._collider:set_restitution(rt.settings.battle.animations.consumable_lost.collider_restitution)
    self._collider:set_rotation_is_fixed(false)
    self._collider:apply_torque(100)
    self._collider:apply_linear_impulse(10000, 0)
end

--- @override
function bt.Animation.CONSUMABLE_LOST:update(delta)
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / rt.settings.battle.animations.consumable_lost.duration

    self._world:update(delta)
    local cutoff = 0.9
    if fraction > cutoff then
        self._sprite:set_opacity(1 - ((fraction - cutoff) / (1 - cutoff)))
    end

    return fraction < 1
end

--- @override
function bt.Animation.CONSUMABLE_LOST:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.CONSUMABLE_LOST:draw()
    rt.graphics.push()
    rt.graphics.origin()
    rt.graphics.translate(self._collider:get_position())
    rt.graphics.rotate(self._collider:get_angle())

    self._sprite:draw()
    rt.graphics.pop()
end