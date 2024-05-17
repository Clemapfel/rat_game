--- @class bt.StatusBar
bt.StatusBar = meta.new_type("StatusBar", rt.Widget, rt.Animation, function()
    return meta.new(bt.StatusBar, {
        _elements = {}, -- Table<cf. add>
        _box = rt.OrderedBox(),
        _opacity = 1,
    })
end)

--- @brief [internal]
function bt.StatusBar:_format_elapsed(status, elapsed)
    local max = status:get_max_duration()
    if max == POSITIVE_INFINITY then
        return ""
    else
        return "<o>" .. tostring(max - elapsed) .. "</o>"
    end
end

--- @brief
function bt.StatusBar:add(status, elapsed)
    local to_insert = {
        element = rt.LabeledSprite(status:get_sprite_id()),
        elapsed = elapsed
    }

    to_insert.element:set_label(self:_format_elapsed(status, elapsed))
    self._elements[status] = to_insert

    if self._is_realized == true then
        to_insert.element:realize()
        self._box:add(status, to_insert.element)
    end
end

--- @brief
function bt.StatusBar:remove(status)
    local entry = self._elements[status]
    if entry == nil then
        rt.warning("In bt.StatusBar.remove: trying to remove status `" .. status:get_id() .. "`, but status is not present in status bar")
        return
    end

    if self._is_realized == true then
        self._box:remove(status)
    end
    self._elements[status] = nil
end

--- @brief
function bt.StatusBar:activate(status)
    local entry = self._elements[status]
    if entry == nil then
        rt.warning("In bt.StatusBar.activate: trying to activate status `" .. status:get_id() .. "`, but status is not present in status bar")
        return
    end

    if self._is_realized == true then
        self._box:activate(status)
    end
end

--- @brief
function bt.StatusBar:synchronize(entity)
    self._box:clear()
    for status in values(entity:list_statuses()) do
        if status:get_is_silent() == false then
            self:add(status, entity:get_status_n_turns_elapsed(status))
        end
    end
end

--- @override
function bt.StatusBar:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._box:realize()

    for entry in values(self._elements) do
        entry.element:realize()
        self._box:add(entry.element)
    end
end

--- @override
function bt.StatusBar:update(delta)
    if self._is_realized ~= true then return end
    self._box:update(delta)
end

--- @override
function bt.StatusBar:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    self._box:fit_into(x, y, width, height)
end

--- @override
function bt.StatusBar:draw()
    if self._is_realized ~= true then return end
    self._box:draw()
end

--- @brief
function bt.StatusBar:set_alignment(alignment)
    self._box:set_alignment(alignment)
end
