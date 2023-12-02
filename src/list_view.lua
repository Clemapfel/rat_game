rt.settings.list_view.default_sort_mode_id = "default"

--- @class rt.ListView
rt.ListView = meta.new_type("ListView", function()
    return meta.new(rt.ListView, {
        _children = {},              -- _children_hash -> {child, height}
        _children_hash = 0,          -- running hash
        _area = rt.AABB(0, 0, 0, 0),
        _sort_mode = rt.settings.list_view.default_sort_mode_id,
        _sortings = {}               -- name -> {comparator, order}
    }, rt.Drawable, rt.Widget)
end)

function rt.ListView:_regenerate_sorting(name)

    meta.assert_table(self._sortings[name])

    self._sortings[name].order = {}
    local to_sort = self._sortings[name].order
    local comp = self._sortings[name].comparator

    for i, _ in ipairs(self._children) do
        table.insert(to_sort, i)
    end

    table.sort(to_sort, function(x, y)
        local left = self._children[x].child
        local right = self._children[y].child
        return try_catch(function()
            local out = comp(left, right)
            meta.assert_boolean(out)
            return out
        end, function(error)
            rt.error("In ListView:_regenerate_sorting: comparator for sort mode `" .. name .. "` failed for widgets `" .. tostring(meta.typeof(left)) .. "`, `" .. tostring(meta.typeof(right)) .. "`: " .. error)
        end)
    end)

end

--- @brief
function rt.ListView:add_sort_mode(name, comparator)
    meta.assert_isa(self, rt.ListView)
    meta.assert_string(name)
    meta.assert_function(comparator)

    self._sortings[name] = {
        comparator = comparator,
        order = {}
    }
end

--- @brief
function rt.ListView:set_sort_mode(name)
    meta.assert_isa(self, rt.ListView)
    meta.assert_string(name)

    if meta.is_nil(self._sortings[name]) then
        rt.error("In rt.ListView.set_sort_mode: no sort mode `" .. name .. "` registered")
    end

    self._sort_mode = name
    if #self._sortings[name].order ~= #self._children then
        self:_regenerate_sorting(name)
    end
end

--- @brief
function rt.ListView:get_sort_mode()
    meta.assert_isa(self, rt.ListView)
    return self._sort_mode
end

--- @brief
function rt.ListView:push_back(child)
    meta.assert_isa(self, rt.ListView)
    meta.assert_widget(child)
    table.insert(self._children, self._children_hash, {
        child = child,
        height = 0,
    })
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
        for _, t in pairs(self._children) do
            local w, h = t.child:measure()
            t.height = h
            t.child:fit_into(rt.AABB(0, 0, width, h))
        end
    end
end

--- @overload rt.Drawable.draw
function rt.ListView:draw()
    love.graphics.setScissor(self._area.x, self._area.y, self._area.width, self._area.height)
    local x, y = self._area.x, self._area.y
    local h_sum = 0

    -- if unsorted, used order of insertion
    if self._sort_mode == rt.settings.list_view.default_sort_mode_id then
        for i, t in ipairs(self._children) do
            love.graphics.translate(x, y)
            t.child:draw()
            love.graphics.translate(-x, -y)

            y = y + t.height
        end
    else
        for _, index in ipairs(self._sortings[self._sort_mode].order) do
            local t = self._children[index]
            love.graphics.translate(x, y)
            t.child:draw()
            love.graphics.translate(-x, -y)

            y = y + t.height
        end
    end
    love.graphics.setScissor()
end

--- @overload rt.Widget.realize
function rt.ListView:realize()
    for _, t in pairs(self._children) do
        t.child:realize()
    end

    rt.Widget.realize(self)
end

