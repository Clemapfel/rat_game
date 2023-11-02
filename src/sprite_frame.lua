--- @class rt.SpriteFrame
rt.SpriteFrame = meta.new_type("SpriteFrame", function(spritesheet)  
    meta.assert_isa(spritesheet, rt.Spritesheet)
    local out = meta.new(rt.SpriteFrame, {
        _spritesheet = spritesheet,
        _top_left = rt.Sprite(spritesheet, "top_left"),
        _top = rt.Sprite(spritesheet, "top"),
        _top_right = rt.Sprite(spritesheet, "top_right"),
        _right = rt.Sprite(spritesheet, "right"),
        _bottom_right = rt.Sprite(spritesheet, "bottom_right"),
        _bottom = rt.Sprite(spritesheet, "bottom"),
        _bottom_left = rt.Sprite(spritesheet, "bottom_left"),
        _left = rt.Sprite(spritesheet, "left"),
        _child = {},
        _width = 30
    }, rt.Drawable, rt.Widget)

    --[[
    out._top_left:set_expand(false)
    out._top_right:set_expand(false)
    out._bottom_left:set_expand(false)
    out._bottom_right:set_expand(false)

    out._top:set_expand_horizontally(true)
    out._top:set_expand_vertically(false)
    out._bottom:set_expand_horizontally(true)
    out._bottom:set_expand_vertically(false)
    out._left:set_expand_horizontally(false)
    out._left:set_expand_vertically(true)
    out._right:set_expand_horizontally(false)
    out._right:set_expand_vertically(true)
    ]]--

    return out
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.SpriteFrame:set_child(child)
    meta.assert_isa(self, rt.SpriteFrame)
    meta.assert_isa(self, rt.Widget)

    if not meta.is_nil(self._child) and meta.isa(self._child, rt.Widget) then
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
    meta.assert_isa(self, rt.SpriteFrame)
    return self._child
end

--- @brief remove child
function rt.SpriteFrame:remove_child()
    meta.assert_isa(self, rt.SpriteFrame)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Drawable.draw
function rt.SpriteFrame:draw()
    meta.assert_isa(self, rt.SpriteFrame)
    if self:get_is_visible() and meta.isa(self._child, rt.Widget) then
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
    meta.assert_isa(self, rt.SpriteFrame)

    local fw, fh = self._spritesheet:get_frame_size("top_left")

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

    if meta.isa(self._child, rt.Widget) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @overload rt.Widget.measure
function rt.SpriteFrame:measure()
    meta.assert_isa(self, rt.SpriteFrame)
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.SpriteFrame:realize()
    meta.assert_isa(self, rt.SpriteFrame)
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

    if meta.isa(self._child, rt.Widget) then
        self._child:realize()
    end
end

--- @param width Number in px, or 0 for default width
function rt.Spritesheet:set_width(number)
    meta.assert_number(number)
    self._width = number
    self:reformat()
end

--- @brief multiple color of frame sprites
function rt.SpriteFrame:set_color(color)
    meta.assert_isa(self, rt.SpriteFrame)

    self._top_left:set_color(color)
    self._top:set_color(color)
    self._top_right:set_color(color)
    self._right:set_color(color)
    self._bottom_right:set_color(color)
    self._bottom:set_color(color)
    self._bottom_left:set_color(color)
    self._left:set_color(color)
end
