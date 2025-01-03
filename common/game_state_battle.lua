--[[
    entity_id_to_multiplicity[entity_id] = count,
    turn_i = 1,
    is_battle_active = true,

    entities = {
        id       -- EntityID
        multiplicity  -- Unsigned
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

    quicksave = {
        time = "",
        state = {}
    }
]]--

--- @brief
function rt.GameState:get_is_battle_active()
    return self._state.is_battle_active
end

--- @brief
function rt.GameState:set_is_battle_active(b)
    meta.assert_boolean(b)
    self._state.is_battle_active = b
end

--- @brief
function rt.GameState:create_entity(config)
    meta.assert_isa(config, bt.EntityConfig)

    local state = self._state
    local n_moves = config:get_n_move_slots()
    local n_equips = config:get_n_equip_slots()
    local n_consumables = config:get_n_consumable_slots()
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

    for id in values(config:list_intrinsic_move_ids()) do
        table.insert(to_add.intrinsic_moves, id)
    end

    table.insert(state.entities, to_add)

    local config_id = config:get_id()
    local current_multiplicity = state.entity_id_to_multiplicity[config_id]
    if state.entity_id_to_multiplicity[config_id] == nil then
        current_multiplicity = 0
    end
    current_multiplicity = current_multiplicity + 1
    state.entity_id_to_multiplicity[config_id] = current_multiplicity

    local out = bt.Entity(config, current_multiplicity)
    local count = sizeof(state.entities)
    to_add.id = config:get_id()
    to_add.index = sizeof(state.entities)
    to_add.multiplicity = current_multiplicity
    to_add.hp = 0

    return out
end

--- @brief [internal]
function rt.GameState:_get_entity_entry(entity)
    meta.assert_isa(entity, bt.Entity)
    for i, entry in ipairs(self._state.entities) do
        if entry.id == entity:get_config():get_id() and entry.multiplicity == entity:get_multiplicity() then
            return entry, i
        end
    end
    return nil, nil
end

--- @brief
function rt.GameState:remove_entity(entity)
    meta.assert_isa(entity, bt.Entity)

    local state = self._state
    local _, entity_i = self:_get_entity_entry(entity)
    if entity_i == nil then
        rt.error("In rt.GameState:entity_remove: trying to remove entity `" .. entity:get_id() .. "`, but entity was not yet added to game state")
        return
    end

    table.remove(state.entities, entity_i)
    local i = 1
    for entry in values(state.entities) do
        entry.index = i
        i = i + 1
    end
end

--- @brief
function rt.GameState:list_dead_entities()
    local out = {}
    for entry in values(self._state.entities) do
        if entry.state == bt.EntityState.DEAD then
            table.insert(out, bt.Entity(bt.EntityConfig(entry.id), entry.multiplicity))
        end
    end
    return out
end

--- @brief
function rt.GameState:list_entities()
    local out = {}
    for entry in values(self._state.entities) do
        if entry.state ~= bt.EntityState.DEAD then
            table.insert(out, bt.Entity(bt.EntityConfig(entry.id), entry.multiplicity))
        end
    end
    return out
end

--- @brief also list dead
function rt.GameState:list_all_entities()
    local out = {}
    for entry in values(self._state.entities) do
        table.insert(out, bt.Entity(bt.EntityConfig(entry.id), entry.multiplicity))
    end
    return out
end

do
    local _sort_by_priority = function(state, t)
        local out = t
        table.sort(t, function(a, b)
            local a_prio = state:entity_get_priority(a)
            local b_prio = state:entity_get_priority(b)
            local a_speed = state:entity_get_speed(a)
            local b_speed = state:entity_get_speed(b)

            if a_prio == b_prio then
                if a_speed == b_speed then
                    return a:get_id() < b:get_id()
                else
                    return a_speed > b_speed
                end
            else
                return a_prio > b_prio
            end
        end)
        return out
    end

    --- @brief
    function rt.GameState:list_entities_in_order()
        return _sort_by_priority(self, self:list_entities())
    end

    --- @brief also list dead
    function rt.GameState:list_all_entities_in_order()
        return _sort_by_priority(self, self:list_all_entities())
    end
end

--- @brief
function rt.GameState:list_party()
    local out = {}
    for entry in values(self._state.entities) do
        local config = bt.EntityConfig(entry.id)
        if entry.state ~= bt.EntityState.DEAD and not config:get_is_enemy() then
            table.insert(out, bt.Entity(config, entry.multiplicity))
        end
    end
    return out
end

--- @brief
function rt.GameState:list_all_party()
    local out = {}
    for entry in values(self._state.entities) do
        local config = bt.EntityConfig(entry.id)
        if not config:get_is_enemy() then
            table.insert(out, bt.Entity(config, entry.multiplicity))
        end
    end
    return out
end

--- @brief
function rt.GameState:list_enemies()
    local out = {}
    for entry in values(self._state.entities) do
        local config = bt.EntityConfig(entry.id)
        if entry.state ~= bt.EntityState.DEAD and config:get_is_enemy() then
            table.insert(out, bt.Entity(config, entry.multiplicity))
        end
    end
    return out
end

--- @brief
function rt.GameState:list_all_enemies()
    local out = {}
    for entry in values(self._state.entities) do
        local config = bt.EntityConfig(entry.id)
        if config:get_is_enemy() then
            table.insert(out, bt.Entity(config, entry.multiplicity))
        end
    end
    return out
end

--- @brief
function rt.GameState:get_n_entities()
    return sizeof(self._state.entities)
end

--- @brief
function rt.GameState:get_n_party()
    return sizeof(self:list_party())
end

--- @brief
function rt.GameState:get_n_enemies()
    return sizeof(self:list_enemies())
end

--- @brief
function rt.GameState:entity_get_is_enemy(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_is_enemy: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    return bt.EntityConfig(entry.id):get_is_enemy()
end

--- @brief
function rt.GameState:entity_get_n_consumable_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_n_consumable_slots: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    return bt.EntityConfig(entry.id):get_n_consumable_slots()
end

--- @brief
function rt.GameState:entity_get_n_equip_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_n_equip_slots: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    return bt.EntityConfig(entry.id):get_n_equip_slots()
end

--- @brief
function rt.GameState:entity_get_n_move_slots(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_get_n_move_slots: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    return bt.EntityConfig(entry.id):get_n_move_slots()
end

--- @brief
function rt.GameState:entity_get_priority(entity)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState.entity_get_priority: entity `" .. entity:get_id() .. "` is not part of state")
        return 0
    end
    return entry.priority
end

--- @brief
function rt.GameState:entity_set_priority(entity, new_value)
    meta.assert_isa(entity, bt.Entity)
    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState.entity_set_priority: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end
    entry.priority = new_value
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
        local status = bt.StatusConfig(id)
        if status:get_is_stun() then
            is_stunned = true
            max_n_turns = math.max(max_n_turns, status:get_max_duration() - n_turns_elapsed)
        end
    end

    return is_stunned, max_n_turns
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
function rt.GameState:entity_swap_indices(entity_a, entity_b)
    meta.assert_isa(entity_a, bt.Entity)
    meta.assert_isa(entity_b, bt.Entity)

    local a_entry = self:_get_entity_entry(entity_a)
    local b_entry = self:_get_entity_entry(entity_b)

    local error_entity
    if a_entry == nil then error_entity = entity_a end
    if b_entry == nil then error_entity = entity_b end
    if error_entity ~= nil then
        rt.error("In rt.GameState:entity_swap_indices: entity `" .. error_entity:get_id() .. "` is not part of state")
        return
    end

    local new_b_index = a_entry.index
    local new_a_index = b_entry.index
    a_entry.index = new_a_index
    b_entry.index = new_b_index

    local state = self._state
    state.entities[new_a_index] = a_entry
    state.entities[new_b_index] = b_entry
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
        new_hp = 0
    end

    entry.hp = math.ceil(new_hp)
end


for which in range("hp", "attack", "defense", "speed") do

    --- @brief entity_get_hp_base_raw, entity_get_attack_base_raw, entity_get_defense_base_raw, entity_get_speed_base_raw
    rt.GameState["entity_get_" .. which .. "_base_raw"] = function(self, entity)
        return entity:get_config()[which .. "_base"]
    end

    --- @brief entity_get_hp_base, entity_get_attack_base, entity_get_defense_base, entity_get_speed_base
    rt.GameState["entity_get_" .. which .. "_base"] = function(self, entity)
        local value = self["entity_get_" .. which .. "_base_raw"](self, entity)
        local equips = self:entity_list_equips(entity)
        for equip in values(equips) do
            value = value + equip[which .. "_base_offset"]
        end

        for equip in values(equips) do
            value = value * equip[which .. "_base_factor"]
        end

        return math.max(0, math.ceil(value))
    end

    --- @brief entity_get_attack, entity_get_defense, entity_get_speed
    rt.GameState["entity_get_" .. which] = function(self, entity)
        local value = self["entity_get_" .. which .. "_base"](self, entity)
        local statuses = self:entity_list_statuses(entity)

        if which ~= "hp" then
            for status in values(statuses) do
                value = value + status[which .. "_offset"]
            end

            for status in values(statuses) do
                value = value * status[which .. "_factor"]
            end
        end

        return math.max(0, math.ceil(value))
    end
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

for which_type in range(
    {"move", bt.MoveConfig},
    {"equip", bt.EquipConfig},
    {"consumable", bt.ConsumableConfig}
) do
    local which, Type = table.unpack(which_type)

    --- @brief entity_list_moves, entity_list_equips, entity_list_consumables
    rt.GameState["entity_list_" .. which .. "s"] = function(self, entity)
        meta.assert_isa(entity, bt.Entity)

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_list_" .. which .."s: entity `" .. entity:get_id() .. "` is not part of state")
            return {}
        end

        local out = {}
        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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
        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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

        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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

        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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

        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
        if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots then
            rt.error("In rt.GameState:entity_add_" .. which .. ": slot index `" .. slot_i .. "` is out of range for an `" .. entity:get_id() .. "` which has `" .. n_slots .. "` slots")
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

        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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
        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)

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
        local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)

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

            local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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

            local n_slots = self["entity_get_n_" .. which .. "_slots"](self, entity)
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
    end

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
        table.insert(out, bt.MoveConfig(move_id))
    end

    return out
end

--- @brief
--- @return Number, Number, Number, Number
function rt.GameState:entity_preview_equip(entity, slot_i, new_equip)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_number(slot_i)
    meta.assert_isa(new_equip, bt.EquipConfig)

    local previous = self:entity_get_equip(entity, slot_i)
    if new_equip == nil then
        self:entity_remove_equip(entity, slot_i)
    else
        self:entity_add_equip(entity, slot_i, new_equip)
    end

    local hp = self:entity_get_hp(entity)
    local attack = self:entity_get_attack(entity)
    local defense = self:entity_get_defense(entity)
    local speed = self:entity_get_speed(entity)

    self:entity_remove_equip(entity, slot_i)
    if previous ~= nil then
        self:entity_add_equip(entity, slot_i, previous)
    end

    return hp, attack, defense, speed
end

--- @brief
function rt.GameState:add_shared_object(object)
    if meta.isa(object, bt.MoveConfig) then
        self:add_shared_move(object)
    elseif meta.isa(object, bt.EquipConfig) then
        self:add_shared_equip(object)
    elseif meta.isa(object, bt.ConsumableConfig) then
        self:add_shareD_consumable(object)
    else
        rt.error("In rt.GameState:add_shared_object: object `" .. meta.typeof(object) .. "` is not a bt.MoveConfig, bt.EquipConfig, or bt.Consumable")
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

    local config = entity:get_config()
    local n_move_slots, n_equip_slots, n_consumable_slots = config:get_n_move_slots(), config:get_n_equip_slots(), config:get_n_consumable_slots()
    for i = 1, n_move_slots do
        local id = entry.moves[i].id
        if id ~= "" then
            local move = bt.MoveConfig(id)
            table.insert(moves, move)
            self:entity_remove_move(entity, i)
        end
    end

    for i = 1, n_equip_slots do
        local id = entry.equips[i].id
        if id ~= "" then
            local equip = bt.EquipConfig(id)
            table.insert(equips, equip)
            self:entity_remove_equip(entity, i)
        end
    end

    for i = 1, n_consumable_slots do
        local id = entry.consumables[i].id
        if id ~= "" then
            local consumable = bt.ConsumableConfig(id)
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
    meta.assert_isa(status, bt.StatusConfig)

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
function rt.GameState:entity_clear_statuses(entity)
    meta.assert_isa(entity, bt.Entity)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_add_status: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    entry.statuses = {}
end

--- @brief
function rt.GameState:entity_has_status(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.StatusConfig)

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
        table.insert(out, bt.StatusConfig(id))
    end
    return out
end

--- @brief
function rt.GameState:entity_get_status_n_turns_elapsed(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.StatusConfig)
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
--- @return Boolean should expire
function rt.GameState:entity_set_status_n_turns_elapsed(entity, status, n_turns)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.StatusConfig)
    meta.assert_number(n_turns)

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

    item.n_turns_elapsed = n_turns
    return item.n_turns_elapsed >= status:get_max_duration()
