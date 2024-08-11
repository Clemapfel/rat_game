--[[
    entity_id_to_multiplicity[entity_id] = count,
    entity_id_to_index[entity_id] = index,
    n_allies = 0
    n_enemies = 0

    entities = {
        id      -- EntityID
        hp      -- Unsigned
        index   -- Unsigned
        
        moves[slot_i] = {
            id
            n_used
        }

        equips[slot_i] = {
            id
        }

        consumables[slot_i] = {
            id
            n_used
        }

        statuses[status_id] = {
            n_turns_elapsed
        }
    }

    shared_moves[move_id] = {
        count
    }

    shared_equips[equip_id] = {
        count
    }

    shared_consumables[equip_id] = {
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
        moves = {},
        equips = {},
        consumables = {}
    }

    for i = 1, n_moves do
        to_add.moves[i] = {
            id = "",
            n_used = 0
        }
    end

    for i = 1, n_equips do
        to_add.equips[i] = {
            id = ""
        }
    end

    for i = 1, n_consumables do
        to_add.consumables[i] = {
            id = "",
            n_used = 0
        }
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
function rt.GameState:_get_entity_entry(entity)
    return self._state.entities[self._state.entity_id_to_index[entity:get_id()]]
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

    if new_hp <= 0 then
        rt.error("In rt.GameState:entity_set_hp: hp value `" .. new_hp .. "` is invalid")
    end

    entry.hp = math.ceil(new_hp)
end

for which in range("move", "equip", "consumable") do
    local type
    if which == "move" then
        type = bt.Move
    elseif which == "equip" then
        type = bt.Equip
    elseif which == "consumable" then
        type = bt.Consumable
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
                table.insert(out, type(id))
            end
        end
        return out
    end

    --- @brief entity_list_move_slots, entity_list_equip_slots, entity_list_consumable_slots
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
                out[slot_i] = type(id)
            end
        end
        return out, n_slots
    end

    --- @brief entity_get_move, entity_get_equip, entity_get_consumable
    rt.GameState["entity_get_" .. which] = function(self, entity, slot_i)
        meta.assert_isa(entity, bt.Entity)

        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots() then
            rt.error("In rt.GameState:entity_add_" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
            return
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
            return type(id)
        end
    end

    --- @brief entity_add_move, entity_add_equip, entity_add_consumable
    rt.GameState["entity_add_" .. which] = function(self, entity, slot_i, object)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_isa(object, type)

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

        if object_entry.n_used ~= nil then
            object_entry.n_used = 0
        end
    end

    --- @brief entity_remove_move, entity_remove_equip, entity_remove_consumable
    rt.GameState["entity_remove_" .. which] = function(self, entity, slot_i)
        meta.assert_isa(entity, bt.Entity)

        local n_slots = entity["get_n_" .. which .. "_slots"](entity)
        if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots() then
            rt.error("In rt.GameState:entity_remove_" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
            return
        end

        local entry = self:_get_entity_entry(entity)
        if entry == nil then
            rt.error("In rt.GameState:entity_remove_" .. which ..": entity `" .. entity:get_id() .. "` is not part of state")
            return 
        end
        local object_entry = entry[which .. "s"]
        object_entry[slot_i].id = ""

        if object_entry.n_used ~= nil then
            object_entry.n_used = 0
        end
    end

    if which == "move" or which == "consumable" then
        --- @brief entity_get_move_n_used, entity_get_consumable_n_used
        rt.GameState["entity_get_" .. which .. "_n_used"] = function(self, entity, slot_i)
            meta.assert_isa(entity, bt.Entity)

            local n_slots = entity["get_n_" .. which .. "_slots"](entity)
            if slot_i <= 0 or math.fmod(slot_i, 1) ~= 0 or slot_i > n_slots() then
                rt.error("In rt.GameState:entity_" .. which .. "_get_n_used" .. which .. ": slot index `" .. slot_i .. "` is out of range for an entity with `" .. n_slots .. "` slots")
                return
            end

            local entry = self:_get_entity_entry(entity)
            if entry == nil then
                rt.error("In rt.GameState:entity_" .. which .."_get_n_used: entity `" .. entity:get_id() .. "` is not part of state")
                return 0
            else
                return entry[which .. "s"].n_used
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
    end

    --- @brief list_shared_moves, list_shared_equips, list_shared_consumables
    rt.GameState["list_shared_" .. which .. "s"] = function(self)
        local out = {}
        local entries = self._state["shared_" .. which .. "s"]
        for id, entry in pairs(entries) do
            table.insert(out, type(id))
        end
        return out
    end

    --- @brief get_shared_move_count, get_shared_equip_count, get_shared_consumable_count
    rt.GameState["get_shared_" .. which .. "_count"] = function(self, object)
        meta.assert_isa(object, type)
        local item = self._state["shared_" .. which .. "s"]
        if item == nil then
            return item[object:get_id()]
        else
            return 0
        end
    end

    --- @brief add_shared_move, add_shared_equip, add_shared_consumable
    rt.GameState["add_shared_" .. which] = function(self, object)
        meta.assert_isa(object, type)

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
        meta.assert_isa(object, type)

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
        meta.assert_isa(object, type)

        local entry = self._state["shared_" .. which .. "s"][object:get_id()]
        if entry == nil then
            return 0
        else
            return entry.count
        end
    end
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
        n_turns_elapsed = 0
    }
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

    entry.statuses[status.get_id()] = nil
end

--- @brief
function rt.GameState:initialize_debug_party()
    local moves = {
        "DEBUG_MOVE",
        "INSPECT",
        "PROTECT",
        "STRUGGLE",
        "SURF",
        "WISH"
    }

    local equips = {
        "DEBUG_EQUIP",
        "DEBUG_CLOTHING",
        "DEBUG_FEMALE_CLOTHING",
        "DEBUG_MALE_CLOTHING",
        "DEBUG_WEAPON",
        "DEBUG_TRINKET"
    }

    local consumables = {
        "DEBUG_CONSUMABLE",
        "ONE_CHERRY",
        "TWO_CHERRY"
    }

    local entities = {
        "MC",
        "MC",
        "PROF",
        "GIRL",
        "RAT"
    }

    for id in values(entities) do
        local entity = bt.Entity(id)
        self:add_entity(entity)

        local possible_moves = rt.random.shuffle({table.unpack(moves)})
        local move_i = 1
        for slot_i = 1, entity:get_n_move_slots() do
            if rt.random.toss_coin(0.8) then
                self:entity_add_move(entity, slot_i, bt.Move(possible_moves[move_i]))
                move_i = move_i + 1
                if move_i > #moves then break end
            end
        end

        for slot_i = 1, entity:get_n_equip_slots() do
            if rt.random.toss_coin(0.8) then
                self:entity_add_equip(entity, slot_i, bt.Equip(equips[rt.random.integer(1, #equips)]))
            end
        end

        for slot_i = 1, entity:get_n_consumable_slots() do
            if rt.random.toss_coin(0.8) then
                self:entity_add_consumable(entity, slot_i, bt.Consumable(consumables[rt.random.integer(1, #consumables)]))
            end
        end

        self:entity_set_hp(entity, entity:get_hp_base())
    end
end


