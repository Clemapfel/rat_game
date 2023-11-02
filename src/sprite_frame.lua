--- @class rt.SpriteFrame
rt.SpriteFrame = meta.new_type("SpriteFrame", function(spritesheet)  
    meta.assert_isa(sprite, rt.Spritesheet)
    local out = meta.new(rt.SpriteFrame, {
        _top_left = rt.Sprite(spritesheet, "top_left"),
        _top = rt.Sprite(spritesheet, "top"),
        _top_right = rt.Sprite(spritesheet, "top_right"),
        _right = rt.Sprite(spritesheet, "right"),
        _bottom_right = rt.Sprite(spritesheet, "bottom_right"),
        _bottom = rt.Sprite(spritesheet, "bottom"),
        _bottom_left = rt.Sprite(spritesheet, "bottom_left"),
        _left = rt.Spritesheet(spritesheet, "left"),
        _child = {}
    }, rt.Drawable, rt.Widget)
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
end

--- @overload rt.Widget.size_allocate
function rt.SpriteFrame:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.SpriteFrame)
    if meta.isa(self._child, rt.Widget) then
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
    if meta.isa(self._child, rt.Widget) then
        self._child:realize()
    end
end
