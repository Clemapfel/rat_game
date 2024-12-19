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
    meta.assert_string(id)
    if self._state.templates[id] == nil then
        rt.error("In rt.GameState.set_active_template: no template with id `" .. id .. "`")
    end
    self._state.active_template_id = id
end

function rt.GameState:_get_active_template()
    local out = self._state.templates[self._state.active_template_id]
    assert(out ~= nil)
    return out
end

function rt.GameState:_active_template_get_entity_entry(entity)
    meta.assert_isa(entity, bt.Entity)
    local template = self:_get_active_template()
    for i, entry in pairs(template.party) do
        if entry.id == entity:get_id() then
            return entry, i
        end
    end
    return nil
end

--- @brief
function rt.GameState:active_template_list_party()
    return self:template_list_party(self._state.active_template_id)
end

--- @brief
function rt.GameState:active_template_get_entity_index(entity)
    local entry, i = self:_active_template_get_entity_entry(entity)
    if entry == nil then
        rt.error("In rt.GameState.active_template_get_party_index: entity `" .. entity:get_id() .. "` is not present in template `" .. self:_get_active_template().name .. "`")
        return 0
    end
    return i
end

--- @brief
function rt.GameState:list_templates()
    local out = {}
    for id, entry in pairs(self._state.templates) do
        table.insert(out, mn.Template(self, id))
    end
    return out
end

--- @brief
function rt.GameState:active_template_get_party_size()
    return sizeof(self:_get_active_template().party)
end

for which_type in range(
    {"move", bt.MoveConfig},
    {"equip", bt.EquipConfig},
    {"consumable", bt.ConsumableConfig}
) do
    local which, type = table.unpack(which_type)

    --- @brief active_template_get_n_move_slots, active_template_get_n_equip_slots, active_template_get_n_consumable_slots
    rt.GameState["active_template_get_n_" .. which .. "_slots"] = function(self, entity)
        return self:_active_template_get_entity_entry(entity)["n_" .. which .. "_slots"]
    end

    --- @brief active_template_list_move_slots, active_template_list_equip_slots, active_template_list_consumable_slots
    rt.GameState["active_template_list_" .. which .. "_slots"] = function(self, entity)
        local entry = self:_active_template_get_entity_entry(entity)
        local out = {}
        local n = entry["n_" .. which .. "_slots"]
        for i = 1, n do
            local id = entry[which .. "s"][i]
            if id ~= nil then
                out[i] = type(id)
            end
        end

        return n, out
    end

    --- @brief active_template_get_move, active_template_get_equip, active_template_get_consumable
    rt.GameState["active_template_get_" .. which] = function(self, entity, slot_i)
        meta.assert_number(slot_i)
        local entry = self:_active_template_get_entity_entry(entity)
        local n = entry["n_" .. which .. "_slots"]
        if slot_i > n then
            rt.error("In rt.GameState.active_template_get_" .. which .. ": slot index `" .. slot_i .. "` is out of range for entity `" .. entry.id .. "` which has `" .. n .. "` slots")
        end
        local id = entry[which .. "s"][slot_i]
        if id == nil then return nil else return type(id) end
    end

    --- @brief active_template_get_first_free_move_slot, active_template_get_first_free_equip_slot, active_template_get_first_free_consumable_slot
    rt.GameState["active_template_get_first_free_" .. which .. "_slot"] = function(self, entity)
        local entry = self:_active_template_get_entity_entry(entity)
        for i = 1, entry["n_" .. which .. "_slots"] do
            if entry[which .. "s"][i] == nil then return i end
        end
        return nil
    end

    --- @brief active_template_has_move, active_template_has_equip, active_template_has_consumable
    rt.GameState["active_template_has_" .. which] = function(self, entity, object)
        local entry = self:_active_template_get_entity_entry(entity)
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
        local entry = self:_active_template_get_entity_entry(entity)
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
        local entry = self:_active_template_get_entity_entry(entity)
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
    local template = self:_get_active_template()
    for entry in values(template.party) do
        for which in range(
            "move",
            "consumable",
            "equip"
        ) do
            local sorted = {}
            local n = entry["n_" .. which .. "_slots"]
            local objects = entry[which .. "s"]

            for i = 1, n do
                if objects[i] ~= nil then
                    table.insert(sorted, objects[i])
                end
            end

            table.sort(sorted, function(a, b)
                return a:get_name() < b:get_name()
            end)

            for i = 1, n do
                objects[i] = sorted[i] -- may be nil
            end
        end
    end
