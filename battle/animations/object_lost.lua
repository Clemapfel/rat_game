--- @class bt.Animation.OBJECT_LOST
bt.Animation.OBJECT_LOST = meta.new_type("OBJECT_LOST", rt.Animation, function(scene, object, entity)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    return meta.new(bt.Animation.OBJECT_LOST, {
        _scene = scene,
        _object = object,
        _entity = entity,
        _target = nil,

        _sprite = nil, -- rt.Sprite
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_rotation = 0,
        _sprite_opacity = 0,

        _opacity_animation = rt.TimedAnimation(2,
            1, 0,
            rt.InterpolationFunctions.GAUSSIAN_HIGHPASS
        ),
        _signal_handler = nil, -- signal id

        _ball_body = nil, -- b2.Body
        _floor_body = nil, -- b2.Body
        _ball_shape = nil,  -- b2.Shape
        _floor_shape = nil, -- b2.Shape
})
end, {
    object_to_sprite = {},
    world = b2.World(0, 1000),
})

--- @override
function bt.Animation.OBJECT_LOST:start()
    self._target = self._scene:get_sprite(self._entity)

    local x, y = self._target:get_position()
    local w, h = self._target:measure()

    local ball_r = 20
    local ball_x, ball_y = x + 0.5 * w, y + 0.5 * h
    local floor_x, floor_y = x + 0.5 * w, 0.5 * love.graphics.getHeight()

    self._ball_body = b2.Body(self.world, b2.BodyType.DYNAMIC, ball_x, ball_y)
    self._ball_shape = b2.CircleShape(self._ball_body, b2.Circle(ball_r))
    self._ball_shape:set_restitution(0.6)
    self._ball_shape:set_friction(0.1)
    self._ball_body:set_rotation_fixed(true)

    self._floor_body = b2.Body(self.world, b2.BodyType.STATIC, floor_x, floor_y)
    self._floor_shape = b2.PolygonShape(self._floor_body, b2.Rectangle(2 * love.graphics.getWidth(), 2))

    local magnitude = 50;
    self._ball_body:apply_linear_impulse(rt.translate_point_by_angle(
        0, 0,
        magnitude,
        -math.pi + math.pi / 4
    ))
    self._ball_body:apply_angular_impulse(1)

    local sprite = self.object_to_sprite[self._object]
    local sprite_w, sprite_h
    if sprite == nil then
        sprite = rt.Sprite(self._object:get_sprite_id())
        sprite:realize()
        sprite_w, sprite_h = sprite:measure()
        sprite:fit_into(-0.5 * sprite_w, -0.5 * sprite_h)
    end

    self._sprite = sprite
    self._signal_handler = self._scene:signal_connect("update", function(scene)
        self.world.updated_this_frame = false
    end)
end

--- @override
function bt.Animation.OBJECT_LOST:finish()
    self._scene:signal_disconnect("update", self._signal_handler)
end

--- @override
function bt.Animation.OBJECT_LOST:update(delta)
    self._opacity_animation:update(delta)
    if self.world.updated_this_frame ~= true then
        self.world:step(delta)
        self.world.updated_this_frame = true
    end

    self._sprite_x, self._sprite_y = self._ball_body:get_centroid()
    self._sprite_rotation = self._ball_body:get_angle()
    self._sprite_opacity = self._opacity_animation:get_value()

    return self._opacity_animation:get_is_done() and select(2, self._ball_body:get_linear_velocity()) < 10e-3
end

--- @override
function bt.Animation.OBJECT_LOST:draw()
    self._sprite:set_opacity(self._sprite_opacity) -- in draw because of cached sprites

    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    love.graphics.rotate(2 * self._sprite_rotation)
    self._sprite:draw()
    love.graphics.pop()
end