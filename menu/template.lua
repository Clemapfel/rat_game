--- @class mn.Template
mn.Template = meta.new_type("MenuTemplate", function(name)
    meta.assert_string(name)
    return meta.new(mn.Template, {
        _name = name,
        _equips = {},      -- Table<EntityID, EquipID>
        _consumables = {}, -- Table<EntityID, ConsumableID>
        _moves = {},       -- Table<EntityID, MoveID>
    })
end)

--- @brief
--- @param entities Table<bt.Entity>
function mn.Template:create_from(entities)
    self._moves = {}
    self._equips = {}
    self._consumables = {}
    for entity in values(entities) do
        local id = entity:get_id()

        local moves = {}
        for move in values(entity:list_moves()) do
            table.insert(moves, move:get_id())
        end
        self._moves[id] = moves

        local consumables = {}
        for consumable in values(entity:list_consumables()) do
            table.insert(consumables, consumable:get_id())
        end
        self._consumables[id] = consumables

        local equips = {}
        for equip in values(entity:list_equips()) do
            table.insert(equips, equip:get_id())
        end
        self._equips[id] = equips
    end
end

--- @brief
function mn.Template:serialize()
    local to_serialize = {
        moves = self._moves,
        consumables = self._consumables,
        equips = self._equips
    }

    return "return " .. serialize("", to_serialize)
end

--- @brief
function mn.Template:deserialize(str)
    local chunk, error_maybe = load(str)
    if error_maybe ~= nil then
        rt.error("In mn.Template.deserialize: error when loading string: " .. error_maybe)
        return
    end

    local out = chunk()

    local valid_keys = {
        ["moves"] = true,
        ["consumables"] = true,
        ["equips"] = true
    }

    for key in keys(out) do
        if valid_keys[key] ~= true then
            rt.error("In mn.Template.deserialize: error when loading table, unexpected key `" .. key .. "`")
            return
        end
    end

    self._moves = {}
    self._equips = {}
    self._consumables = {}

    for entity_id in keys(out.moves) do
        if self._moves[entity_id] == nil then self._moves[entity_id] = {} end
        for move_id in values(out.moves[entity_id]) do
            table.insert(self._moves[entity_id], move_id)
        end
    end

    for entity_id in keys(out.equips) do
        if self._equips[entity_id] == nil then self._equips[entity_id] = {} end
        for equip_id in values(out.equips[entity_id]) do
            table.insert(self._equips[entity_id], equip_id)
        end
    end

    for entity_id in keys(out.consumables) do
        if self._consumables[entity_id] == nil then self._consumables[entity_id] = {} end
        for consumable_id in values(out.consumables[entity_id]) do
            table.insert(self._consumables[entity_id], consumable_id)
        end
    end
end

--- @brief
function mn.Template:get_equips(entity)
    meta.assert_isa(entity, bt.Entity)
    local entity_id = entity:get_id()
    local out = {}
    for id in values(self._equips[entity_id]) do
        table.insert(out, bt.Equip(id))
    end
    return out
end

--- @brief
function mn.Template:get_consumables(entity)
    meta.assert_isa(entity, bt.Entity)
    local entity_id = entity:get_id()
    local out = {}
    for id in values(self._consumables[entity_id]) do
        table.insert(out, bt.Consumable(id))
    end
    return out
end

--- @brief
function mn.Template:get_moves(entity)
    meta.assert_isa(entity, bt.Entity)
    local entity_id = entity:get_id()
    local out = {}
    for id in values(self._moves[entity_id]) do
        table.insert(out, bt.Move(id))
    end
    return out
end