end

--- @brief
function rt.GameState:entity_has_status(entity, status)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.StatusConfig)

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
    meta.assert_isa(status, bt.StatusConfig)

    local entry = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState:entity_remove_status: entity `" .. entity:get_id() .. "` is not part of state")
        return
    end

    entry.statuses[status:get_id()] = nil
end

--- @brief
function rt.GameState:add_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    self._state.global_statuses[global_status:get_id()] = {
        n_turns_elapsed = 0,
        storage = {}
    }
end

--- @brief
function rt.GameState:remove_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    local entry = self._state.global_statuses[global_status:get_id()]

    if entry == nil then
        rt.error("In rt.GameState:remove_global_status: status `" .. global_status:get_id() .. "` is not present")
        return
    end

    self._state.global_statuses[global_status:get_id()] = nil
end

--- @brief
function rt.GameState:has_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    return self._state.global_statuses[global_status:get_id()] ~= nil
end

--- @brief
function rt.GameState:list_global_statuses()
    local out = {}
    for id in keys(self._state.global_statuses) do
        table.insert(out, bt.GlobalStatusConfig(id))
    end
    return out
end

--- @brief
function rt.GameState:get_global_status_n_turns_elapsed(global_status)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    local entry = self._state.global_statuses[global_status:get_id()]
    if entry == nil then
        return 0
    else
        return entry.n_turns_elapsed
    end
