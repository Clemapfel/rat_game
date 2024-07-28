--- @class mn.Template
mn.Template = meta.new_type("MenuTemplate", function(name)
    meta.assert_string(name)
    return meta.new(mn.Template, {
        _name = name,
        _entities = {}, -- Table<EntityID, {equips, consumables, moves}>
    })
end)

--- @brief
--- @param entities Table<bt.Entity>
function mn.Template:create_from(entities)
    self._entities = {}
    for entity in values(entities) do
        local id = entity:get_id()

        local moves = {}
        for move in values(entity:list_moves()) do
            table.insert(moves, move:get_id())
        end

        local consumables = {}
        for consumable in values(entity:list_consumables()) do
            table.insert(consumables, consumable:get_id())
        end

        local equips = {}
        for equip in values(entity:list_equips()) do
            table.insert(equips, equip:get_id())
        end

        self._entities[entity:get_id()] = {
            moves = moves,
            consumables = consumables,
            equips = equips
        }
    end
end

--- @brief
function mn.Template:list_equips(entity)
    meta.assert_isa(entity, bt.Entity)
    local entity_id = entity:get_id()
    local out = {}
    for id in values(self._entities[entity_id].equips) do
        table.insert(out, bt.Equip(id))
    end
    return out
end

--- @brief
function mn.Template:list_consumables(entity)
    meta.assert_isa(entity, bt.Entity)
    local entity_id = entity:get_id()
    local out = {}
    for id in values(self._entities[entity_id].consumables) do
        table.insert(out, bt.Consumable(id))
    end
    return out
end

--- @brief
function mn.Template:list_moves(entity)
    meta.assert_isa(entity, bt.Entity)
    local entity_id = entity:get_id()
    local out = {}
    for id in values(self._entities[entity_id].moves) do
        table.insert(out, bt.Move(id))
    end
    return out
end

--- @brief
function mn.Template:has_entity(entity)
    return self._entities[entity:get_id()] ~= nil
end