end

for which in range(
    "hp",
    "attack",
    "defense",
    "speed"
) do
    --- @brief active_template_get_hp, active_template_get_attack, active_template_get_defense, active_template_get_speed
    rt.GameState["active_template_get_" .. which] = function(self, entity)
       local entry = self:_active_template_get_entity_entry(entity)
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

function rt.GameState:active_template_preview_equip(entity, slot_i, equip)
    local entry = self:_active_template_get_entity_entry(entity)

    if slot_i > entry.n_equip_slots then
        rt.error("In rt.GameState:active_template_preview_equip: equip slot `" .. slot_i .. "` is out of range for entity `" .. entity:get_id() .. "` which has " .. entry.n_equip_slots .. " slots")
        return 0, 0, 0, 0
    end
    local before = entry.equips[slot_i]

    entry.equips[slot_i] = equip
    local hp = self:active_template_get_hp(entity)
    local attack = self:active_template_get_attack(entity)
    local defense = self:active_template_get_defense(entity)
    local speed = self:active_template_get_speed(entity)

    entry.equips[slot_i] = before
    return hp, attack, defense, speed
end

function rt.GameState:template_create(name)
    meta.assert_string(name)

    local i = self._state.template_id_counter
    self._state.template_id_counter = self._state.template_id_counter + 1

    local suffix = ""
    if i < 10 then suffix = "00" elseif i < 100 then suffix = "0" end
    suffix = suffix .. i

    local id = "TEMPLATE_" .. suffix

    for id, template in pairs(self._state.templates) do
        if template.name == name then
            rt.warning("In rt.GameState:template_create: template `" .. id .. "` has the same name `" .. name .. "` as template `" .. id .. "`")
        end
    end

    assert(self._state.templates[id] == nil)
    self._state.templates[id] = {
        name = name,
        date = os.time(),
        party = {}
    }

    return mn.Template(self, id)
end

do
    function rt.GameState:_assert_template_exists(scope, id)
        meta.assert_string(scope, id)
        local template = self._state.templates[id]
        if template == nil then
            rt.error("In rt.GameState." .. scope .. ": no template with id `" .. id .. "`")
        end
        return template
    end
    
    function rt.GameState:load_template(id)
        if self:_assert_template_exists("load_template", id) ~= nil then
            self._state.active_template_id = id
        end
    end

    function rt.GameState:template_rename(id, new_name)
        meta.assert_string(new_name)
        if self:_assert_template_exists("template_rename", id) ~= nil then
            self._state.templates[id].name = new_name
        end
    end

    function rt.GameState:template_delete(id)
        if self:_assert_template_exists("template_delete", id) ~= nil then
            self._state.templates[id] = nil
        end
    end

    function rt.GameState:template_get_name(id)
        if self:_assert_template_exists("template_get_name", id) ~= nil then
            return self._state.templates[id].name
        end
        return ""
    end

    function rt.GameState:template_get_date(id)
        if self:_assert_template_exists("template_get_date", id) ~= nil then
            return os.date("%c",  self._state.templates[id].date)
        end
        return ""
    end

    function rt.GameState:template_list_party(id)
        local template = self:_assert_template_exists("template_list_entities", id)
        local out = {}
        for entry in values(template.party) do
            table.insert(out, bt.Entity(bt.EntityConfig(entry.id), 1))
        end
        return out
    end

    function rt.GameState:template_add_entity(id, entity_config, moves, equips, consumables)
        meta.assert_string(id)
        meta.assert_isa(entity_config, bt.EntityConfig)
        if moves == nil then moves = {} end
        if equips == nil then equips = {} end
        if consumables == nil then consumables = {} end

        local template = self:_assert_template_exists("template_add_entity", id)

        local new_i = 1
        for i, entry in pairs(template.party) do
            if entry.id == entity_config:get_id() then
                rt.warning("In rt.GameState:template_add_entity: template `" .. id .. "` already has an entry for entity `" .. entity_config:get_id() .. "`")
                break -- no error, replace
            end
            new_i = new_i + 1
        end

        local to_add = {
            id = entity_config:get_id(),
            n_move_slots = entity_config.n_move_slots,
            moves = {},
            n_equip_slots = entity_config.n_equip_slots,
            equips = {},
            n_consumable_slots = entity_config.n_consumable_slots,
            consumables = {}
        }
        template.party[new_i] = to_add

        for i, move in pairs(moves) do
            meta.assert_isa(move, bt.MoveConfig)
            if i > to_add.n_move_slots then
                rt.error("In rt.GameState.template_add_entity: entity `" .. entity_config:get_id() .. "` has `" .. to_add.n_move_slots .. "` slots, supplied move table has more entries")
                break
            end

            to_add.moves[i] = move:get_id()
        end

        for i, equip in pairs(equips) do
            meta.assert_isa(equip, bt.EquipConfig)
            if i > to_add.n_equip_slots then
                rt.error("In rt.GameState.template_add_entity: entity `" .. entity_config:get_id() .. "` has `" .. to_add.n_equip_slots .. "` slots, supplied equip table has more entries")
                break
            end

            to_add.equips[i] = equip:get_id()
        end

        for i, consumable in pairs(consumables) do
            meta.assert_isa(consumable, bt.ConsumableConfig)
            if i > to_add.n_consumable_slots then
                rt.error("In rt.GameState.template_add_entity: entity `" .. entity_config:get_id() .. "` has `" .. to_add.n_consumable_slots .. "` slots, supplied consumable table has more entries")
                break
            end

            to_add.consumables[i] = consumable:get_id()
        end
    end
