--- @class bt.EnemySprite
bt.EnemySprite = meta.new_type("EnemySprite", function(entity)
    assert(meta.isa(entity, bt.Entity) and entity.is_enemy == true)
    local out = meta.new(bt.EnemySprite, {
        _sprite = rt.ImageDisplay("assets/favicon.png"),
        _shader = rt.Shader("assets/shaders/enemy_sprite.glsl"),
        _elapsed = 0
    }, rt.Drawable, rt.Widget, rt.Animation)

    out._shader:send("_pulse_active", true) -- todo
    out._shader:send("_pulse_frequency", 0.75)
    out._shader:send("_pulse_color", {1, 0, 1, 1})

    out._sprite:set_minimum_size(0, 0)
    out:set_is_animated(true)
    return out
end)

--- @overload
function bt.EnemySprite:size_allocate(x, y, width, height)
    println(width, " x ", height)
    self._sprite:fit_into(x, y, width, height)
end

--- @overload
function bt.EnemySprite:draw()
    self._shader:bind()
    self._sprite:draw()
    self._shader:unbind()
end

--- @overload
function bt.EnemySprite:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("_time", self._elapsed)
end

--- @overload
function bt.EnemySprite:realize()
    self._sprite:realize()
    rt.Widget.realize(self)
end