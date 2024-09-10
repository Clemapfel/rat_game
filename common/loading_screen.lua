rt.settings.loading_screen = {
    opacity_sweep_duration = 0.5,   -- seconds
    label_frame_duration = 1 / 2,   -- seconds
}

--- @class rt.LoadingScreen
rt.LoadingScreen = meta.new_type("LoadingScreen", rt.Widget, rt.Animation, function()
    local out = meta.new(rt.LoadingScreen, {
        _shape = rt.VertexRectangle(0, 0, 1, 1),
        _label_frames = {},
        _frame_i = 1,
        _elapsed = 0,
        _is_active = false,
        _current_opacity = 0
    })

    out._n_frames = 4
    local prefix, postfix = "<b><wave><rainbow>", "</wave></rainbow></b>"
    for i = 1, out._n_frames do
        table.insert(out._label_frames, rt.Label(
            prefix .. "Loading" .. string.rep(".", i - 1) .. postfix,
            rt.settings.font.default_large, rt.settings.font.default_large_mono
        ))
    end
    return out
end)

--- @override
function rt.LoadingScreen:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    for labels in values(self._label_frames) do
        labels:realize()
    end
end

--- @override
function rt.LoadingScreen:size_allocate(x, y, width, height)
    self._shape:reformat(
        x, y,
        x + width, y,
        x + width, y + height,
        x, y + height
    )

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

    self._shape:set_color(rt.RGBA(0, 0, 0, self._current_opacity))
end

--- @override
function rt.LoadingScreen:update(delta)
    self._elapsed = self._elapsed + delta
    local frame_duration = rt.settings.loading_screen.frame_duration
    while self._elapsed > frame_duration do
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
    local step = 1 / rt.settings.opacity_sweep_duration * delta
    if self._is_active and self._current_opacity < 1 then
        self._current_opacity = self._current_opacity + step
        opacity_changed = true
    elseif self._is_active == false and self._current_opacity > 0 then
        self._current_opacity = self._current_opacity - step
        opacity_changed = true
    end

    if opacity_changed then
        self._current_opacity = clamp(self._current_opacity, 0, 1)
        self._shape:set_color(rt.RGBA(0, 0, 0, self._current_opacity))
    end

end

--- @override
function rt.LoadingScreen:draw()
    self._shape:draw()
    self._label_frames[self._frame_i]:draw()
end

--- @brief
function rt.LoadingScreen:show()
    self._is_active = true
end

--- @brief
function rt.LoadingScreen:hide()
    self._is_active = false
end