end

--- @brief
function rt.GameState:set_global_status_n_turns_elapsed(global_status, n_turns)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    meta.assert_number(n_turns)

    local entry = self._state.global_statuses[global_status:get_id()]
    if entry == nil then
        rt.error("In rt.GameState.set_global_status_n_turns_elapsed: global status `" .. global_status:get_id() .. "` is not present")
        return 0
    end

    entry.n_turns_elapsed = clamp(n_turns, 0, global_status:get_max_duration())
end

--- @brief
function rt.GameState:has_global_status(global_status)
    meta.assert_isa(global_status, bt.GlobalStatusConfig)
    return self._state.global_statuses[global_status:get_id()] ~= nil
end

--- @brief
function rt.GameState:entity_set_status_storage_value(entity, status, id, new_value)
    meta.assert_isa(entity, bt.Entity)
    meta.assert_isa(status, bt.StatusConfig)
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
    meta.assert_isa(status, bt.StatusConfig)
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
    meta.assert_isa(status, bt.GlobalStatusConfig)
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
    meta.assert_isa(status, bt.GlobalStatusConfig)
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
    meta.assert_isa(status, bt.GlobalStatusConfig)
    meta.assert_table(new_table)

    local status_entry = self._state.global_statuses[status:get_id()]
    if status_entry == nil then
        rt.error("In rt.GameState:set_global_status_storage_value: entity `" .. entity:get_id() .. "` is not part of state")
        return nil
    end

    status_entry.storage = new_table
