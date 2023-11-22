--- @class rt.TransitionLayout
rt.TransitionLayout = meta.new_type("TransitionLayout", function(child)
    local initial_w, initial_h = child:measure()
    local out = meta.new(rt.TransitionLayout, {
        _child = ternary(meta.is_nil(child), {}, child),
        _min_w = initial_w,
        _min_h = initial_h,
        _current_w = initial_w,
        _current_h = initial_h,
        _target_w = initial_w,
        _target_h = initial_h,
        _animation_timer = {}
    }, rt.Drawable, rt.Widget)
    return out
end)

function rt.TransitionLayout:start_transition()

end

--- @overload rt.Drawabl.draw
function rt.TransitionLayout:draw()
    meta.assert_isa(self, rt.TransitionLayout)
    if meta.is_widget(self._child) then
        self._child:draw()
    end
end

--- @overload rt.Widget.measure
function rt.TransitionLayout:measure()
    meta.assert_isa(self, rt.TransitionLayout)
    return self._current_w, self._current_h
end

--- @overload rt.Widget.size_allocate
function rt.TransitionLayout:size_allocate(x, y, width, height)
    meta.assert_isa(self, rt.TransitionLayout)
    if meta.is_widget(self._child) then
        child:fit_into(x, y, self._current_w, self._current_h)
    end
end

--- @overload rt.Widget.realize
function rt.TransitionLayout:realize()
    meta.assert_isa(self, rt.TransitionLayout)
    if meta.is_widget(self._child) then
        self._child:realize()
    end
end

--- @brief set singular child
--- @param child rt.Widget
function rt.TransitionLayout:set_child(child)
    meta.assert_isa(self, rt.TransitionLayout)
    meta.assert_isa(child, rt.Widget)

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
function rt.TransitionLayout:get_child()
    meta.assert_isa(self, rt.TransitionLayout)
    return self._child
end

--- @brief remove child
function rt.TransitionLayout:remove_child()
    meta.assert_isa(self, rt.TransitionLayout)
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end
end