if mn.Animation == nil then mn.Animation = {} end

rt.settings.menu.animation.object_moved = {
    speed = 1000, -- px / s
}

--- @class mn.ObjectMovedAnimation
mn.Animation.OBJECT_MOVED = meta.new_type("OBJECT_MOVED", rt.QueueableAnimation, function(object, from, to)
    meta.assert_aabb(from)
    meta.assert_aabb(to)

    return meta.new(mn.Animation.OBJECT_MOVED, {
        _object = object,
        _sprite = rt.Sprite(object:get_sprite_id()),
        _from_aabb = from,
        _to_aabb = to,
        _elapsed = 0,
        _sprite_offset_x = 0,
        _sprite_offset_y = 0,
        _sprite_size_offset_x = 0,
        _sprite_size_offset_y = 0
    })
end)

--- @override
function mn.Animation.OBJECT_MOVED:start()
    self._sprite:realize()
    local sprite_w, sprite_h = self._sprite:get_resolution()
    sprite_w = sprite_w * 2
    sprite_h = sprite_h * 2
    self._sprite:set_minimum_size(sprite_w, sprite_h)
    self._sprite:fit_into(0, 0, sprite_w, sprite_h)

    self._sprite_size_offset_x = -sprite_w * 0.5
    self._sprite_size_offset_y = -sprite_h * 0.5

    self._elapsed = 0
end

--- @override
function mn.Animation.OBJECT_MOVED:update(delta)
    self._elapsed = self._elapsed + delta
    local from_x, from_y = self._from_aabb.x + 0.5 * self._from_aabb.width, self._from_aabb.y + 0.5 * self._from_aabb.height
    local to_x, to_y = self._to_aabb.x + 0.5 * self._to_aabb.width, self._to_aabb.y + 0.5 * self._to_aabb.height

    local speed = rt.settings.menu.animation.object_moved.speed

    local length = rt.distance(from_x, from_y, to_x, to_y)
    local duration = (length / speed)
    local fraction = clamp(self._elapsed / duration, 0, 1)

    local angle = rt.angle(to_x - from_x, to_y - from_y)
    local distance = rt.sigmoid(fraction) * length
    self._sprite_offset_x, self._sprite_offset_y = rt.translate_point_by_angle(from_x, from_y, distance, angle)

    return fraction < 1
end

--- @override
function mn.Animation.OBJECT_MOVED:draw()
    local offset_x, offset_y = self._sprite_offset_x + self._sprite_size_offset_x, self._sprite_offset_y + self._sprite_size_offset_y
    rt.graphics.translate(offset_x, offset_y)
    self._sprite:draw()
    rt.graphics.translate(-offset_x, -offset_y)
end

--- @override
function mn.Animation.OBJECT_MOVED:finish()
end