end

do
    local function _deep_copy(original)
        if not meta.is_table(original) then return original end
        local out = {}
        for key, value in pairs(original) do
            if meta.is_table(value) then
                out[key] = _deep_copy(value)
            else
                out[key] = value
            end
        end
        return out
    end

    -- fields that will be copied during in-battle quicksave
    local _quicksaved_state_member_names = {
        "entity_id_to_multiplicity",
        "entities",
        "turn_i",
        "global_statuses",
        "shared_moves",
        "shared_equips",
        "shared_consumables"
    }

    --- @brief
    --- @return rt.RenderTexture
    function rt.GameState:create_quicksave()
        local scene = self._current_scene

        if not meta.isa(scene, bt.BattleScene) then
            rt.error("In rt.GameState.create_quicksave: trying to quicksave, but no or non-battle scene is active")
            return
        end

        local bounds = scene:get_bounds()
        if not (self._quicksave_screenshot ~= nil and
            self._quicksave_screenshot:get_width() == bounds.width and
            self._quicksave_screenshot:get_height() == bounds.height)
        then
            self._quicksave_screenshot = rt.RenderTexture(bounds.width, bounds.height, 0, rt.TextureFormat.RGB5A1)
        end

        scene:create_quicksave_screenshot(self._quicksave_screenshot)

        self._state.quicksave = nil
        local state_copy = _deep_copy(self._state)
        local quicksave = {
            time = os.time(),
            state = {}
        }

        for name in values(_quicksaved_state_member_names) do
            quicksave.state[name] = state_copy[name]
        end
        self._state.quicksave = quicksave
        return self._quicksave_screenshot
    end

    --- @brief
    function rt.GameState:load_quicksave()
        if self._state.quicksave == nil then
            rt.error("In rt.GameState.load_quicksave: Trying to load quicksave, but none is present")
            return
        end

        local state = self._state
        local saved = state.quicksave.state

        state.entity_id_to_multiplicity = {}
        state.entities = {}
        state.turn_i = saved.turn_i
        state.global_statuses = saved.global_statuses
        state.shared_moves = saved.shared_moves
        state.shared_equips = saved.shared_equips
        state.shared_consumables = saved.shared_consumables

        local entities = {}
        for i, entry in ipairs(saved.entities) do
            state.entities[i] = entry
        end
    end
