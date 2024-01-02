rt.EmblemPosition = meta.new_enum({
    TOP_LEFT = "TOP_LEFT",
    TOP_RIGHT = "TOP_RIGHT",
    BOTTOM_LEFT = "BOTTOM_LEFT",
    BOTTOM_RIGHT = "BOTTOM_RIGHT"
})

--- @class rt.EmblemLayout
rt.EmblemLayout = meta.new_type("EmblemLayout", function(position)
    position = which(position, rt.EmblemPosition.TOP_RIGHT)
    return meta.new(rt.EmblemLayout, {
        _child = {},
        _emblem = {},
        _emblem_position = position
    }, rt.Widget, rt.Drawable)
end)

--- @brief set singular child
--- @param child rt.Widget
function rt.EmblemLayout:set_child(child)
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
function rt.EmblemLayout:get_child()
    return self._child
end

--- @param child rt.Widget
function rt.EmblemLayout:set_emblem(emblem)
    if not meta.is_nil(self._emblem) and meta.is_widget(self._emblem) then
        self._emblem:set_parent(nil)
    end

    self._emblem = emblem
    emblem:set_parent(self)

    if self:get_is_realized() then
        self._emblem:realize()
        self:reformat()
    end
end

--- @brief get singular emblem
--- @return rt.Widget
function rt.EmblemLayout:get_emblem()
    return self._emblem
end

--- @brief remove emblem
function rt.EmblemLayout:remove_emblem()
    if not meta.is_nil(self._emblem) then
        self._emblem:set_parent(nil)
        self._emblem = nil
    end
end

--- @overload rt.Drawable.draw
function rt.EmblemLayout:draw()
    if self:get_is_visible() and meta.is_widget(self._child) then
        self._child:draw()
        self._emblem:draw()
    end
end

--- @brief
function rt.EmblemLayout:set_emblem_position(position)
    self._emblem_position = position
    self:reformat()
end

--- @brief
function rt.EmblemLayout:get_emblem_position()
    return self._emblem_position
end

--- @overload rt.Widget.size_allocate
function rt.EmblemLayout:size_allocate(x, y, width, height)
    if meta.is_widget(self._child) then
        self._child:fit_into(rt.AABB(x, y, width, height))
    end

    if meta.is_widget(self._emblem) then
        local w, h = self._emblem:measure()
        if self._emblem_position == rt.EmblemPosition.TOP_LEFT then
            self._emblem:fit_into(rt.AABB(x - 0.5 * w, y - h * 0.5, w, h))
        elseif self._emblem_position == rt.EmblemPosition.TOP_RIGHT then
            self._emblem:fit_into(rt.AABB(x + width - 0.5 * w, y - h * 0.5, w, h))
        elseif self._emblem_position == rt.EmblemPosition.BOTTOM_RIGHT then
            self._emblem:fit_into(rt.AABB(x + width - 0.5 * w, y + height - 0.5 * h, w, h))
        elseif self._emblem_position == rt.EmblemPosition.BOTTOM_LEFT then
            self._emblem:fit_into(rt.AABB(x - 0.5 * w, y + height - 0.5 * h, w, h))
        end
    end
end

--- @overload rt.Widget.measure
function rt.EmblemLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.EmblemLayout:realize()
    if self:get_is_realized() then return end
    self._realized = true
    if meta.is_widget(self._child) then
        self._child:realize()
    end

    if meta.is_widget(self._emblem) then
        self._emblem:realize()
    end
end