end

for which_type in range(
    {"move", bt.MoveConfig},
    {"equip", bt.EquipConfig},
    {"consumable", bt.ConsumableConfig}
) do
    local which, Type = table.unpack(which_type)

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

function rt.GameState:initialize_debug_inventory()
    local moves = {
        "BOMB",
        "DEBUG_MOVE"
    }

    local equips = {
        "FAST_SHOES",
        "HELMET",
        "KITCHEN_KNIFE"
    }

    local consumables = {
        "SINGLE_CHERRY",
        "DOUBLE_CHERRY"
    }

    local entities = {
        bt.EntityConfig("MC"),
        bt.EntityConfig("PROF"),
        bt.EntityConfig("GIRL"),
        bt.EntityConfig("RAT")
    }

    rt.random.seed(0)

    local default_template = self:template_create("default")
    for entity_config in values(entities) do
        local current_moves, current_consumables, current_equips = {}, {}, {}

        local current_moves = {bt.MoveConfig("DEBUG_MOVE")}
        local move_i = 1
        for slot_i = 2, entity_config.n_move_slots do
            if rt.random.toss_coin(0.2) then
                current_moves[slot_i] = bt.MoveConfig(moves[move_i])
                move_i = move_i + 1
                if move_i > #moves then break end
            end
        end

        local current_consumables = {bt.ConsumableConfig("DEBUG_CONSUMABLE")}
        local consumable_i = 1
        for slot_i = 2, entity_config.n_consumable_slots do
            if rt.random.toss_coin(0.2) then
                current_consumables[slot_i] = bt.ConsumableConfig(consumables[consumable_i])
                consumable_i = consumable_i + 1
                if consumable_i > #consumables then break end
            end
        end

        local current_equips = {bt.EquipConfig("DEBUG_EQUIP")}
        local equip_i = 1
        for slot_i = 2, entity_config.n_equip_slots do
            if rt.random.toss_coin(0.2) then
                current_equips[slot_i] = bt.EquipConfig(equips[consumable_i])
                consumable_i = consumable_i + 1
                if consumable_i > #consumables then break end
            end
        end

        self:template_add_entity(
            default_template:get_id(),
            entity_config,
            current_moves,
            current_equips,
            current_consumables
        )
    end

    local empty_template = self:template_create("empty")
    local error_template = self:template_create("error")
    for entity in range(entities[1]) do
        self:template_add_entity(error_template:get_id(), entity,
            table.rep(bt.MoveConfig("DEBUG_MOVE"), 16),
            {},
            {}
        )
    end

    self._state.active_template_id = default_template:get_id()
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