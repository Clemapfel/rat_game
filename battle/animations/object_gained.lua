rt.settings.battle.animation.object_gained = {
    duration = 2
}

--- @class bt.Animation.OBJECT_GAINED
--- @param scene bt.BattleScene
--- @param object
--- @param sprite bt.EntitySprite
bt.Animation.OBJECT_GAINED = meta.new_type("OBJECT_GAINED", rt.Animation, function(scene, object, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EntitySprite)

    local duration = rt.settings.battle.animation.object_gained.duration
    return meta.new(bt.Animation.OBJECT_GAINED, {
        _scene = scene,
        _object = object,
        _target = sprite,

        _sprite = nil, -- rt.Sprite,
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_opacity = 0,
        _sprite_path = nil, -- rt.Spline

        _ray = rt.VertexRectangle(0, 0, 1, 1),
        _ray_aabb = rt.AABB(0, 0, 1, 1),

        _path_animation = rt.TimedAnimation(duration,
            0, 1, rt.InterpolationFunctions.EXPONENTIAL_ACCELERATION
        ),

        _opacity_animation = rt.TimedAnimation(0.5 * duration - 0.075,
            1, 0, rt.InterpolationFunctions.GAUSSIAN_HIGHPASS, 10
        ),

        _scale_animation = rt.TimedAnimation(0.5 * duration,
            1, 5, rt.InterpolationFunctions.GAUSSIAN_HIGHPASS
        ),

        _position_animation = rt.TimedAnimation
    })
end, {
    object_to_sprite = {}
})

--- @override
function bt.Animation.OBJECT_GAINED:start()
    local sprite = self.object_to_sprite[self._object]
    local sprite_w, sprite_h
    if sprite == nil then
        sprite = rt.Sprite(self._object:get_sprite_id())
        sprite:realize()
        sprite_w, sprite_h = sprite:measure()
        sprite:fit_into(-0.5 * sprite_w, -0.5 * sprite_h)
    end

    self._sprite = sprite
    local x, y = self._target:get_position()
    local w, h = self._target:get_snapshot():get_size()

    local bottom_y = y + h - 0.5 * sprite_h
    self._sprite_path = rt.Spline({
        x + 0.5 * w, 0 - sprite_h,
        x + 0.5 * w, bottom_y
    })

    self._ray_aabb.x = x + 0.5 * w
    self._ray_aabb.y = 0
    self._ray_aabb.width = sprite_w
    self._ray_aabb.height = bottom_y + 0.5 * sprite_h
end

--- @override
function bt.Animation.OBJECT_GAINED:update(delta)
    if self._path_animation:update(delta) then
        self._opacity_animation:update(delta)
        self._scale_animation:update(delta)
    end

    self._sprite_opacity = self._opacity_animation:get_value()
    self._sprite_scale = self._scale_animation:get_value()
    self._sprite_x, self._sprite_y = self._sprite_path:at(self._path_animation:get_value())

    local ray_fraction = self._path_animation:get_value()
    local x, y, w, h = rt.aabb_unpack(self._ray_aabb)
    w = w * ray_fraction
    local center_x = x
    local top_r, bottom_r = 0.2 * w, 0.5 * w
    self._ray:reformat(
        center_x + 0.5 * top_r, y,
        center_x - 0.5 * top_r, y,
        center_x - 0.5 * bottom_r, y + h,
        center_x + 0.5 * bottom_r, y + h
    )

    local opacity_factor = clamp(2 * self._sprite_opacity, 0, 1)
    local up_opacity, down_opacity = 0.3 * opacity_factor, 0.4 * opacity_factor
    self._ray:set_vertex_color(1, rt.RGBA(1, 1, 1, up_opacity))
    self._ray:set_vertex_color(2, rt.RGBA(1, 1, 1, up_opacity))
    self._ray:set_vertex_color(3, rt.RGBA(1, 1, 1, down_opacity))
    self._ray:set_vertex_color(4, rt.RGBA(1, 1, 1, down_opacity))

    return self._opacity_animation:get_is_done() and self._path_animation:get_is_done()
end

--- @override
function bt.Animation.OBJECT_GAINED:draw()
    self._sprite:set_opacity(self._sprite_opacity) -- in draw because of cached sprites
    self._ray:draw()

    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    love.graphics.scale(self._sprite_scale)
    self._sprite:draw()
    love.graphics.pop()
end