--[[
    shared_moves[move_id] = {
        count
    }

    shared_equips[equip_id] = {
        count
    }

    shared_consumables[equip_id] = {
    }


    active_template_id = "default",
    templates[template_id] = {
        name    -- String
        date    -- UnixTimestamp
        party[1] = {
            id = EntityId,

            n_move_slots
            moves[slot_i] = MoveID

            n_consumable_slots
            consumables[slot_i] = ConsumableID

            n_equip_slots
            equips[slot_i] = EquipID
        }
    },

    template_id_counter
]]--


--- @brief
function rt.GameState:get_active_template()
    return self._state.active_template_id
end

--- @brief
function rt.GameState:set_active_template(id)
    if self._state.templates[id] == nil then
        rt.error("In rt.GameState.set_active_template: no template with id `" .. id .. "`")
    end
    self._state.active_template_id = id
end

function rt.GameState:_get_active_template()
    return self._state.templates[self._state.active_template_id]
end

function rt.GameState:_get_entity_entry(entity)
    meta.assert_isa(entity, bt.Entity)
    for i, entry in pairs(self._state.templates[self._state.active_template_id]) do
        if entry.id == entity:get_id() then
            return entry, i
        end
    end
    return nil
end

--- @brief
function rt.GameState:active_template_list_party()
    local template = self:_get_active_template()
    local out = {}
    for entry in values(template.party) do
        table.insert(out, bt.Entity(bt.EntityConfig(entry.id), 1))
    end
    return out
end

--- @brief
function rt.GameState:active_template_get_entity_index(entity)
    local entry, i = self:_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState.active_template_get_party_index: entity `" .. entity:get_id() .. "` is not present in template `" .. self:_get_active_template().name .. "`")
        return 0
    end
    return i
end

--- @brief
function rt.GameState:list_templates()
    local out = {}
    for id, entry in values(self._state.templates) do
        table.insert(out, mn.Template(self, id))
    end
    return out
end

--- @brief
function rt.GameState:active_template_get_party_size()
    return sizeof(self._get_active_template().party)
end

for which_type in range(
    {"move", bt.MoveConfig},
    {"equip", bt.EquipConfig},
    {"consumable", bt.ConsumableConfig}
) do
    local which, type = table.unpack(which_type)

    --- @brief active_template_get_n_move_slots, active_template_get_n_equip_slots, active_template_get_n_consumable_slots
    rt.GameState["active_template_get_n_" .. which .. "_slots"] = function(self, entity)
        return self:_get_entity_entry(entity)["n_" .. which .. "_slots"]
    end

    --- @brief active_template_list_move_slots, active_template_list_equip_slots, active_template_list_consumable_slots
    rt.GameState["active_template_list_" .. which .. "_slots"] = function(self, entity)
        local entry = self:_get_entity_entry(entity)
        local out = {}
        local n = entry["n_" .. which .. "_slots"]
        for i = 1, n do
            out[i] = entry[which .. "s"][i]
        end

        return n, out
    end

    --- @brief active_template_get_move, active_template_get_equip, active_template_get_consumable
    rt.GameState["active_template_get_" .. which] = function(self, entity, slot_i)
        meta.assert_number(slot_i)
        local entry = self:_get_entity_entry(entity)
        local n = entry["n_" .. which .. "_slots"]
        if slot_i > n then
            rt.error("In rt.GameState.active_template_get_" .. which .. ": slot index `" .. slot_i .. "` is out of range for entity `" .. entry.id .. "` which has `" .. n .. "` slots")
        end
        return type(entry[which .. "s"][slot_i])
    end

        --- @brief active_template_get_first_free_move_slot, active_template_get_first_free_equip_slot, active_template_get_first_free_consumable_slot
    rt.GameState["active_template_get_first_free_" .. which .. "_slot"] = function(self, entity)
        local entry = self:_get_entity_entry(entity)
        for i = 1, entry["n_" .. which .. "_slots"] do
            if entry[which .. "s"][i] == nil then return i end
        end
        return nil
    end

    --- @brief active_template_has_move, active_template_has_equip, active_template_has_consumable
    rt.GameState["active_template_has_" .. which] = function(self, entity, object)
        local entry = self:_get_entity_entry(entity)
        for i = 1, entry["n_" .. which .. "_slots"] do
            if entry[which .. "s"][i].id == object:get_id() then
                return true
            end
        end
        return false
    end

    --- @brief active_template_add_move, active_template_add_equip, active_template_add_consumable
    rt.GameState["active_template_add_" .. which] = function(self, entity, slot_i, object)
        meta.assert_number(slot_i)
        local entry = self:_get_entity_entry(entity)
        local n = entry["n_" .. which .. "_slots"]
        if slot_i > n then
            rt.error("In rt.GameState.active_template_add_" .. which .. ": slot index `" .. slot_i .. "` is out of range for entity `" .. entry.id .. "` which has `" .. n .. "` slots")
            return
        end

        if entry[which .. "s"][slot_i] ~= nil then
            rt.error("In rt.GameState.active_template_add_" .. which .. ": slot index `" .. slot_i .. "` of entity `" .. entry.id .. "` already has a " .. which .. " equipped")
            return
        end

        entry[which .. "s"][slot_i] = object:get_id()
    end

    --- @brief active_template_remove_move, active_template_remove_equip, active_template_remove_consumable
    rt.GameState["active_template_remove_" .. which] = function(self, entity, slot_i)
        meta.assert_number(slot_i)
        local entry = self:_get_entity_entry(entity)
        local n = entry["n_" .. which .. "_slots"]
        if slot_i > n then
            rt.error("In rt.GameState.active_template_remove_" .. which .. ": slot index `" .. slot_i .. "` is out of range for entity `" .. entry.id .. "` which has `" .. n .. "` slots")
            return
        end

        if entry[which .. "s"][slot_i] ~= nil then
            rt.error("In rt.GameState.active_template_remove_" .. which .. ": slot index `" .. slot_i .. "` of entity `" .. entry.id .. "` already has a " .. which .. " equipped")
            return
        end

        local out = type(entry[which .. "s"][slot_i])
        entry[which .. "s"][slot_i] = nil
        return out
    end
