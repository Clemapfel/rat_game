--- @class RevealLayout
rt.RevealLayout = meta.new_type("RevealLayout", function(child)
    local out = meta.new(rt.RevealLayout, {
        _child = {},
        _is_revealed = true,
        _current_offset = 0,
        _max_offset = 0,
        _area = rt.AABB(0, 0, 1, 1)
    }, rt.Drawable, rt.Widget, rt.Animation)
    out:set_is_animated(true)
    return out
end)

--- @brief
function rt.RevealLayout:set_is_revealed(b)
    self._is_revealed = true
end

--- @brief
function rt.RevealLayout:get_is_revealed()
    return self._is_revealed
end

--- @overload
function rt.RevealLayout:update(delta)

    local speed = 10
    if self._is_revealed and self._current_offset > 0 then
        self._current_offset = self._current_offset - speed * delta
        self._current_offset = clamp(self._current_offset, 0, self._max_offset)
    elseif self._is_revealed and self._current_offset < self._max_offset then
        self._current_offset = self._current_offset + speed * delta
        self._current_offset = clamp(self._current_offset, 0, self._max_offset)
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.RevealLayout:set_child(child)
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
function rt.RevealLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.RevealLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end

--- @overload rt.Drawable.draw
function rt.RevealLayout:draw()
    love.graphics.translate(self._current_offset, 0)
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.size_allocate
function rt.RevealLayout:size_allocate(x, y, width, height)
    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end
end

--- @overload rt.Widget.measure
function rt.RevealLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.RevealLayout:realize()

    if self:get_is_realized() then return end

    self._realized = true
    if meta.is_widget(self._child) then
        self._child:realize()
    end
end
