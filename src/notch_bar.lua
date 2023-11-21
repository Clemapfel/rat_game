--- @class rt.NotchBar
rt.NotchBar = meta.new_type("NotchBar", function(n_notches)
    if meta.is_nil(n_notches) then n_notches = 1 end
    meta.assert_number(n_notches)

    local out = meta.new(rt.NotchBar, {
        _n_notches = n_notches,
        _filled = {},   --  notch_index -> is_filled,
        _nochtes = {},
        _center = rt.Circle(0, 0, 1, 16),
        _center_outline = rt.Circle(0, 0, 1, 16),
        _backdrop = rt.Circle(0, 0, 1, 16),
        _frame = rt.Circle(0, 0, 1, 16),
        _frame_outline_inner = rt.Circle(0, 0, 1, 16),
        _frame_outline_outer = rt.Circle(0, 0, 1, 16)
    }, rt.Drawable, rt.Widget)

    out._center_outline:set_is_outline(true)
    out._frame_outline_inner:set_is_outline(true)
    out._frame_outline_outer:set_is_outline(true)

    out._center:set_color(rt.Palette.FOREGROUND)
    out._center_outline:set_color(rt.Palette.FOREGROUND_OUTLINE)
    out._frame:set_color(rt.Palette.FOREGROUND)
    out._frame_outline_inner:set_color(rt.Palette.BASE_OUTLINE)
    out._frame_outline_outer:set_color(rt.Palette.BASE_OUTLINE)

    out._backdrop:set_color(rt.Palette.BASE)
    return out
end)

--- @overload rt.Drawable.draw
function rt.NotchBar:draw()
    self._frame:draw()
    self._backdrop:draw()
    self._center:draw()
    self._center_outline:draw()
    self._frame_outline_inner:draw()
    self._frame_outline_outer:draw()
end

--- @overload rt.Widget.size_allocate
function rt.NotchBar:size_allocate(x, y, width, height)
    local radius = math.min(width, height) / 2
    local center_x, center_y = x + 0.5 * width, y + 0.5 * height

    local min_frame_thickness = 4
    local center_radius = math.max(0.3 * radius, min_frame_thickness)
    local frame_radius = math.min(0.8 * radius, radius - min_frame_thickness) -- inner
    local eps = 1 / 400

    self._center:resize(center_x, center_y, center_radius)
    self._center_outline:resize(center_x, center_y, center_radius + eps)
    self._backdrop:resize(center_x, center_y, frame_radius)
    self._frame:resize(center_x, center_y, radius)
    self._frame_outline_inner:resize(center_x, center_y, frame_radius)
    self._frame_outline_outer:resize(center_x, center_y, radius)
end

--- @brief [internal]
function rt.NotchBar:_update_notches()
end

--- @brief
--- @param notch_i Number (or Table<Number>)
--- @param filled Boolean
function rt.NotchBar:set_filled(notch_i, filled)
    meta.assert_isa(self, rt.NotchBar)
    if not meta.is_table(notch_i) then
        meta.assert_number(notch_i)
    end
    meta.assert_boolean(filled)

    local assert_notch_i = function(i)
        if i < 1 or i > self._n_notches then
            rt.error("In rt.Notchbar.set_notch: index `" .. tostring(i) .. "` is out of bounds for a notch bar with `" .. tostring(self._n_notches) .."` notches")
        end
    end

    if meta.is_number(notch_i) then
        assert_notch_i(notch_i)
        local current = self._filled[notch_i]
        self._filled[notch_i] = filled

        if current ~= filled then
            self:_update_notches()
        end
    else
        local changed = false
        for _, i in pairs(notch_i) do
            assert_notch_i(i)

            local current = self._filled
            self._filled[notch_i] = filled
            if current ~= filled then changed = true end
        end
        if changed then
            self._update_notches()
        end
    end
end
