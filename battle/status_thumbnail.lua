rt.settings.status_thumbnail.count_font = rt.Font(30, "assets/fonts/pixel.ttf")

--- @class bt.StatusThumbnail
bt.StatusThumbnail = meta.new_type("StatusThumbanil", function(status, count)
    local out = meta.new(bt.StatusThumbnail, {
        _sprite = status:create_sprite(),
        _aspect = rt.AspectLayout(1),
        _count = count,
        _count_label = rt.Glyph(rt.settings.status_thumbnail.count_font, tostring(count), { is_outlined = true })
    }, rt.Drawable, rt.Widget)

    out._aspect:set_child(out._sprite)
    out:set_count(count)

    local res_x, res_y = out._sprite:get_resolution()
    out._sprite:set_minimum_size(2 * res_x, 2 * res_y)
    out._aspect:set_expand(false)
    return out;
end)

--- @overload
function bt.StatusThumbnail:draw()
    self._aspect:draw()
    self._count_label:draw()
end

--- @overload
function bt.StatusThumbnail:size_allocate(x, y, width, height)
    self._aspect:fit_into(x, y, width, height)
    local label_w, label_h = self._count_label:get_size()

    x, y = self._sprite:get_position()
    local w, h = self._sprite:get_size()
    self._count_label:set_position(x + w - label_w, y + h - label_h)
end

--- @overload
function bt.StatusThumbnail:realize()
    self._aspect:realize()
    rt.Widget.realize(self)
end

--- @overload
function bt.StatusThumbnail:measure()
    return self._sprite:measure()
end

--- @brief
function bt.StatusThumbnail:set_count(n)

    local pos_x, pos_y = self._count_label:get_position()
    self._count = n
    self._count_label = rt.Glyph(rt.settings.status_thumbnail.count_font, tostring(n), {
        is_outlined = true
    })
    self._count_label:set_position(pos_x, pos_y)
end

