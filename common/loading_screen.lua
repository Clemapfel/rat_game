rt.settings.loading_screen = {
    fade_in_duration = 0.25,  -- seconds
    fade_out_duration = 0.1, -- seconds
    frame_duration = 1 / 2,  -- seconds
}

--- @class rt.LoadingScreen
--- @signal shown (self) -> nil
--- @signal hidden (self) -> nil
rt.LoadingScreen = meta.new_type("LoadingScreen", rt.Widget, rt.Animation, rt.SignalEmitter, function()
    local out = meta.new(rt.LoadingScreen, {
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _label_frames = {},
        _frame_i = 1,
        _elapsed = 0,
        _is_active = false,
        _current_opacity = 1
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

    out:signal_add("show")
    out:signal_add("hidden")
    return out
end)

--- @override
function rt.LoadingScreen:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for labels in values(self._label_frames) do
        labels:realize()
    end

    self:_update_color()
end

--- @override
function rt.LoadingScreen:size_allocate(x, y, width, height)
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
function rt.LoadingScreen:update(delta)
    self._elapsed = self._elapsed + delta
    local frame_duration = rt.settings.loading_screen.frame_duration
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

    local opacity_changed = false
    local step_up = 1 / rt.settings.loading_screen.fade_in_duration * delta
    local step_down = 1 / rt.settings.loading_screen.fade_out_duration * delta
    if self._is_active and self._current_opacity < 1 then
        local before = self._current_opacity
        self._current_opacity = self._current_opacity + step_up
        opacity_changed = true
        if before >= 1 then
            self:signal_emit("shown")
        end
    elseif self._is_active == false and self._current_opacity > 0 then
        self._current_opacity = self._current_opacity - step_down
        opacity_changed = true
        if self._current_opacity <= 0 then
            self:signal_emit("hidden")
        end
    end

    if opacity_changed then
        self._current_opacity = clamp(self._current_opacity, 0, 1)
        self:_update_color()
    end
end

--- @brief
function rt.LoadingScreen:_update_color()
    self._shape:set_color(rt.RGBA(
        1 - self._current_opacity,
        1 - self._current_opacity,
        1 - self._current_opacity,
        1
    ))
end

--- @override
function rt.LoadingScreen:draw()
    rt.graphics.set_blend_mode(rt.BlendMode.MULTIPLY, rt.BlendMode.MULTIPLY)
    self._shape:draw()
    rt.graphics.set_blend_mode()

    if self._current_opacity >= 1 then
        self._label_frames[self._frame_i]:draw()
    end
end

--- @brief
function rt.LoadingScreen:show()
    self._is_active = true
end

--- @brief
function rt.LoadingScreen:hide()
    self._is_active = false
end