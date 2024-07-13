if mn.Animation == nil then mn.Animation = {} end

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

    local speed = 2000 -- px / s
    local hold_duration = 0.1

    local length = rt.distance(from_x, from_y, to_x, to_y)
    local fraction = self._elapsed / ((length / speed) + (1 + 2 * hold_duration))
    if fraction < hold_duration then
        self._sprite:set_opacity(fraction / hold_duration)
        self._sprite_offset_x, self._sprite_offset_y = from_x, from_y
    elseif  fraction > 1 - hold_duration then
        self._sprite:set_opacity((1 - fraction) / hold_duration)
        self._sprite_offset_x, self._sprite_offset_y = to_x, to_y
    else
        self._sprite:set_opacity(1)
        local angle = rt.angle(to_x - from_x, to_y - from_y)
        local distance = rt.sigmoid(fraction / (1 - 2 * hold_duration), 18) * length
        self._sprite_offset_x, self._sprite_offset_y = rt.translate_point_by_angle(from_x, from_y, distance, angle)
    end

    return fraction < 1
end

--- @override
function mn.Animation.OBJECT_MOVED:draw()
    local offset_x, offset_y = self._sprite_offset_x + self._sprite_size_offset_x, self._sprite_offset_y + self._sprite_size_offset_y
    rt.graphics.translate(offset_x, offset_y)
    self._sprite:draw()
    rt.graphics.translate(-offset_x, -offset_y)

    local from_x, from_y = self._from_aabb.x + 0.5 * self._from_aabb.width, self._from_aabb.y + 0.5 * self._from_aabb.height
    local to_x, to_y = self._to_aabb.x + 0.5 * self._to_aabb.width, self._to_aabb.y + 0.5 * self._to_aabb.height
    love.graphics.points(
        from_x, from_y,
        to_x, to_y
    )
end

--- @override
function mn.Animation.OBJECT_MOVED:finish()
end