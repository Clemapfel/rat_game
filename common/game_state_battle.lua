--[[
    entity_id_to_multiplicity[entity_id] = count,
    entity_id_to_index[entity_id] = index,
    n_allies = 0
    n_enemies = 0

    entities = {
        id       -- EntityID
        hp       -- Unsigned
        state    -- bt.EntityState
        index    -- Unsigned
        priority -- Signed

        storage = {}, -- Table<String, Any>
        
        moves[slot_i] = {
            id  -- MoveID
            n_used
            is_disabled = false,
            storage = {}
        }

        intrinsic_moves = {
            id,
            storage = {}
        }

        equips[slot_i] = {
            id  -- EquipID
            is_disabled = false,
            storage = {}
        }

        consumables[slot_i] = {
            id  -- ConsumableID
            n_used
            is_disabled = false,
            storage = {}
        }

        statuses = {
            id,
            n_turns_elapsed,
            storage = {}
        }
    }

    global_statuses = {
        id,
        n_turns_elapsed,
        storage = {}
    }

    shared_moves[move_id] = {
        count
    }

    shared_equips[equip_id] = {
        count
    }

    shared_consumables[equip_id] = {
    }

    template_id_counter -- Unsigned
    templates = {
        name    -- String
        date    -- UnixTimestamp
        entities[config_id] = {
            n_move_slots
            moves[slot_i] = MoveID

            n_consumable_slots
            consumables[slot_i] = ConsumableID

            n_equip_slots
            equips[slot_i] = EquipID
        }
    }
]]--

--- @brief
function rt.GameState:add_entity(entity)
    meta.assert_isa(entity, bt.Entity)

    local state = self._state

    if entity:get_is_enemy() then
        state.n_enemies = state.n_enemies + 1
    else
        state.n_allies = state.n_allies + 1
    end

    local n_moves = entity:get_n_move_slots()
    local n_equips = entity:get_n_equip_slots()
    local n_consumables = entity:get_n_consumable_slots()
    local to_add = {
        index = -1,
        hp = -1,
        id = "",
        state = bt.EntityState.ALIVE,
        moves = {},
        equips = {},
        consumables = {},
        statuses = {},
        intrinsic_moves = {},
        storage = {}
    }

    for i = 1, n_moves do
        to_add.moves[i] = {
            id = "",
            n_used = 0,
            is_disabled = false,
            storage = {}
        }
    end

    for i = 1, n_equips do
        to_add.equips[i] = {
            id = "",
            is_disabled = false,
            storage = {}
        }
    end

    for i = 1, n_consumables do
        to_add.consumables[i] = {
            id = "",
            n_used = 0,
            is_disabled = false,
            storage = {}
        }
    end

    for id in values(entity:list_intrinsic_move_ids()) do
        table.insert(to_add.intrinsic_moves, id)
    end

    if entity:get_is_enemy() then
        to_add.index = state.n_enemies
    else
        to_add.index = state.n_allies
    end

    table.insert(state.entities, to_add)

    local config_id = entity:get_config_id()
    local current_multiplicity = state.entity_id_to_multiplicity[config_id]
    if state.entity_id_to_multiplicity[config_id] == nil then
        current_multiplicity = 0
    end
    current_multiplicity = current_multiplicity + 1
    state.entity_id_to_multiplicity[config_id] = current_multiplicity

    entity:update_id_from_multiplicity(current_multiplicity)
    local count = sizeof(state.entities)
    state.entity_id_to_index[entity:get_id()] = count
    to_add.hp = entity:get_hp_base()
    to_add.id = entity:get_id()

    self._entity_index_to_entity[count] = entity
    self._entity_to_entity_index[entity] = count
end

--- @brief
function rt.GameState:remove_entity(entity)
    meta.assert_isa(entity, bt.Entity)

    local state = self._state
    if state.entities[entity:get_id()] == nil then
        rt.error("In rt.GameState:entity_remove: trying to remove entity `" .. entity:get_id() .. "`, but entity was not yet added to game state")
        return
    end

    if entity:get_is_enemy() then
        state.n_enemies = state.n_enemies - 1
    else
        state.n_allies = state.n_allies - 1
    end

    state.entities[entity:get_id()] = nil
    -- do not reset multiplicity
end

--- @brief
function rt.GameState:list_entities()
    local out = {}
    for i, entity in ipairs(self._entity_index_to_entity) do
        table.insert(out, entity)
    end
    return out
end

--- @brief
function rt.GameState:list_entities_in_order()
    local out = self:list_entities()
    table.sort(out, function(a, b)
        if a:get_priority() == b:get_priority() then
            if a:get_speed() == b:get_speed() then
                return a:get_name() < b:get_name()
            else
                return a:get_speed() > b:get_speed()
            end
        else
            return a:get_priority() > b:get_priority()
        end
    end)
    return out
end

--- @brief
function rt.GameState:list_allies()
    local out = {}
    for i, entity in ipairs(self._entity_index_to_entity) do
        if entity:get_is_enemy() == false then
            table.insert(out, entity)
        end
    end
    return out
end

--- @brief
function rt.GameState:list_enemies()
    local out = {}
    for i, entity in ipairs(self._entity_index_to_entity) do
        if entity:get_is_enemy() == true then
            table.insert(out, entity)
        end
    end
    return out
end

--- @brief
function rt.GameState:get_n_entities()
    return self._state.n_allies + self._state.n_enemies
