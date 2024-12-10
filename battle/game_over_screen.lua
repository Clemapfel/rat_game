rt.settings.battle.game_over_screen = {
    vignette_transition_duration = 10, -- seconds
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

        _value = 0,
        _direction = true
    })
end)
meta.add_signal(bt.GameOverScreen, "done")

--- @override
function bt.GameOverScreen:realize()
    if self:already_realized() then return end
end

--- @brief
function bt.GameOverScreen:set_is_expanded(b)
    self._direction = not b
end

--- @brief
function bt.GameOverScreen:get_is_expanded()
    return not self._direction
end

--- @brief
--- @brief
function bt.QuicksaveIndicator:skip()
    if self._direction == true then
        self._value = 1
    else
        self._value = 0
    end
    self:update(0)
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
    local step = delta * (1 / self._duration)
    local before = self._value
    if self._direction then
        self._value = self._value + step
        if before < 1 and self._value >= 1 then
            self:signal_emit("done")
        end
    else
        self._value = self._value - step
        if before > 0 and self._value <= 0 then
            self:signal_emit("done")
        end
    end
    self._value = clamp(self._value, 0, 1)
    self._vignette_shader:send("fraction", self._value)
end

--- @override
function bt.GameOverScreen:draw()
    self._vignette_shader:bind()
    self._vignette_shape:draw()
    self._vignette_shader:unbind()
end