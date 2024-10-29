rt.settings.battle.animation.consumable_consumed = {
    duration = 3
}

--- @class bt.Animation.CONSUMABLE_CONSUMED
--- @param scene bt.BattleScene
--- @param consumable bt.Consumable
--- @param sprite bt.EntitySprite
bt.Animation.CONSUMABLE_CONSUMED = meta.new_type("CONSUMABLE_CONSUMED", rt.Animation, function(scene, consumable, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(consumable, bt.Consumable)
    meta.assert_isa(sprite, bt.EntitySprite)
    local duration = rt.settings.battle.animation.consumable_consumed.duration
    local n_bites = 5
    return meta.new(bt.Animation.CONSUMABLE_CONSUMED, {
        _scene = scene,
        _consumable = consumable,
        _target = sprite,

        _sprite = nil, -- rt.Sprite
        _sprite_x = 0,
        _sprite_y = 0,
        _sprite_scale = 1,
        _scale_animation = rt.TimedAnimation(duration,
            2, 1, rt.InterpolationFunctions.STEPS, n_bites
        ),
        _target_animation = rt.TimedAnimation(duration,
            0.8, 1, rt.InterpolationFunctions.TRIANGLE_WAVE, n_bites
        ),
        _target_scale = 1,

        _circles = {},
        _generate_circle = nil, -- Function
        _n_bites = n_bites * 2,
        _duration = duration,
        _bite_elapsed = 0
    })
end, {
    consumable_to_sprite = {}
})

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:start()
    local sprite = self.consumable_to_sprite[self._consumable]
    local sprite_w, sprite_h
    if sprite == nil then
        sprite = rt.Sprite(self._consumable:get_sprite_id())
        sprite:realize()
        sprite_w, sprite_h = sprite:measure()
        sprite:fit_into(-0.5 * sprite_w, -0.5 * sprite_h)
    end

    self._sprite = sprite
    local x, y = self._target:get_position()
    local w, h = self._target:get_snapshot():get_size()
    self._sprite_x, self._sprite_y = x + 0.5 * w, y + 0.5 * h
    self._target_aabb = rt.AABB(x, y, w, h)
    self._circle_aabb = rt.AABB(x, y, w, h)
    self._circle_aabb.x, self._circle_aabb.y = 0.1 * math.min(w, h), 0.4 * math.min(w, h)
    self._generate_circle = function()
        local x, y, r
        local offset = 0.2
        local restrict_x_or_y = rt.random.toss_coin()

        if rt.random.toss_coin() then
            x = rt.random.number(0, w)
            if rt.random.toss_coin() then
                y = rt.random.number(0, offset * h)
            else
                y = rt.random.number((1 - offset) * h, h)
            end
        else
            y = rt.random.number(0, h)
            if rt.random.toss_coin() then
                x = rt.random.number(0, offset * w)
            else
                x = rt.random.number((1 - offset) * w, w)
            end
        end

        local which = math.min(w, h)
        return {x - 0.5 * w, y - 0.5 * h, offset * 2 * math.min(w, h)}
    end

    self._target:set_is_visible(false)
end

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:finish()
    self._target:set_is_visible(true)
end

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:update(delta)
    for animation in range(self._scale_animation, self._target_animation) do
        animation:update(delta)
    end

    self._bite_elapsed = self._bite_elapsed + delta
    local step = self._duration / self._n_bites
    while self._bite_elapsed > step do
        local x, y, w, h = rt.aabb_unpack(self._circle_aabb)
        table.insert(self._circles, self._generate_circle())
        self._bite_elapsed = self._bite_elapsed - step
    end

    self._sprite_scale = self._scale_animation:get_value()
    self._target_scale = self._target_animation:get_value()
    return self._scale_animation:get_is_done()
end

--- @override
function bt.Animation.CONSUMABLE_CONSUMED:draw()

    love.graphics.push()
    local x, y, w, h = rt.aabb_unpack(self._target_aabb)
    x = x + 0.5 * w
    y = y + 0.5 * h
    love.graphics.translate(x, y)
    love.graphics.scale(1, self._target_scale)
    love.graphics.translate(-x, -y)
    love.graphics.translate(0, 0.5 * (1 - self._target_scale) * h)
    self._target:draw_snapshot()
    love.graphics.pop()

    love.graphics.push()
    love.graphics.translate(self._sprite_x, self._sprite_y)
    love.graphics.scale(self._sprite_scale)

    local stencil_value = meta.hash(self) % 254 + 1
    rt.graphics.stencil(stencil_value, function()
        for circle in values(self._circles) do
            love.graphics.circle("fill", table.unpack(circle))
        end
    end)
    rt.graphics.set_stencil_test(rt.StencilCompareMode.NOT_EQUAL, stencil_value)
    self._sprite:draw()
    rt.graphics.set_stencil_test()

    --[[
    for circle in values(self._circles) do
        love.graphics.circle("fill", table.unpack(circle))
    end
    ]]--

    love.graphics.pop()
end