end

--- @brief
function rt.GameState:reset_entity_multiplicity()
    self._state.entity_id_to_multiplicity = {}
end

--- @brief
function rt.GameState:has_quicksave()
    return self._state.quicksave ~= nil
end

--- @brief
function rt.GameState:set_quicksave_screenshot(texture)
    meta.assert_isa(texture, rt.RenderTexture)
    self._quicksave_screenshot = texture
end

--- @brief
function rt.GameState:get_quicksave_screenshot()
    return self._quicksave_screenshot
end

--- @brief
function rt.GameState:get_quicksave_n_turns_elapsed()
    if self._state.quicksave == nil then
        rt.error("In rt.GameState:get_quicksave_n_turns_elapsed: no quicksave present")
        return 0
    end
    return self._state.turn_i  - self._state.quicksave.turn_i
end

--- @brief
function rt.GameState:get_quicksave_exists()
    return self._state.quicksave ~= nil
end

--- @brief
function rt.GameState:get_quicksave_screenshot()
    return self._quicksave_screenshot
end

--- @brief
function rt.GameState:set_turn_i(i)
    meta.assert_number(i)
    self._state.turn_i = i
end

--- @brief
function rt.GameState:get_turn_i()
    return self._state.turn_i
end


--- @brief
function rt.GameState:initialize_debug_state()
    self:initialize_debug_inventory()
end
