--- @class bt.ConsumableBar
bt.ConsumableBar = meta.new_type("ConsumableBar", rt.Widget, rt.Animation, function()
    return meta.new(bt.ConsumableBar, {
        _elements = {}, -- Table<cf. add>
        _box = rt.OrderedBox(),
        _opacity = 1,
    })
end)

--- @brief [internal]
function bt.ConsumableBar:_format_n_uses(consumable, n_consumed)
    local max = consumable:get_max_n_uses()
    if max == POSITIVE_INFINITY then
        return ""
    else
        return "<o>" .. tostring(max - n_consumed) .. "</o>"
    end
end

--- @brief
function bt.ConsumableBar:add(consumable, n_consumed)
    local to_insert = {
        element = rt.LabeledSprite(consumable:get_sprite_id()),
        n_consumed = n_consumed
    }

    to_insert.element:set_label(self:_format_n_uses(consumable, n_consumed))
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
