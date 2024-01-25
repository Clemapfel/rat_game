rt.settings.sprite_frame = {
    top_left_id = "top_left",
    top_id = "top",
    top_right_id = "top_right",
    right_id = "right",
    bottom_right_id = "bottom_right",
    bottom_id = "bottom",
    bottom_left_id = "bottom_left",
    left_id = "left"
}

--- @class rt.SpriteFrame
rt.SpriteFrame = meta.new_type("SpriteFrame", function(spritesheet)

    local out = meta.new(rt.SpriteFrame, {
        _spritesheet = spritesheet,
        _top_left = rt.Sprite(spritesheet, rt.settings.sprite_frame.top_left_id),
        _top = rt.Sprite(spritesheet, rt.settings.sprite_frame.top_id),
        _top_right = rt.Sprite(spritesheet, rt.settings.sprite_frame.top_right_id),
        _right = rt.Sprite(spritesheet, rt.settings.sprite_frame.right_id),
        _bottom_right = rt.Sprite(spritesheet, rt.settings.sprite_frame.bottom_right_id),
        _bottom = rt.Sprite(spritesheet, rt.settings.sprite_frame.bottom_id),
        _bottom_left = rt.Sprite(spritesheet, rt.settings.sprite_frame.bottom_left_id),
        _left = rt.Sprite(spritesheet, rt.settings.sprite_frame.left_id),
        _child = {},
        _width = 30
    }, rt.Drawable, rt.Widget)

    return out
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.SpriteFrame:set_child(child)



    if not meta.is_nil(self._child) and meta.is_widget(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._child:realize()
        self:reformat()
    end
end

--- @brief get singular child
--- @return rt.Widget
function rt.SpriteFrame:get_child()

    return self._child
end

--- @brief remove child
function rt.SpriteFrame:remove_child()

    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.e.draw
function rt.SpriteFrame:draw()

    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end

    self._top_left:draw()
    self._top:draw()
    self._top_right:draw()
    self._right:draw()
    self._bottom_right:draw()
    self._bottom:draw()
    self._bottom_left:draw()
    self._left:draw()
end

--- @overload rt.Widget.size_allocate
function rt.SpriteFrame:size_allocate(x, y, width, height)


    local fw, fh = self._spritesheet:get_frame_size(rt.settings.sprite_frame.top_left_id)

    if self._width ~= 0 then
        fw = self._width
        fh = self._width
    end

    self._top_left:fit_into(rt.AABB(x, y, fw, fh))
    self._top:fit_into(rt.AABB(x + fw, y, width - 2 * fw, fh))
    self._top_right:fit_into(rt.AABB(x + width - fw, y, fw, fh))
    self._right:fit_into(rt.AABB(x + width - fw, y + fh, fw, height - 2 * fh))
    self._bottom_right:fit_into(rt.AABB(x + width - fw, y + height - fh, fw, fh))
    self._bottom:fit_into(rt.AABB(x + fw, y + height - fh, width - 2 * fw, fh))
    self._bottom_left:fit_into(rt.AABB(x, y + height - fh, fw, fh))
    self._left:fit_into(rt.AABB(x, y + fh, fw, height - 2 * fw))

    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @overload rt.Widget.measure
function rt.SpriteFrame:measure()

    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.SpriteFrame:realize()

    if self:get_is_realized() then return end
    self._realized = true
    self._top_left:realize()
    self._top:realize()
    self._top_right:realize()
    self._right:realize()
    self._bottom_right:realize()
    self._bottom:realize()
    self._bottom_left:realize()
    self._left:realize()

    if meta.is_widget(self._child) then
        self._child:realize()
    end
end

--- @param width Number in px, or 0 for default width
function rt.Spritesheet:set_width(number)

    self._width = number
    self:reformat()
end

--- @brief multiple color of frame sprites
function rt.SpriteFrame:set_color(color)


    self._top_left:set_color(color)
    self._top:set_color(color)
    self._top_right:set_color(color)
    self._right:set_color(color)
    self._bottom_right:set_color(color)
    self._bottom:set_color(color)
    self._bottom_left:set_color(color)
    self._left:set_color(color)
end

--- @brief [internal] test
function rt.test.sprite_frame()
    error("TODO")
end
