--- @class rt.Sprite
rt.Sprite = meta.new_type("Sprite", function(spritesheet, animation_id)
    if meta.is_nil(animation_id) then
        animation_id = spritesheet.name
    end
    spritesheet:_assert_has_animation("Sprite:", animation_id)
    local w, h = spritesheet:get_frame_size(animation_id)
    local out = meta.new(rt.Sprite, {}, rt.Drawable, rt.Widget)

    out._spritesheet = spritesheet
    out._animation_id = animation_id
    out._current_frame = 1
    out._frame_width = w
    out._frame_height = h

    out:set_minimum_size(w, h)
    out:set_expand(false)
    out._shape:set_texture(out._spritesheet)
    out:set_frame(1)
    return out
end)

rt.Sprite._spritesheet = {}
rt.Sprite._animation_id = ""
rt.Sprite._current_frame = -1
rt.Sprite._shape = rt.VertexRectangle(0, 0, 0, 0)
rt.Sprite._frame_width = 0
rt.Sprite._frame_height = 0

--- @overload rt.Drawable.draw
function rt.Sprite:draw()
    meta.assert_isa(self, rt.Sprite)

    if self:get_is_visible() then
        self._shape:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.Sprite:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.Sprite)

    if self._allow_scaling then
        self._shape:resize(x, y, width, height)
        return
    end

    x = x + self:get_margin_left()
    y = y + self:get_margin_top()

    local fw = ternary(self:get_expand_horizontally(), width, self._frame_width)
    local fh = ternary(self:get_expand_vertically(), height, self._frame_height)
    local w = width - self:get_margin_right()
    local h = height - self:get_margin_bottom()

    if fw > w then fw = w end
    if fh > h then fh = h end

    local x_align = self:get_horizontal_alignment()
    local y_align = self:get_vertical_alignment()

    if x_align == rt.Alignment.START and y_align == rt.Alignment.START then
        self._shape:resize(x, y, fw, fh)
    elseif x_align == rt.Alignment.START and y_align == rt.Alignment.CENTER then
        self._shape:resize(x, y + 0.5 * h - 0.5 * fh, fw, fh)
    elseif x_align == rt.Alignment.START and y_align == rt.Alignment.END then
        self._shape:resize(x, y + h - fh, fw, fh)
    elseif x_align == rt.Alignment.CENTER and y_align == rt.Alignment.START then
        self._shape:resize(x + 0.5 * w - 0.5 * fw, y, fw, fh)
    elseif x_align == rt.Alignment.CENTER and y_align == rt.Alignment.CENTER then
        self._shape:resize(x + 0.5 * w - 0.5 * fw, y + 0.5 * h - 0.5 * fh, fw, fh)
    elseif x_align == rt.Alignment.CENTER and y_align == rt.Alignment.END then
        self._shape:resize(x + 0.5 * w - 0.5 * fw, y + h - fh, fw, fh)
    elseif x_align == rt.Alignment.END and y_align == rt.Alignment.START then
        self._shape:resize(x + w - fw, y, fw, fh)
    elseif x_align == rt.Alignment.END and y_align == rt.Alignment.CENTER then
        self._shape:resize(x + w - fw, y + 0.5 * h - 0.5 * fh, fw, fh)
    elseif x_align == rt.Alignment.END and y_align == rt.Alignment.END then
        self._shape:resize(x + w - fw, y + h - fh, fw, fh)
    end
end

--- @overload rt.Widget.measure
function rt.Sprite:measure()
    local w, h = self._frame_width, self._frame_height
    w = w + self:get_margin_left() + self:get_margin_right()
    h = h + self:get_margin_top() + self:get_margin_bottom()
    return w, h
end

--- @brief
function rt.Sprite:set_frame(i)
    meta.assert_isa(self, rt.Sprite)
    meta.assert_number(i)
    local n_frames = self._spritesheet:get_n_frames(self._animation_id)
    if i < 1 or i > n_frames then
        error("[rt] In Sprite:set_frame: frame index `" .. tostring(i) .. "` is out of range for animation `" .. self._animation_id .. "` of spritesheet `" .. self._spritesheet.name .. "` which has `" .. tostring(n_frames) .. "` frames")
    end

    self._current_frame = i
    self._shape:set_texture_rectangle(self._spritesheet:get_frame(self._animation_id, i))
end

--- @brief
function rt.Sprite:get_frame()
    meta.assert_isa(self, rt.Sprite)
    return self._current_frame
end

--- @brief
function rt.Sprite:get_n_frames()
    meta.assert_isa(self, rt.Sprite)
    return self._spritesheet:get_n_frames(self._animation_id)
end
