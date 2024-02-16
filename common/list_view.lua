rt.settings.list_view.default_sort_mode_id = "default"
rt.settings.list_view.scrollbar_width = rt.settings.margin_unit

--- @class rt.ListView
rt.ListView = meta.new_type("ListView", rt.Widget, function()
    return meta.new(rt.ListView, {
        _children = {}, -- child_hash -> rt.Widget
        _children_hash = 0,
        _area = rt.AABB(0, 0, 0, 0),
        _sort_mode = rt.settings.list_view.default_sort_mode_id,
        _sortings = {},  -- name -> {comparator, order}
    })
end)

--- @brief [internal]
function rt.ListView:_regenerate_sorting(name)
    self._sortings[name].order = {}
    local to_sort = self._sortings[name].order
    local comp = self._sortings[name].comparator

    for i, _ in pairs(self._children) do
        table.insert(to_sort, i)
    end

    table.sort(to_sort, function(x, y)
        local left = self._children[x]
        local right = self._children[y]
        return try_catch(function()
            local out = comp(left, right)

            return out
        end, function(error)
            rt.error("In ListView:_regenerate_sorting: comparator for sort mode `" .. name .. "` failed for widgets `" .. tostring(meta.typeof(left)) .. "`, `" .. tostring(meta.typeof(right)) .. "`: " .. error)
        end)
    end)
end

--- @brief
function rt.ListView:add_sort_mode(name, comparator)
    self._sortings[name] = {
        comparator = comparator,
        order = {}
    }
end

--- @brief
function rt.ListView:set_sort_mode(name)
    if meta.is_nil(self._sortings[name]) then
        rt.error("In rt.ListView.set_sort_mode: no sort mode `" .. name .. "` registered")
    end

    if self._sort_mode ~= name then
        self._sort_mode = name
        if #self._sortings[name].order ~= #self._children then
            self:_regenerate_sorting(name)
        end
        self:reformat()
    end
end

--- @brief
function rt.ListView:get_sort_mode()
    return self._sort_mode
end

--- @brief
function rt.ListView:push_back(child)
    self._children[self._children_hash] = child
    self._children_hash = self._children_hash + 1

    if self:get_is_realized() then
        child:realize()
        self:reformat()
    end
end

--- @overlad rt.Widget.size_allocate
function rt.ListView:size_allocate(x, y, width, height)
    local child_y = y
    if self._sort_mode == rt.settings.list_view.default_sort_mode_id then
        for _, child in pairs(self._children) do
            local w, h = child:measure()
            child:fit_into(rt.AABB(x, child_y, width, h))
            child_y = child_y + h
        end
    else
        for _, index in pairs(self._sortings[self._sort_mode].order) do
            local child = self._children[index]
            local w, h = child:measure()
            child:fit_into(rt.AABB(x, child_y, width, h))
            child_y = child_y + h
        end
    end
end

--- @overload rt.Drawable.draw
function rt.ListView:draw()
    if self:get_is_visible() then
        for _, child in pairs(self._children) do
            child:draw()
        end
    end
end

--- @overload rt.Widget.realize
function rt.ListView:realize()
    for _, child in pairs(self._children) do
        child:realize()
    end

    rt.Widget.realize(self)
end
