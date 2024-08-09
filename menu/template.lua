--- @class mn.Template
mn.Template = meta.new_type("MenuTemplate", function(name)
    meta.assert_string(name)
    return meta.new(mn.Template, {
        name = name,
        grabbed_object = nil,
        entities = {},
        created_on = os.date("%c")
    })
end)

--- @brief
function mn.Template:create_from(...)
    self.entities = {}
    for entity in range(...) do
        meta.assert_isa(entity, bt.Entity)
        self.entities[entity] = {
            moves = entity:list_move_slots(),
            n_move_slots = entity:get_n_move_slots(),

            equips = entity:list_equip_slots(),
            n_equip_slots = entity:get_n_equip_slots(),

            consumables = entity:list_consumable_slots(),
            n_consumable_slots = entity:get_n_consumable_slots()
        }
    end
end

--- @brief
function mn.Template:add_entity(entity)
    meta.assert_isa(entity, bt.Entity)
    self.entities[entity] = {
        moves = {},
        n_move_slots = entity:get_n_move_slots(),

        equips = {},
        n_equip_slots = entity:get_n_equip_slots(),

        consumables = {},
        n_consumable_slots = entity:get_n_consumable_slots()
    }
end

--- @brief
function mn.Template:copy_from(other)
    meta.assert_isa(other, mn.Template)
    for entity in keys(self.entities) do
        local other_setup = other.entities[entity]
        if other_setup ~= nil then
            local self_setup = self.entities[entity]
            assert(self_setup.n_move_slots == other_setup.n_move_slots and self_setup.n_equip_slots == other_setup.n_equip_slots and self_setup.n_consumable_slots == other_setup.n_consumable_slots)

            for i = 1, other_setup.n_move_slots do
                self_setup.moves[i] = other_setup.moves[i]
            end

            for i = 1, other_setup.n_equip_slots do
                self_setup.equips[i] = other_setup.equips[i]
            end

            for i = 1, other_setup.n_consumable_slots do
                self_setup.consumables[i] = other_setup.consumables[i]
            end
        end
    end
end

--- @brief
function mn.Template:get_sprite_id()
    return "orbs", "generic_overlay"
end

--- @brie
function mn.Template:get_name()
    return self.name
end

--- @brief
function mn.Template:set_name(name)
    self.name = name
end

--- @brief
function mn.Template:list_entities()
    local out = {}
    for entity in keys(self.entities) do
        table.insert(out, entity)
    end
    return out
end

--- @brief
function mn.Template:list_move_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    local setup = self.entities[entity]
    local out = {}
    for i = 1, setup.n_move_slots do
        out[i] = setup.moves[i]
    end
    return out, setup.n_move_slots
end

--- @brief
function mn.Template:list_consumable_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    local setup = self.entities[entity]
    local out = {}
    for i = 1, setup.n_consumable_slots do
        out[i] = setup.consumables[i]
    end
    return out, setup.n_consumable_slots
end

--- @brief
function mn.Template:list_equip_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    local setup = self.entities[entity]
    local out = {}
    for i = 1, setup.n_equip_slots do
        out[i] = setup.equips[i]
    end
    return out, setup.n_equip_slots
end

--- @brief
function mn.Template:get_id()
    return self:get_name()
end

--- @brief
function mn.Template:get_creation_date()
    return self.created_on
end