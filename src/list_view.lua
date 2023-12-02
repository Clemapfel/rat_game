--- @class rt.ListView
rt.ListView = meta.new_type("ListView", function()
    return meta.new(rt.ListView, {
        _children = {},
        _children_hash = 0,
        _default_order = rt.List(),
        _area = rt.AABB(0, 0, 0, 0)
    }, rt.Drawable, rt.Widget)
end)

--- @brief
function rt.ListView:push_back(child)
    meta.assert_isa(self, rt.ListView)
    meta.assert_widget(child)
    table.insert(self._children, self._children_hash, child)
    self._default_order:push_back(self._children_hash)
    self._children_hash = self._children_hash + 1

    if self:get_is_realized() then
        child:realize()
    end
end

--- @overlad rt.Widget.size_allocate
function rt.ListView:size_allocate(x, y, width, height)
    local before = self._area.width
    self._area = rt.AABB(x, y, width, height)
    if width ~= before then
        for _, child in pairs(self._children) do
            local w, h = child:measure()
            child:fit_into(rt.AABB(0, 0, width, h))
        end
    end
end

--- @overload rt.Drawable.draw
function rt.ListView:draw()
    love.graphics.setScissor(self._area.x, self._area.y, self._area.width, self._area.height)
    local x, y = self._area.x, self._area.y
    local h_sum = 0

    local current = self._default_order._first_node
    while not meta.is_nil(current) do -- and h_sum <= self._area.height do
        local child = self._children[current.value]

        love.graphics.translate(x, y)
        child:draw()
        love.graphics.translate(-x, -y)

        y = y + select(2, child:measure())
        current = current.next
    end

    love.graphics.setScissor()
end

--- @overload rt.Widget.realize
function rt.ListView:realize()
    for _, child in pairs(self._children) do
        child:realize()
    end
    rt.Widget.realize(self)
end

--- @brief
function rt.ListView:sort_by()

end

