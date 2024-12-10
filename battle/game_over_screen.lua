rt.settings.battle.game_over_screen = {
    vignette_transition_duration = 5, -- seconds
}

--- @class bt.GameOverScreen
bt.GameOverScreen = meta.new_type("GameOverScreen", rt.Updatable, rt.Widget, function()
    local settings = rt.settings.battle.game_over_screen
    return meta.new(bt.GameOverScreen, {
        _load_save_label = nil, -- rt.Label
        _load_quicksave_label = nil, -- "
        _heading_label = nil, -- "

        _vignette_shader = rt.Shader("battle/game_over_screen.glsl"),
        _vignette_shape = rt.VertexRectangle(0, 0, 1, 1),
        _duration = settings.vignette_transition_duration,
        _elapsed = 0
    })
end)

--- @override
function bt.GameOverScreen:realize()
    if self:already_realized() then return end
end

--- @override
function bt.GameOverScreen:size_allocate(x, y, width, height)
    self._vignette_shape:reformat(
        x, y,
        x + width, y,
        x + width, y + height,
        x, y + height
    )

    self._vignette_shader:send("black", {rt.color_unpack(rt.Palette.BLACK)})
    self._vignette_shader:send("red", {rt.color_unpack(rt.Palette.CINNABAR)})
end

--- @override
function bt.GameOverScreen:update(delta)
    self._elapsed = self._elapsed + delta
    --self._vignette_shader:send("fraction", clamp(self._elapsed / self._duration, 0, 1))
    self._vignette_shader:send("fraction", rt.InterpolationFunctions.SINE_WAVE(self._elapsed / self._duration))
end

--- @override
function bt.GameOverScreen:draw()
    self._vignette_shader:bind()
    self._vignette_shape:draw()
    self._vignette_shader:unbind()
end