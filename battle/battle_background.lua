rt.settings.battle_background.dampening = 1 -- in [0, 1], where 1 = no dampening

--- @class bt.BattleBackground
bt.BattleBackground = meta.new_type("BattleBackground", function(id)
    local out = meta.new(bt.BattleBackground, {
        _id = id,
        _shader = rt.Shader("assets/shaders/" .. id .. ".glsl"),
        _elapsed = 0,
        _vertex_shape = rt.VertexRectangle(0, 0, 1, 1),
        _area = rt.AABB(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget, rt.Animation)
    out:set_is_animated(true)
    return out
end)

--- @overload rt.Drawable.draw
function bt.BattleBackground:draw()
    love.graphics.push()
    love.graphics.reset()
    self._shader:bind()
    self._vertex_shape:draw()
    self._shader:unbind()

    love.graphics.setBlendMode("multiply", "premultiplied")
    local dampening = rt.settings.battle_background.dampening
    love.graphics.setColor(dampening, dampening, dampening, 1)
    love.graphics.rectangle("fill", self._area.x, self._area.y, self._area.width, self._area.height)
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()
end

--- @overload rt.Widget.size_allocate
function bt.BattleBackground:size_allocate(x, y, width, height)

    self._vertex_shape:set_vertex_position(1, x + 0, y + 0)
    self._vertex_shape:set_vertex_position(2, x + width, y + 0 )
    self._vertex_shape:set_vertex_position(3, x + width, y + height)
    self._vertex_shape:set_vertex_position(4, x + 0, y + height)
    self._area = rt.AABB(x, y, width, height)
end

--- @overload rt.Animation.update
function bt.BattleBackground:update(delta)
    self._elapsed = self._elapsed + delta
    self._shader:send("_time", self._elapsed)
end