end

--- @brief
function rt.GameState:active_template_sort(entity)
    TODO: sort
end

for which in range(
    "hp",
    "attack",
    "defense",
    "speed"
) do
   rt.GameState["active_template_get_" .. which] = function(self, entity)
       local entry = self:_get_entity_entry(entity)
       local config = bt.EntityConfig(entry.id)

       local value = config[which .. "_base"]
       for i = 1, entry.n_equip_slots do
           local equip_id = entry.equips[i]
           if equip_id ~= nil then
               local equip_config = bt.EquipConfig(equip_id)
               value = value * equip_config["get_" .. which .. "_base_factor"](equip_config)
           end
       end

       for i = 1, entry.n_equip_slots do
           local equip_id = entry.equips[i]
           if equip_id ~= nil then
               local equip_config = bt.EquipConfig(equip_id)
               value = value + equip_config["get_" .. which .. "_base_offset"](equip_config)
           end
       end

       return value
   end
end

--- @brief active_template_get_hp, active_template_get_attack, active_template_get_defense, active_template_get_speed
function rt.GameState:active_template_get_hp(entity)
    local entry = self:_get_entity_entry(entity)
    local config = bt.EntityConfig(entry.id)

    local value = config.hp_base
    for i = 1, entry.n_equip_slots do
        local equip_id = entry.equips[i]
        if equip_id ~= nil then
            value = value * bt.EquipConfig(equip_id):get_hp_base_factor()
        end
    end

    for i = 1, entry.n_equip_slots do
        local equip_id = entry.equips[i]
        if equip_id ~= nil then
            value = value + bt.EquipConfig(equip_id):get_hp_base_offset()
        end
    end

    return value
end
---------------------

--- @brief
function rt.GameState:set_grabbed_object(object)
    if not (meta.isa(object, bt.MoveConfig) or meta.isa(object, bt.EquipConfig) or meta.isa(object, bt.ConsumableConfig)) then
        rt.error("In rt.GameState:set_grabbed_object: Objet `" .. meta.typeof(object) .. "` is not a bt.MoveConfig, bt.ConsumableConfig, or bt.EquipConfig")
        return
    end

    if self._grabbed_object ~= nil then
        if meta.isa(self._grabbed_object, bt.MoveConfig) then
            self:add_shared_move(self._grabbed_object)
        elseif meta.isa(self._grabbed_object, bt.EquipConfig) then
            self:add_shared_equip(self._grabbed_object)
        elseif meta.isa(self._grabbed_object, bt.ConsumableConfig) then
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