end

--- @brief
function rt.GameState:get_n_allies()
    return self._state.n_allies
end

--- @brief
function rt.GameState:get_n_enemies()
    return self._state.n_enemies
end

--- @brief
function rt.GameState:entity_get_multiplicity(entity)
    meta.assert_isa(entity, bt.Entity)

    local current_multiplicity = self._state.entity_id_to_multiplicity[entity:get_id()]
    if current_multiplicity == nil then
        return 0
    else
        return current_multiplicity
    end
end

--- @brief
function rt.GameState:entity_get_priority(entity)
    meta.assert_isa(entity, bt.Entity)
    return self:_get_entity_entry(entity).priority
end

--- @brie
--- @return Boolean, Unsigned is_stunned, number of turns left
function rt.GameState:entity_get_is_stunned(entity)
    meta.assert_isa(entity, bt.Entity)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_is_stunned: entity `" .. entity:get_id() .. "` is not part of state")
        return {}
    end

    local is_stunned = false
    local max_n_turns = 0
    for id, n_turns_elapsed in pairs(entry.statuses) do
        local status = bt.Status(id)
        if status:get_is_stun() then
            is_stunned = true
            max_n_turns = math.max(max_n_turns, status:get_max_duration() - n_turns_elapsed)
        end
    end

    return is_stunned, max_n_turns
end

--- @brief
function rt.GameState:_get_entity_entry(entity)
    return self._state.entities[self._state.entity_id_to_index[entity:get_id()]]
end

--- @brief
function rt.GameState:_entity_id_to_entity(id)
    local index = self._state.entity_id_to_index[id]
    if index == nil then return nil end
    return self._entity_index_to_entity[index]
end

