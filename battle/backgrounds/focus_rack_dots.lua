rt.settings.battle.background.eye = {
    shader_path = "battle/backgrounds/eye.glsl"
}

bt.Background.FOCUS_RACK_DOTS = meta.new_type("FOCUS_RACK_DOTS", bt.Background, function()
    return meta.new(bt.Background.FOCUS_RACK_DOTS, {
        _shader = {},   -- rt.Shader
        _shape = rt.VertexRectangle(0, 0, 10, 10),
        _shape_texture = rt.RenderTexture(50, 50),
        _elapsed = 0,
        _focus = 0.5; -- in [0, 1]
    })
end)

--- @override
function bt.Background.FOCUS_RACK_DOTS:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._shader = rt.Shader("battle/backgrounds/focus_rack_dots.glsl")

    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.UP then
            self._focus = self._focus + 0.01
        elseif which == rt.InputButton.DOWN then
            self._focus = self._focus - 0.01
        end
        dbg(self._focus)
    end)
end

--- @override
function bt.Background.FOCUS_RACK_DOTS:size_allocate(x, y, width, height)
    self._shape:set_vertex_position(1, x, y)
    self._shape:set_vertex_position(2, x + width, y)
    self._shape:set_vertex_position(3, x + width, y + height)
    self._shape:set_vertex_position(4, x, y + height)
end

--- @override
function bt.Background.FOCUS_RACK_DOTS:update(delta, intensity)
    self._elapsed = self._elapsed + delta
end

--- @override
function bt.Background.FOCUS_RACK_DOTS:draw()
    self._shader:bind()
    --self._shader:send("elapsed", self._elapsed)
    self._shader:send("focus", self._focus)
    self._shape:draw()
    self._shader:unbind()
end
