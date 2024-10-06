rt.settings.loading_screen.default = {
    fade_in_duration = 0.25,  -- seconds
    fade_out_duration = 0.1, -- seconds
    frame_duration = 1 / 2,  -- seconds
}

--- @class rt.LoadingScreen.DEFAULT
--- @brief use show / hide to reveal, if hidden during show, interpolates and smoothly transitions
--- @signal shown (self) -> nil
--- @signal hidden (self) -> nil
rt.LoadingScreen.DEFAULT = meta.new_type("LoadingScreen_DEFAULT", rt.LoadingScreen, function()
    local out = meta.new(rt.LoadingScreen.DEFAULT, {
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _label_frames = {},
        _frame_i = 1,
        _elapsed = 0,
        _is_active = false,
        _current_opacity = 0,
        _fade_in_elapsed = 0,
        _fade_out_elapsed = 0,
        _label_visible = false,
        _shown_emitted = false,
        _hidden_emitted = false,
    })

    out._n_frames = 4
    local prefix, postfix = "<o><b><wave><rainbow>", "</wave></rainbow></b></o>"
    for i = 1, out._n_frames do
        table.insert(out._label_frames, rt.Label(
            prefix .. "Loading" .. string.rep(".", i - 1) .. postfix,
            rt.settings.font.default_large, rt.settings.font.default_large_mono
        ))
    end

    out:_update_color()

    out:signal_add("shown")
    out:signal_add("hidden")
    return out
end)

--- @override
function rt.LoadingScreen.DEFAULT:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for labels in values(self._label_frames) do
        labels:realize()
    end

    self:_update_color()
end

--- @override
function rt.LoadingScreen.DEFAULT:size_allocate(x, y, width, height)
    self._shape:reformat(x, y, x + width, y, x + width, y + height, x, y + height)

    local max_label_w = NEGATIVE_INFINITY
    local label_hs = {}
    for label in values(self._label_frames) do
        local w, h = label:measure()
        max_label_w = math.max(max_label_w, w)
        table.insert(label_hs, h)
    end

    local m = rt.settings.margin_unit
    local outer_margin = 4 * m
    for i, label in ipairs(self._label_frames) do
        label:fit_into(x + width - max_label_w - outer_margin, y + height - label_hs[i] - outer_margin)
    end

    self:_update_color()
end

--- @override
function rt.LoadingScreen.DEFAULT:update(delta)
    self._elapsed = self._elapsed + delta
    local frame_duration = rt.settings.loading_screen.default.frame_duration
    while self._current_opacity > 0 and self._elapsed > frame_duration do
        self._elapsed = self._elapsed - frame_duration
        self._frame_i = self._frame_i + 1
        if self._frame_i > self._n_frames then
            self._frame_i = 1
        end
    end

    for label in values(self._label_frames) do
        label:update(delta)
    end

    -- when walking along `f(t)` by `dt`, step is `(f(t + dt) - f(t)) / dt`

    local eps = 1 / 1000

    local opacity_changed = false
    if self._is_active and self._current_opacity <= 1 then
        local fade_in_duration = rt.settings.loading_screen.default.fade_in_duration
        local f_high = rt.gaussian_highpass(self._fade_in_elapsed / fade_in_duration + delta / fade_in_duration)
        local f_low = rt.gaussian_highpass(self._fade_in_elapsed / fade_in_duration)
        self._fade_in_elapsed = self._fade_in_elapsed + delta
        local step = f_high - f_low
        self._current_opacity = self._current_opacity + step

        if self._current_opacity >= 1 - eps then
            if self._shown_emitted == false then
                self:signal_emit("shown")
                self._shown_emitted = true
            end
            self._label_visible = true
        end

        opacity_changed = true
    elseif self._is_active == false and self._current_opacity > 0 then
        local fade_out_duration = rt.settings.loading_screen.default.fade_out_duration
        local f_high = 1 - rt.gaussian_highpass(self._fade_out_elapsed / fade_out_duration + delta / fade_out_duration)
        local f_low = 1 - rt.gaussian_highpass(self._fade_out_elapsed / fade_out_duration)
        self._fade_out_elapsed = self._fade_out_elapsed + delta
        local step = f_high - f_low
        self._current_opacity = self._current_opacity + step

        if self._current_opacity <= 0 + eps then
            if self._hidden_emitted == false then
                self:signal_emit("hidden")
                self._hidden_emitted = true
            end
        end

        opacity_changed = true
    end

    if opacity_changed then
        self._current_opacity = clamp(self._current_opacity, 0, 1)
        self:_update_color()
    end
end

--- @brief
function rt.LoadingScreen.DEFAULT:_update_color()
    self._shape:set_color(rt.RGBA(
        1 - self._current_opacity,
        1 - self._current_opacity,
        1 - self._current_opacity,
        1
    ))

    for labels in values(self._label_frames) do
        labels:set_opacity(clamp(self._current_opacity, 0, 1))
    end
end

--- @override
function rt.LoadingScreen.DEFAULT:draw()
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.MULTIPLY)
    self._shape:draw()
    rt.graphics.set_blend_mode()

    if self._label_visible then
        self._label_frames[self._frame_i]:draw()
    end
end

--- @brief
function rt.LoadingScreen.DEFAULT:show()
    self._is_active = true
    self._fade_in_elapsed = 0
    self._fade_out_elapsed = 0
    self._shown_emitted = false
    self._hidden_emitted = false
end

--- @brief
function rt.LoadingScreen.DEFAULT:hide()
    self._label_visible = false
    self._is_active = false
    self._fade_in_elapsed = 0
    self._fade_out_elapsed = 0
    self._shown_emitted = false
    self._hidden_emitted = false
end

--- @brief
function rt.LoadingScreen.DEFAULT:set_current_opacity(opacity)
    self._current_opacity = clamp(opacity, 0, 1)
end