--- @brief
function rt.GameState:entity_get_party_index(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_party_index: entity `" .. entity:get_id() .. "` is not part of state")
        return -1
    end
    return entry.index
end

--- @brief
function rt.GameState:entity_get_hp(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_hp: entity `" .. entity:get_id() .. "` is not part of state")
        return 0
    end

    return entry.hp
end

--- @brief
function rt.GameState:entity_set_hp(entity, new_hp)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_number(new_hp)
    
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_hp: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    if new_hp < 0 then
        rt.error("In rt.GameState:entity_set_hp: hp value `" .. new_hp .. "` is invalid")
    end

    entry.hp = math.ceil(new_hp)
end

--- @brief
function rt.GameState:entity_set_state(entity, new_state)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_enum_value(new_state, bt.EntityState)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_state: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    entry.state = new_state
end

function rt.GameState:entity_get_state(entity)
    meta.assert_isa(entity, bt.Entity)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_state: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    return entry.state
end

for which in range("move", "equip", "consumable") do
    local Type
    if which == "move" then
        Type = bt.Move
    elseif which == "equip" then
        Type = bt.Equip
    elseif which == "consumable" then
        Type = bt.Consumable
    end

    --- @brief entity_list_moves, entity_list_equips, entity_list_consumables
    rt.GameState["entity_list_" .. which .. "s"] = function(self, entity)
        meta.assert_isa(entity, bt.Entity)

        local entry = self:_get_entity_entry(entity)
        if entry == nil then 
            rt.error("In rt.GameState:entity_list_" .. which .."s: entity `" .. entity:get_id() .. "` is not part of state")
            return {} 
        end

        local out = {}
        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        for slot_i = 1, n_slots do
            local id = entry[which .. "s"][slot_i].id
            if id ~= "" then
                table.insert(out, Type(id))
            end
        end
        return out
    end

    --- @brief entity_list_move_slots, entity_list_equip_slots, entity_list_consumable_slots
    --- @return Unsigned, Table<*>
    rt.GameState["entity_list_" .. which .. "_slots"] = function(self, entity)
        meta.assert_isa(entity, bt.Entity)

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_list_" .. which .."s: entity `" .. entity:get_id() .. "` is not part of state")
            return {}
        end

        local out = {}
        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        for slot_i = 1, n_slots do
            local id = entry[which .. "s"][slot_i].id
            if id ~= "" then
                out[slot_i] = Type(id)
            end
        end
        return n_slots, out
    end

    --- @brief entity_get_move, entity_get_equip, entity_get_consumable
    rt.GameState["entity_get_" .. which] = function(self, entity, slot_i)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)

        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots then
            rt.error("In rt.GameState:entity_add_" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
            return nil
        end

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_get_" .. which ..": entity `" .. entity:get_id() .. "` is not part of state")
            return nil
        end

        local id = entry[which .. "s"][slot_i].id
        if id == "" then
            return nil
        else
            return Type(id)
        end
    end

    --- @brief entity_get_first_free_move_slot, entity_get_first_free_equip_slot, entity_get_first_free_consumable_slot
    rt.GameState["entity_get_first_free_" .. which .. "_slot"] = function(self, entity)
        meta.assert_isa(entity, bt.Entity)

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_get_first_free_" .. which .."_slot: entity `" .. entity:get_id() .. "` is not part of state")
            return nil
        end

        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        local slots = entry[which .. "s"]
        for i = 1, n_slots do
            if slots[i].id == "" then return i end
        end

        return nil
    end

    --- @brief entity_add_move, entity_add_equip, entity_add_consumable
    rt.GameState["entity_add_" .. which] = function(self, entity, slot_i, object)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_isa(object, Type)
        meta.assert_number(slot_i)

        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots then
            rt.error("In rt.GameState:entity_add_" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
            return
        end

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_add_" .. which ..": entity `" .. entity:get_id() .. "` is not part of state")
            return
        end

        local object_entry = entry[which .. "s"][slot_i]
        object_entry.id = object:get_id()
        object_entry.storage = {}

        if object_entry.n_used ~= nil then
            object_entry.n_used = 0
        end
    end

    --- @brief entity_remove_move, entity_remove_equip, entity_remove_consumable
    rt.GameState["entity_remove_" .. which] = function(self, entity, slot_i)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)

        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots then
            rt.error("In rt.GameState:entity_remove_" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
            return
        end

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_remove_" .. which ..": entity `" .. entity:get_id() .. "` is not part of state")
            return 
        end

        local object_entry = entry[which .. "s"]
        local current_id = object_entry[slot_i].id
        object_entry[slot_i].id = ""
        object_entry[slot_i].storage = {}

        if object_entry.n_used ~= nil then
            object_entry.n_used = 0
        end

        if current_id == "" then return nil else return Type(current_id) end
    end

    --- @brief entity_has_move, entity_has_equip, entity_has_consumable
    rt.GameState["entity_has_" .. which] = function(self, entity, object)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_isa(object, Type)

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_has_" .. which ..": entity `" .. entity:get_id() .. "` is not part of state")
            return
        end
        local slots = entry[which .. "s"]
        local n_slots = entity["get_n_" .. which .. "_slots"](entity)

        for i = 1, n_slots do
            if slots[i].id == object:get_id() then
                return true
            end
         end

        return false
    end

    --- @brief entity_get_move_slot_i, entity_get_equip_slot_i, entity_get_consumable_slot_i
    rt.GameState["entity_get_" .. which .. "_slot_i"] = function(self, entity, object)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_isa(object, Type)

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_has_" .. which ..": entity `" .. entity:get_id() .. "` is not part of state")
            return
        end
        local slots = entry[which .. "s"]
        local n_slots = entity["get_n_" .. which .. "_slots"](entity)

        local out = {}
        for i = 1, n_slots do
            if slots[i].id == object:get_id() then
                table.insert(out, i)
            end
        end

        return table.unpack(out)
    end

    if which == "move" or which == "consumable" then
        --- @brief entity_get_move_n_used, entity_get_consumable_n_used
        rt.GameState["entity_get_" .. which .. "_n_used"] = function(self, entity, slot_i)
            meta.assert_isa(entity, bt.Entity)
            meta.assert_number(slot_i)

            local n_slots = entity["get_n_" .. which .. "_slots"](entity)
            if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots then
                rt.error("In rt.GameState:entity_" .. which .. "_get_n_used" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
                return 0
            end

            local entry = self:_get_entity_entry(entity)
            if entry == nil then
                rt.error("In rt.GameState:entity_" .. which .."_get_n_used: entity `" .. entity:get_id() .. "` is not part of state")
                return 0
            else
                return entry[which .. "s"][slot_i].n_used
            end
        end

        --- @brief entity_increase_move_n_used, entity_increase_consumable_n_used
        rt.GameState["entity_increase_" .. which .. "_n_used"] = function(self, entity, slot_i)
            meta.assert_isa(entity, bt.Entity)

            local n_slots = entity["get_n_" .. which .. "_slots"](entity)
            if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots() then
                rt.error("In rt.GameState:entity_" .. which .. "_get_n_used" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
                return
            end

            local entry = self:_get_entity_entry(entity)
            if entry == nil then
                rt.error("In rt.GameState:entity_" .. which .."_increase_n_used: entity `" .. entity:get_id() .. "` is not part of state")
                return 
            end
            entry[which .. "s"].n_used = entry[which .. "s"].n_used + 1
        end

        --- @brief entity_set_move_n_used, entity_set_consumable_n_used
        rt.GameState["entity_set_" .. which .. "_n_used"] = function(self, entity, object, n)

        end
    end

    --- @brief list_shared_moves, list_shared_equips, list_shared_consumables
    rt.GameState["list_shared_" .. which .. "s"] = function(self)
        local out = {}
        local entries = self._state["shared_" .. which .. "s"]
        for id, entry in pairs(entries) do
            table.insert(out, Type(id))
        end
        return out
    end

    --- @brief list_shared_move_quantities, list_shared_equip_quantities, list_shared_consumable_quantities
    rt.GameState["list_shared_" .. which .. "_quantities"] = function(self)
        local out = {}
        local entries = self._state["shared_" .. which .. "s"]
        for id, entry in pairs(entries) do
            out[Type(id)] = entry.count
        end
        return out
    end

    --- @brief get_shared_move_count, get_shared_equip_count, get_shared_consumable_count
    rt.GameState["get_shared_" .. which .. "_count"] = function(self, object)
        meta.assert_isa(object, Type)
        local item = self._state["shared_" .. which .. "s"]
        if item == nil then
            return item[object:get_id()]
        else
            return 0
        end
    end

    --- @brief add_shared_move, add_shared_equip, add_shared_consumable
    rt.GameState["add_shared_" .. which] = function(self, object)
        meta.assert_isa(object, Type)

        local entry = self._state["shared_" .. which .. "s"][object:get_id()]
        if entry == nil then
            entry = {
                count = 1
            }
            self._state["shared_" .. which .. "s"][object:get_id()] = entry
        else
            entry.count = entry.count + 1
        end
    end

    --- @brief remove_shared_move, remove_shared_equip, remove_shared_consumable
    rt.GameState["remove_shared_" .. which] = function(self, object)
        meta.assert_isa(object, Type)

        local entry = self._state["shared_" .. which .. "s"][object:get_id()]
        if entry == nil then
            rt.error("In rt.GameState:remove_shared_" .. which .. ": " .. meta.typeof(object) .. " `" .. object:get_id() .. "` is not present in shared inventory")
            return
        end

        entry.count = entry.count - 1
        if entry.count == 0 then
            self._state["shared_" .. which .. "s"][object:get_id()] = nil
        end
    end

    --- @brief get_shared_move_count, get_shared_equip_count, get_shared_consumable_count
    rt.GameState["get_shared_" .. which .. "_count"] = function(self, object)
        meta.assert_isa(object, Type)

        local entry = self._state["shared_" .. which .. "s"][object:get_id()]
        if entry == nil then
            return 0
        else
            return entry.count
        end
    end
end

for which_type in range(
    {"move", bt.Move},
    {"equip", bt.Equip},
    {"consumable", bt.Consumable}
) do
    local which, type = table.unpack(which_type)
    --- @brief entity_get_move_is_disabled, entity_get_equip_is_disabled, entity_get_consumable_is_disabled
    rt.GameState["entity_get_" .. which .. "_is_disabled"] = function(self, entity, slot_i)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)

        local entity_entry = self:_get_entity_entry(entity)
        if entity_entry == nil then
            rt.error("In rt.GameState:entity_get_is_" .. which .. "_disabled: entity `" .. entity:get_id() .. "` is not part of state")
            return
        end

        local object_entry = entity_entry[which .. "s"][slot_i]
        if object_entry == nil or object_entry.id == nil then
            rt.error("In rt.GameState:entity_get_is_" .. which .. "_disabled: entity `" .. entity:get_id() .. "` has no consumable in slot `" .. slot_i .. "`")
            return
        end

        return object_entry.is_disabled
    end

    --- @brief entity_set_move_is_disabled, entity_set_equip_is_disabled, entity_set_consumable_is_disabled
    rt.GameState["entity_set_" .. which .. "_is_disabled"] = function(self, entity, slot_i, b)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)
        meta.assert_boolean(b)

        local entity_entry = self:_get_entity_entry(entity)
        if entity_entry == nil then
            rt.error("In rt.GameState:entity_set_is_" .. which .. "_disabled: entity `" .. entity:get_id() .. "` is not part of state")
            return
        end

        local object_entry = entity_entry[which .. "s"][slot_i]
        if object_entry == nil or object_entry.id == nil then
            rt.error("In rt.GameState:entity_set_is_" .. which .. "_disabled: entity `" .. entity:get_id() .. "` has no consumable in slot `" .. slot_i .. "`")
            return
        end

        object_entry.is_disabled = b
    end
end

--- @brief
function rt.GameState:entity_set_storage_value(entity, id, new_value)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_string(id)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    entry.storage[id] = new_value
end

--- @brief
function rt.GameState:entity_get_storage_value(entity, id)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_string(id)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    return entry.storage[id]
end

--- @brief
function rt.GameState:entity_replace_storage_value(entity, new_table)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_table(new_table)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    entry.storage = new_table
end

--- @brief
function rt.GameState:entity_list_intrinsic_moves(entity)
    meta.assert_isa(entity, bt.Entity)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_list_intrinsic_moves: entity `" .. entity:get_id() .. "` is not part of state")
        return {}
    end

    local out = {}
    for move_id in values(entry.intrinsic_moves) do
        table.insert(out, bt.Move(move_id))
    end

    return out
end

--- @brief
--- @return Number, Number, Number, Number
function rt.GameState:entity_preview_equip(entity, slot_i, new_equip)

    local previous = self:entity_get_equip(entity, slot_i)

    if new_equip == nil then
        self:entity_remove_equip(entity, slot_i)
    else
        self:entity_add_equip(entity, slot_i, new_equip)
    end

    local hp, attack, defense, speed = entity:get_hp(), entity:get_attack_current(), entity:get_defense_current(), entity:get_speed_current()

    self:entity_remove_equip(entity, slot_i)
    if previous ~= nil then
        self:entity_add_equip(entity, slot_i, previous)
    end

    return hp, attack, defense, speed
end

--- @brief
function rt.GameState:add_shared_object(object)
    if meta.isa(object, bt.Move) then
        self:add_shared_move(object)
    elseif meta.isa(object, bt.Equip) then
        self:add_shared_equip(object)
    elseif meta.isa(object, bt.Consumable) then
        self:add_shareD_consumable(object)
    else
        rt.error("In rt.GameState:add_shared_object: object `" .. meta.typeof(object) .. "` is not a bt.Move, bt.Equip, or bt.Consumable")
    end
end

--- @brief
function rt.GameState:entity_sort_inventory(entity)
    meta.assert_isa(entity, bt.Entity)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_sort_inventory: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    local moves = {}
    local equips = {}
    local consumables = {}

    local n_move_slots, n_equip_slots, n_consumable_slots = entity:get_n_move_slots(), entity:get_n_equip_slots(), entity:get_n_consumable_slots()
    for i = 1, n_move_slots do
        local id = entry.moves[i].id
        if id ~= "" then
            local move = bt.Move(id)
            table.insert(moves, move)
            self:entity_remove_move(entity, i)
        end
    end

    for i = 1, n_equip_slots do
        local id = entry.equips[i].id
        if id ~= "" then
            local equip = bt.Equip(id)
            table.insert(equips, equip)
            self:entity_remove_equip(entity, i)
        end
    end

    for i = 1, n_consumable_slots do
        local id = entry.consumables[i].id
        if id ~= "" then
            local consumable = bt.Consumable(id)
            table.insert(consumables, consumable)
            self:entity_remove_consumable(entity, i)
        end
    end

    for i, move in ipairs(moves) do
        self:entity_add_move(entity, i, move)
    end

    for i, equip in ipairs(equips) do
        self:entity_add_equip(entity, i, equip)
    end

    for i, consumable in ipairs(consumables) do
        self:entity_add_consumable(entity, i, consumable)
    end

    return moves, equips, consumables
end

--- @brief
function rt.GameState:entity_add_status(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_add_status: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    entry.statuses[status:get_id()] = {
        n_turns_elapsed = 0,
        storage = {}
    }
end

--- @brief
function rt.GameState:entity_has_status(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_has_status: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    return entry.statuses[status:get_id()] ~= nil
end

--- @brief
--- @return Table<bt.Status>
function rt.GameState:entity_list_statuses(entity)
    meta.assert_isa(entity, bt.Entity)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_list_statuses: entity `" .. entity:get_id() .. "` is not part of state")
        return {}
    end

    local out = {}
    for id, _ in pairs(entry.statuses) do
        table.insert(out, bt.Status(id))
    end
    return out
end

--- @brief
function rt.GameState:entity_get_status_n_turns_elapsed(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_status_n_turns_elapsed: entity `" .. entity:get_id() .. "` is not part of state")
        return 0
    end

    local item = entry.statuses[status:get_id()]
    if item == nil then return 0 end
    return item.n_turns_elapsed
end

--- @brief
function rt.GameState:entity_set_status_n_turns_elapsed(entity, status, n_turns)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)
    meta.assert_unsigned(n_turns)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_status_n_turns_elapsed: entity `" .. entity:get_id() .. "` is not part of state")
        return 0
    end

    local item = entry.statuses[status:get_id()]
    if item == nil then
        rt.error("In rt.GameState:entity_set_status_n_turns_elapsed: entity `" .. entity:get_id() .. "` has no status `" .. status:get_id() .. "`")
        return 0
    end

    item.n_turns_elapsed = clamp(n_turns, 0, status:get_max_duration())
end

--- @brief
function rt.GameState:entity_has_status(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_has_status: entity `" .. entity:get_id() .. "` is not part of state")
        return false
    end

    return entry.statuses[status:get_id()] ~= nil
end

--- @brief
function rt.GameState:entity_remove_status(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_remove_status: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    entry.statuses[status:get_id()] = nil
end

--- @brief
function rt.GameState:add_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    self._state.global_statuses[global_status:get_id()] = {
        n_turns_elapsed = 0,
        storage = {}
    }
end

--- @brief
function rt.GameState:remove_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    local entry = self._state.global_statuses[global_status:get_id()]

    if entry == nil then
        rt.error("In rt.GameState:remove_global_status: status `" .. global_status:get_id() .. "` is not present")
        return
    end

    self._state.global_statuses[global_status:get_id()] = nil
end

--- @brief
function rt.GameState:has_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    return self._state.global_statuses[global_status:get_id()] ~= nil
end

--- @brief
function rt.GameState:list_global_statuses()
    local out = {}
    for id in keys(self._state.global_statuses) do
        table.insert(out, bt.GlobalStatus(id))
    end
    return out
end

--- @brief
function rt.GameState:get_global_status_n_turns_elapsed(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    local entry = self._state.global_statuses[global_status:get_id()]
    if entry == nil then
        return 0
    else
        return entry.n_turns_elapsed
    end
end

--- @brief
function rt.GameState:set_global_status_n_turns_elapsed(global_status, n_turns)
    meta.assert_isa(global_status, bt.GlobalStatus)
    meta.assert_unsigned(n_turns)

    local entry = self._state.global_statuses[global_status:get_id()]
    if entry == nil then
        rt.error("In rt.GameState.set_global_status_n_turns_elapsed: global status `" .. global_status:get_id() .. "` is not present")
        return 0
    end

    entry.n_turns_elapsed = clamp(n_turns, 0, global_status:get_max_duration())
end

--- @brief
function rt.GameState:has_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatus)
    return self._state.global_statuses[global_status:get_id()] ~= nil
end

--- @brief
function rt.GameState:entity_set_status_storage_value(entity, status, id, new_value)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)
    meta.assert_string(id)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    local status_entry = entry.statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:entity_set_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    status_entry.storage[id] = new_value
end

--- @brief
function rt.GameState:entity_get_status_storage_value(entity, status, id)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.Status)
    meta.assert_string(id)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    local status_entry = entry.statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:entity_set_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    return status_entry.storage[id]
end

--- @brief
function rt.GameState:entity_replace_status_storage(entity, new_table)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_table(new_table)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_set_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    local status_entry = entry.statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:entity_set_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    status_entry.storage = new_table
end

--- @brief
function rt.GameState:set_global_status_storage_value(status, id, new_value)
    meta.assert_isa(status, bt.GlobalStatus)
    meta.assert_string(id)

    local status_entry = self._state.global_statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:set_global_status_storage_value: global status `" .. status:get_id() .. "` is not present")
        return nil
    end

    status_entry.storage[id] = new_value
end

--- @brief
function rt.GameState:get_global_status_storage_value(status, id, new_value)
    meta.assert_isa(status, bt.GlobalStatus)
    meta.assert_string(id)

    local status_entry = self._state.global_statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:set_global_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    return status_entry.storage[id]
end

--- @brief
function rt.GameState:replace_global_status_storage(status, new_table)
    meta.assert_isa(status, bt.GlobalStatus)
    meta.assert_table(new_table)

    local status_entry = self._state.global_statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:set_global_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    status_entry.storage = new_table
end

for which_type in range(
    {"move", bt.Move},
    {"equip", bt.Equip},
    {"consumable", bt.Consumable}
) do
    local which, type = table.unpack(which_type)

    --- @brief entity_set_move_storage_value, entity_set_status_storage_value, entity_set_equip_storage_value, entity_set_consumable_storage_value
    rt.GameState["entity_set_" .. which .. "_storage_value"] = function(self, entity, slot_i, id, new_value)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)
        meta.assert_string(id)

        local entity_entry = self:_get_entity_entry(entity)
        if entity_entry == nil then
            rt.error("In rt.GameState:entity_set_" .. which .. "_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
            return
        end

        local object_entry = entity_entry[which .. "s"][slot_i]
        if object_entry == nil or object_entry.id == nil then
            rt.error("In rt.GameState:entity_set_" .. which .. "_storage_value: entity `" .. entity:get_id() .. "` has no valid object at slot `" .. slot_i .. "`")
            return
        end

        object_entry.storage[id] = new_value
    end

    --- @brief entity_get_move_storage_value, entity_get_status_storage_value, entity_get_equip_storage_value, entity_get_consumable_storage_value
    rt.GameState["entity_get_" .. which .. "_storage_value"] = function(self, entity, slot_i, id, new_value)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)
        meta.assert_string(id)

        local entity_entry = self:_get_entity_entry(entity)
        if entity_entry == nil then
            rt.error("In rt.GameState:entity_get_" .. which .. "_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
            return
        end

        local object_entry = entity_entry[which .. "s"][slot_i]
        if object_entry == nil or object_entry.id == nil then
            rt.error("In rt.GameState:entity_get_" .. which .. "_storage_value: entity `" .. entity:get_id() .. "` has no valid object at slot `" .. slot_i .. "`")
            return
        end

        return object_entry.storage[id]
    end

    --- @brief entity_replace_move_storage_value, entity_replace_status_storage_value, entity_replace_equip_storage_value, entity_replace_consumable_storage_value
    rt.GameState["entity_replace_" .. which .. "_storage_value"] = function(self, entity, slot_i, new_table)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)
        meta.assert_table(new_table)

        local entity_entry = self:_get_entity_entry(entity)
        if entity_entry == nil then
            rt.error("In rt.GameState:entity_get_" .. which .. "_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
            return
        end

        local object_entry = entity_entry[which .. "s"][slot_i]
        if object_entry == nil or object_entry.id == nil then
            rt.error("In rt.GameState:entity_get_" .. which .. "_storage_value: entity `" .. entity:get_id() .. "` has no valid object at slot `" .. slot_i .. "`")
            return
        end

        object_entry.storage = new_table
    end
end

--- @brief
function rt.GameState:list_templates()
    local out = {}
    for id in keys(self._state.templates) do
        table.insert(out, mn.Template(self, id))
    end
    return out
end

--- @brief
function rt.GameState:template_get_name(id)
    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:template_get_name: template `" .. id .. "` is not part of state")
        return ""
    end
    return entry.name
end

--- @brief
function rt.GameState:template_get_date(id)
    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:template_get_date: template `" .. id .. "` is not part of state")
        return os.date("%c", os.time())
    end

    return os.date("%c", entry.date)
end

--- @brief
function rt.GameState:template_list_entities(id)
    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:template_list_entities: template `" .. id .. "` is not part of state")
        return {}
    end

    local out = {}
    for entity_id in keys(entry.entities) do
        table.insert(out, self:_entity_id_to_entity(entity_id))
    end

    table.sort(out, function(a, b)
        return self._entity_to_entity_index[a] < self._entity_to_entity_index[b]
    end)

    return out
end

for which in range("move", "consumable", "equip") do
    local Type
    if which == "move" then
        Type = bt.Move
    elseif which == "equip" then
        Type = bt.Equip
    elseif which == "consumable" then
        Type = bt.Consumable
    end

    --- @brief template_list_entity_move_slots, template_list_entity_consumable_slots, template_list_entity_equip_slots
    --- @return Unsigned, Table<*>
    rt.GameState["template_list_entity_" .. which .. "_slots"] = function(self, template_id, entity_id)
        meta.assert_string(template_id, entity_id)

        local entry = self._state.templates[template_id]
        if entry == nil then
            rt.error("In rt.GameState:template_list_entity_" .. which .. "_slots: template `" .. template_id .. "` is not part of state")
            return {}
        end

        local setup = entry.entities[entity_id]
        if setup == nil then return {} end

        local out = {}
        local slots = setup[which .. "s"]
        local n = 0
        for slot_i, id in ipairs(slots) do
            if id ~= "" then
                out[slot_i] = Type(id)
            end
            n = n + 1
        end

        return n, out
    end
end

--- @brief
--- @return TemplateID
function rt.GameState:add_template(name)
    meta.assert_string(name)
    local n = self._state.template_id_counter

    local id = "TEMPLATE_"
    if n < 10 then
        id = id .. "00"
    elseif n < 100 then
        id = id .. "0"
    end

    id = id .. n .. "_"

    for i = 1, #name do
        local c = string.at(name, i)
        if c == " " then
            id = id .. "_"
        else
            id = id .. string.upper(c)
        end
    end

    self._state.template_id_counter = self._state.template_id_counter + 1
    self._state.templates[id] = {
        name = name,
        date = os.time(),
        entities = {}
    }

    return id
end

--- @brief
function rt.GameState:remove_template(template)
    meta.assert_isa(template, mn.Template)
    local id = template:get_id()
    if self._state.templates[id] == nil then
        rt.error("In rt.GameState.remove_template: template `" .. id .. "` is not part of state")
        return
    end

    self._state.templates[id] = nil
end

--- @brief
function rt.GameState:load_template(template)
    meta.assert_isa(template, mn.Template)
    local id = template:get_id()
    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:load_template: no template with id `" .. id .. "`")
    end

    local state = self._state
    local entity_id_to_is_present = {}

    -- unequip all
    local entities = self:list_entities()
    for entity_i, entity_entry in ipairs(state.entities) do
        entity_id_to_is_present[entity_entry.id] = true

        local entity = self._entity_index_to_entity[entity_i]
        for slot_i, move_entry in ipairs(entity_entry.moves) do
            if move_entry.id ~= "" then
                local move = bt.Move(move_entry.id)
                self:entity_remove_move(entity, slot_i)
                self:add_shared_move(move)
            end
        end

        for slot_i, equip_entry in ipairs(entity_entry.equips) do
            if equip_entry.id ~= "" then
                local equip = bt.Equip(equip_entry.id)
                self:entity_remove_equip(entity, slot_i)
                self:add_shared_equip(equip)
            end
        end

        for slot_i, consumable_entry in ipairs(entity_entry.consumables) do
            if consumable_entry.id ~= "" then
                local consumable = bt.Consumable(consumable_entry.id)
                self:entity_remove_consumable(entity, slot_i)
                self:add_shared_consumable(consumable)
            end
        end
    end

    -- equip if possible
    local full_equip_possible = true

    for entity in values(template:list_entities()) do
        if entity_id_to_is_present[entity:get_id()] then
            local n, slots = template:list_move_slots(entity)
            local move_set = {}
            for slot_i = 1, n do
                local move = slots[slot_i]
                if move ~= nil then
                    local shared_move_entry = state.shared_moves[move:get_id()]
                    if shared_move_entry ~= nil and shared_move_entry.count >= 1 and move_set[move] == nil then
                        self:remove_shared_move(move)
                        self:entity_add_move(entity, slot_i, move)
                        move_set[move] = true
                    else
                        full_equip_possible = false
                    end
                end
            end

            n, slots = template:list_equip_slots(entity)
            for slot_i = 1, n do
                local equip = slots[slot_i]
                if equip ~= nil then
                    local shared_equip_entry = state.shared_equips[equip:get_id()]
                    if shared_equip_entry ~= nil and shared_equip_entry.count >= 1 then
                        self:remove_shared_equip(equip)
                        self:entity_add_equip(entity, slot_i, equip)
                    else
                        full_equip_possible = false
                    end
                end
            end

            n, slots = template:list_consumable_slots(entity)
            for slot_i = 1, n do
                local consumable = slots[slot_i]
                if consumable ~= nil then
                    local shared_consumable_entry = state.shared_consumables[consumable:get_id()]
                    if shared_consumable_entry ~= nil and shared_consumable_entry.count >= 1 then
                        self:remove_shared_consumable(consumable)
                        self:entity_add_consumable(entity, slot_i, consumable)
                    else
                        full_equip_possible = false
                    end
                end
            end
        else
            full_equip_possible = false
        end
    end

    return full_equip_possible
end

--- @brief
function rt.GameState:template_rename(id, new_name)
    meta.assert_string(id, new_name)
    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:template_rename: no template with id `" .. id .. "`")
        return
    end

    entry.name = new_name
end

--- @brief
function rt.GameState:template_remove(id)
    meta.assert_string(id)
    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:template_remove: no template with id `" .. id .. "`")
        return
    end
end

--- @brief
--- @param entity bt.Entity
--- @param moves Table<bt.Move>
--- @param equips Table<bt.Equips>
--- @param consumables Table<bt.Consumables>
function rt.GameState:template_add_entity(id, entity, moves, equips, consumables)
    meta.assert_string(id)
    meta.assert_table(moves, equips, consumables)
    meta.assert_isa(entity, bt.Entity)

    local entry = self._state.templates[id]
    if entry == nil then
        rt.error("In rt.GameState:template_add_entity: no template with id `" .. id .. "`")
        return
    end

    local n_move_slots = entity:get_n_move_slots()
    local n_consumable_slots = entity:get_n_consumable_slots()
    local n_equip_slots = entity:get_n_equip_slots()

    local setup = {
        moves = {},
        consumables = {},
        equips = {}
    }

    for i = 1, n_move_slots do
        local move = moves[i]
        if move ~= nil then
            meta.assert_isa(move, bt.Move)
            setup.moves[i] = move:get_id()
        else
            setup.moves[i] = ""
        end
    end

    for i = 1, n_equip_slots do
        local equip = equips[i]
        if equip ~= nil then
            meta.assert_isa(equip, bt.Equip)
            setup.equips[i] = equip:get_id()
        else
            setup.equips[i] = ""
        end
    end

    for i = 1, n_consumable_slots do
        local consumable = consumables[i]
        if consumable ~= nil then
            meta.assert_isa(consumable, bt.Consumable)
            setup.consumables[i] = consumable:get_id()
        else
            setup.consumables[i] = ""
        end
    end

    entry.entities[entity:get_id()] = setup
end

--- @brief
function rt.GameState:set_grabbed_object(object)
    if not (meta.isa(object, bt.Move) or meta.isa(object, bt.Equip) or meta.isa(object, bt.Consumable)) then
        rt.error("In rt.GameState:set_grabbed_object: Objet `" .. meta.typeof(object) .. "` is not a bt.Move, bt.Consumable, or bt.Equip")
        return
    end

    if self._grabbed_object ~= nil then
        if meta.isa(self._grabbed_object, bt.Move) then
            self:add_shared_move(self._grabbed_object)
        elseif meta.isa(self._grabbed_object, bt.Equip) then
            self:add_shared_equip(self._grabbed_object)
        elseif meta.isa(self._grabbed_object, bt.Consumable) then
            self:add_shared_consumable(self._grabbed_object)
        else
            -- unreachable
        end
    end

    self._grabbed_object = object
end

--- @brief
function rt.GameState:has_grabbed_object()
    return self._grabbed_object ~= nil
end

--- @brief
function rt.GameState:take_grabbed_object()
    local out = self._grabbed_object
    self._grabbed_object = nil
    return out
end

--- @brief
function rt.GameState:peek_grabbed_object()
    return self._grabbed_object
end



--- @brief
function rt.GameState:initialize_debug_state()
    local moves = {
        "BOMB",
        "DEBUG_MOVE"
    }

    local equips = {
        --"DEBUG_EQUIP",
        "FAST_SHOES",
        "HELMET",
        "KITCHEN_KNIFE"
    }

    local consumables = {
        --"DEBUG_CONSUMABLE",
        "SINGLE_CHERRY",
        "DOUBLE_CHERRY"
    }

    local entities = {
        bt.Entity(self, "MC"),
        bt.Entity(self, "PROF"),
        bt.Entity(self, "GIRL"),
        bt.Entity(self, "RAT"),
        bt.Entity(self, "BOULDER"),
    }

    local n_sprouts = 2
    for i = 1, n_sprouts do
        table.insert(entities, bt.Entity(self, "WALKING_SPROUT"))
    end

    rt.random.seed(0)

    for entity in values(entities) do
        local possible_moves = rt.random.shuffle({table.unpack(moves)})
        local move_i = 1
        for slot_i = 1, entity:get_n_move_slots() do
            if rt.random.toss_coin(0.2) then
                self:entity_add_move(entity, slot_i, bt.Move(possible_moves[move_i]))
                move_i = move_i + 1
                if move_i > #moves then break end
            end
        end

        if entity:get_n_equip_slots() > 0 then
            self:entity_add_equip(entity, 1, bt.Equip("DEBUG_EQUIP"))
        end
        for slot_i = 2, entity:get_n_equip_slots() do
            if rt.random.toss_coin(0.8) then
                self:entity_add_equip(entity, slot_i, bt.Equip(equips[rt.random.integer(1, #equips)]))
            end
        end

        if entity:get_n_consumable_slots() > 0 then
            self:entity_add_consumable(entity, 1, bt.Consumable("DEBUG_CONSUMABLE"))
        end
        for slot_i = 2, entity:get_n_consumable_slots() do
            if rt.random.toss_coin(0.8) then
                self:entity_add_consumable(entity, slot_i,  bt.Consumable(consumables[rt.random.integer(1, #consumables)]))
            end
        end

        --self:entity_add_status(entity, bt.Status("DEBUG_STATUS"))
        self:entity_set_hp(entity, entity:get_hp_base())
    end

    self:add_global_status(bt.GlobalStatus("DEBUG_GLOBAL_STATUS"))

    local max_count = 99
    for move in values(moves) do
        self:add_shared_move(bt.Move(move), rt.random.integer(1, max_count))
    end

    for consumable in values(consumables) do
        self:add_shared_consumable(bt.Consumable(consumable), rt.random.integer(1, max_count))
    end

    for equip in values(equips) do
        self:add_shared_equip(bt.Equip(equip), rt.random.integer(1, max_count))
    end

    local empty_template = self:add_template("Empty Template")
    for entity in values(entities) do
        self:template_add_entity(empty_template, entity, {}, {}, {})
    end

    local debug_template = self:add_template("Debug Template")
    for entity in values(entities) do
        self:template_add_entity(debug_template, entity, entity:list_moves(), entity:list_equips(), entity:list_consumables())
    end

    local error_template = self:add_template("Error Template")
    for entity in range(entities[1]) do
        self:template_add_entity(error_template, entity, table.rep(bt.Move("DEBUG_MOVE"), 16), {}, {})
    end
end
