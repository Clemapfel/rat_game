--- @class bt.ConsumableBar
bt.ConsumableBar = meta.new_type("ConsumableBar", rt.Widget, rt.Animation, function()
    return meta.new(bt.ConsumableBar, {
        _elements = {}, -- Table<cf. add>
        _box = rt.OrderedBox(),
        _opacity = 1,
    })
end)

--- @brief [internal]
function bt.ConsumableBar:_format_n_consumed(consumable, n_consumed)
    local max = consumable:get_max_n_uses()
    if max == POSITIVE_INFINITY then
        return ""
    else
        return "<o>" .. tostring(max - n_consumed) .. "</o>"
    end
end

--- @brief
function bt.ConsumableBar:add(consumable, elapsed)
    meta.assert_number(elapsed)

    if self._elements[consumable] ~= nil then
        self:set_n_consumed(consumable, elapsed)
        return
    end

    local to_insert = {
        element = rt.LabeledSprite(consumable:get_sprite_id()),
        elapsed = elapsed
    }

    to_insert.element:set_label(self:_format_n_consumed(consumable, elapsed))
    self._elements[consumable] = to_insert

    if self._is_realized == true then
        to_insert.element:realize()
        self._box:add(consumable, to_insert.element)
    end
end

--- @brief
function bt.ConsumableBar:remove(consumable)
    local entry = self._elements[consumable]
    if entry == nil then
        rt.warning("In bt.ConsumableBar.remove: trying to remove consumable `" .. consumable:get_id() .. "`, but consumable is not present in consumable bar")
        return
    end

    if self._is_realized == true then
        self._box:remove(consumable)
    end
    self._elements[consumable] = nil
end

--- @brief
function bt.ConsumableBar:activate(consumable)
    local entry = self._elements[consumable]
    if entry == nil then
        rt.warning("In bt.ConsumableBar.activate: trying to activate consumable `" .. consumable:get_id() .. "`, but consumable is not present in consumable bar")
        return
    end

    if self._is_realized == true then
        self._box:activate(consumable)
    end
end

--- @brief
function bt.ConsumableBar:synchronize(entity)
    local actually_present = {}
    for consumable in values(entity:list_consumables()) do
        actually_present[consumable] = true
    end

    local currently_present = {}
    for consumable in values(self._box:list_elements()) do
        currently_present[consumable] = true
    end

    -- remove
    for consumable in keys(currently_present) do
        if actually_present[consumable] ~= true then
            self:remove(consumable)
        end
    end

    -- add & update time
    for consumable in keys(actually_present) do
        local n_consumed = entity:get_consumable_n_consumed(consumable)
        if currently_present[consumable] ~= true then
            self:add(consumable, n_consumed)
        else
            self:set_n_consumed(consumable, n_consumed)
        end
    end
end

--- @brief
function bt.ConsumableBar:skip()
    self:update(60) -- finish all animations
end

--- @brief
function bt.ConsumableBar:set_n_consumed(consumable, n_consumed)
    local current = self._elements[consumable]
    if current == nil then
        self:add(consumable, n_consumed)
    end

    if current.elapsed ~= n_consumed then
        self._box:activate(consumable, function(sprite)
            sprite:set_label(self:_format_n_consumed(consumable, n_consumed))
        end)
    end
end

--- @override
function bt.ConsumableBar:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._box:realize()

    for entry in values(self._elements) do
        entry.element:realize()
        self._box:add(entry.element)
    end
end

--- @override
function bt.ConsumableBar:update(delta)
    if self._is_realized ~= true then return end
    self._box:update(delta)
end

--- @override
function bt.ConsumableBar:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    self._box:fit_into(x, y, width, height)
end

--- @override
function bt.ConsumableBar:draw()
    if self._is_realized ~= true then return end
    self._box:draw()
end

--- @brief
function bt.ConsumableBar:set_alignment(alignment)
    self._box:set_alignment(alignment)
end


--[[

--- @class bt.ConsumableBar
bt.ConsumableBar = meta.new_type("ConsumableBar", rt.Widget, rt.Animation, function()
    return meta.new(bt.ConsumableBar, {
        _elements = {}, -- Table<cf. add>
        _box = rt.OrderedBox(),
        _opacity = 1,
    })
end)

--- @brief [internal]
function bt.ConsumableBar:_format_n_consumed(consumable, n_consumed)
    local max = consumable:get_max_n_uses()
    if max == POSITIVE_INFINITY then
        return ""
    else
        return "<o>" .. tostring(max - n_consumed) .. "</o>"
    end
end

--- @brief
function bt.ConsumableBar:add(consumable, n_consumed)
    meta.assert_number(n_consumed)
    local to_insert = {
        element = rt.LabeledSprite(consumable:get_sprite_id()),
        n_consumed = n_consumed
    }

    to_insert.element:set_label(self:_format_n_consumed(consumable, n_consumed))
    self._elements[consumable] = to_insert

    if self._is_realized == true then
        to_insert.element:realize()
        self._box:add(consumable, to_insert.element)
    end
end

--- @brief
function bt.ConsumableBar:remove(consumable)
    local entry = self._elements[consumable]
    if entry == nil then
        rt.warning("In bt.ConsumableBar.remove: trying to remove consumable `" .. consumable:get_id() .. "`, but consumable is not present in consumable bar")
        return
    end

    if self._is_realized == true then
        self._box:remove(consumable)
    end
    self._elements[consumable] = nil
end

--- @brief
function bt.ConsumableBar:activate(consumable)
    local entry = self._elements[consumable]
    if entry == nil then
        rt.warning("In bt.ConsumableBar.activate: trying to activate consumable `" .. consumable:get_id() .. "`, but consumable is not present in consumable bar")
        return
    end

    if self._is_realized == true then
        self._box:activate(consumable)
    end
end

--- @brief
function bt.ConsumableBar:set_n_consumed(consumable, n_consumed)
    self._box:activate(consumable, function(sprite)
        sprite:set_label(self:_format_n_consumed(consumable, n_consumed))
    end)
end

--- @brief
function bt.ConsumableBar:synchronize(entity)
    self._box:clear()
    for consumable in values(entity:list_consumables()) do
        self:add(consumable, entity:get_consumable_n_consumed(consumable))
    end
end

--- @override
function bt.ConsumableBar:realize()
    if self._is_realized == true then return end
    self._is_realized = true
    self._box:realize()

    for entry in values(self._elements) do
        entry.element:realize()
        self._box:add(entry.element)
    end
end

--- @override
function bt.ConsumableBar:update(delta)
    if self._is_realized ~= true then return end
    self._box:update(delta)
end

--- @override
function bt.ConsumableBar:size_allocate(x, y, width, height)
    if self._is_realized ~= true then return end
    self._box:fit_into(x, y, width, height)
end

--- @override
function bt.ConsumableBar:draw()
    if self._is_realized ~= true then return end
    self._box:draw()
end

--- @brief
function bt.ConsumableBar:set_alignment(alignment)
    self._box:set_alignment(alignment)
end
]]--