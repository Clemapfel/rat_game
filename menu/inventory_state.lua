mn.Template = meta.new_type("MenuTemplate", function(name)
    meta.assert_string(name)
    return meta.new(mn.Template, {
        name = name,
        grabbed_object = nil,
        entities = {}
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
function mn.Template:get_sprite_id()
    return "orbs", "generic_overlay"
end

--- @brie
function mn.Template:get_name()
    return self.name
end


--- @class mn.InventoryState
mn.InventoryState = meta.new_type("MenuInventoryState", function()
    local self = meta.new(mn.InventoryState, {
        shared_moves = {},          -- Table<bt.Move, Integer>
        shared_consumables = {},    -- Table<bt.Consumable, Integer>
        shared_equips = {},         -- Table<bt.Equip, Integer>
        templates = {},             -- Table<mn.Template>
        active = mn.Template("Active Template")      -- mn.Template
    })

    -- setup debug
    for move_id in range(
        "DEBUG_MOVE",
        "INSPECT",
        "PROTECT",
        "STRUGGLE",
        "SURF",
        "WISH"
    ) do
        local n = rt.random.integer(1, 5)
        for i = 1, n do
            self:add_shared_move(bt.Move(move_id))
        end
    end

    for equip_id in range(
        "DEBUG_EQUIP",
        "DEBUG_CLOTHING",
        "DEBUG_FEMALE_CLOTHING",
        "DEBUG_MALE_CLOTHING",
        "DEBUG_WEAPON",
        "DEBUG_TRINKET"
    ) do
        local n = rt.random.integer(1, 5)
        for i = 1, n do
            self:add_shared_equip(bt.Equip(equip_id))
        end
    end

    for consumable_id in range(
        "DEBUG_CONSUMABLE",
        "ONE_CHERRY",
        "TWO_CHERRY"
    ) do
        local n = rt.random.integer(1, 5)
        for i = 1, n do
            self:add_shared_consumable(bt.Consumable(consumable_id))
        end
    end

    local entities = {
        bt.Entity("MC"),
        bt.Entity("GIRL")
    }

    local empty_template = mn.Template("Empty Template")
    empty_template:create_from(table.unpack(entities))
    self:add_template(empty_template)

    self.active = mn.Template("Active Template")
    self.active:create_from(table.unpack(entities))

    for entity in values(entities) do
        self:add_equipped_move(entity, 2, bt.Move("DEBUG_MOVE"))
        self:add_equipped_move(entity, 4, bt.Move("WISH"))

        self:add_equipped_equip(entity, 1, bt.Equip("DEBUG_EQUIP"))
        self:add_equipped_consumable(entity, 1, bt.Consumable("DEBUG_CONSUMABLE"))
    end
    return self
end)


--- @brief
function mn.InventoryState:serialize()
    local to_serialize = {}
    to_serialize.shared_moves = {}
    for move, quantity in pairs(self.shared_moves) do
        to_serialize.shared_moves[move:get_id()] = quantity
    end

    to_serialize.shared_equips = {}
    for equip, quantity in pairs(self.shared_equips) do
        to_serialize.shared_equips[equip:get_id()] = quantity
    end

    to_serialize.shared_consumables = {}
    for consumable, quantity in pairs(self.shared_consumables) do
        to_serialize.shared_consumables[consumable:get_id()] = quantity
    end

    local serialize_template = function(template)
        local out = {}
        out.name = template.name
        out.entities = {}
        for entity, setup in pairs(template.entities) do
            local entity_to_push = {}

            entity_to_push.n_move_slots = setup.n_move_slots
            entity_to_push.moves = {}
            for i = 1, setup.n_move_slots do
                local object = setup.moves[i]
                if object ~= nil then
                    entity_to_push.moves[i] = object:get_id()
                end
            end

            entity_to_push.n_equip_slots = setup.n_equip_slots
            entity_to_push.equips = {}
            for i = 1, setup.n_equip_slots do
                local object = setup.equips[i]
                if object ~= nil then
                    entity_to_push.equips[i] = object:get_id()
                end
            end

            entity_to_push.n_consumable_slots = setup.n_consumable_slots
            entity_to_push.consumables = {}
            for i = 1, setup.n_consumable_slots do
                local object = setup.consumables[i]
                if object ~= nil then
                    entity_to_push.consumables[i] = object:get_id()
                end
            end

            out.entities[entity:get_id()] = entity_to_push
        end

        return out
    end

    to_serialize.templates = {}
    for template in values(self.templates) do
        table.insert(to_serialize.templates, serialize_template(template))
    end

    to_serialize.active = serialize_template(self.active)
    return "return " .. serialize(to_serialize)
end

function mn.InventoryState:deserialize(str)
    local chunk, error_maybe = load(str)
    if error_maybe ~= nil then
        rt.error("In mn.InventoryState:deserialize: syntax error: " .. error_maybe)
    end

    local parsed = chunk()
    self.shared_moves = {}
    for id, quantity in pairs(parsed.shared_moves) do
        self.shared_moves[bt.Move(id)] = quantity
    end

    self.shared_equips = {}
    for id, quantity in pairs(parsed.shared_equips) do
        self.shared_equips[bt.Equip(id)] = quantity
    end

    self.shared_consumables = {}
    for id, quantity in pairs(parsed.shared_consumables) do
        self.shared_consumables[bt.Consumable(id)] = quantity
    end

    local deserialize_template = function(parsed)
        local template = mn.Template()
        template.name = parsed.name
        for entity_id, setup in pairs(parsed.entities) do
            local to_insert = {
                moves = {},
                n_move_slots = setup.n_move_slots,

                equips = {},
                n_equip_slots = setup.n_equip_slots,

                consumables = {},
                n_consumable_slots = setup.n_consumable_slots
            }

            for slot_i, move_id in pairs(setup.moves) do
                to_insert.moves[slot_i] = bt.Move(move_id)
            end

            for slot_i, equip_id in pairs(setup.equips) do
                to_insert.equips[slot_i] = bt.Equip(equip_id)
            end

            for slot_i, consumable_id in pairs(setup.consumables) do
                to_insert.consumables[slot_i] = bt.Consumable(consumable_id)
            end

            template.entities[bt.Entity(entity_id)] = to_insert
        end
        return template
    end

    self.templates = {}
    for template in values(parsed.templates) do
        table.insert(self.templates, deserialize_template(template))
    end

    self.active = deserialize_template(parsed.active)
    return self
end

for which in range("move", "equip", "consumable") do
    --- @brief
    mn.InventoryState["add_shared_" .. which] = function(self, object)
        local shared_name = "shared_" .. which .. "s"
        local current = self[shared_name][object]
        if current == nil then
            self[shared_name][object] = 1
        else
            self[shared_name][object] = current + 1
        end
    end

    --- @brief
    mn.InventoryState["take_shared_" .. which] = function(self, object)
        local shared_name = "shared_" .. which .. "s"

        local current = self[shared_name][object]
        if current == nil then
            rt.error("In mn.InventoryState.take_shared_" .. which .. ": `" .. object:get_id() .. "` not in shared inventory")
            return nil
        end

        if current == 1 then
            self[shared_name][object] = nil
        else
            self[shared_name][object] = current - 1
        end

        return object
    end

    --- @brief
    mn.InventoryState["take_equipped_" .. which] = function(self, entity, slot_i)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)
        local setup = self.active.entities[entity]
        if setup == nil then
            rt.error("In mn.InventoryState.take_equipped_" .. which .. ": no entity with id `" .. entity:get_id() .. "`")
        end

        local taken = false
        local object = setup[which .. "s"][slot_i]
        setup[which .. "s"][slot_i] = nil
        taken = object ~= nil

        if not taken then
            rt.error("In mn.InventoryState.take_equipped_" .. which .. ": entity `" .. entity:get_id() .. "` does not have `" .. object:get_id() .. "` equipped")
        end
        return object
    end

    --- @brief
    mn.InventoryState["add_equipped_" .. which] = function(self, entity, slot_i, object)
        meta.assert_isa(entity, bt.Entity)
        meta.assert_number(slot_i)
        local setup = self.active.entities[entity]
        if setup == nil then
            rt.error("In mn.InventoryState.take_equipped_" .. which .. ": no entity with id `" .. entity:get_id() .. "`")
        end

        local current = setup[which .. "s"][slot_i]
        if current ~= nil then
            if meta.isa(self.grabbed_object, bt.Move) then
                self:add_shared_move(current)
            elseif meta.isa(self.grabbed_object, bt.Equip) then
                self:add_shared_equip(current)
            elseif meta.isa(self.grabbed_object, bt.Consumable) then
                self:add_shared_consumable(current)
            end
        end

        setup[which .. "s"][slot_i] = object
    end

    --- @brief
    mn.InventoryState["entity_has_" .. which] = function(self, entity, object)
        meta.assert_isa(entity, bt.Entity)
        if object == nil then return false end
        local setup = self.active.entities[entity]
        if setup == nil then
            rt.error("In mn.InventoryState.entity_has_" .. which .. ": entity `" .. entity:get_id() .. "` is not part of state")
        end
        local n = setup["n_" .. which .. "_slots"]
        for i = 1, n do
            if setup[which .. "s"][i] == object then return true end
        end
        return false
    end

    --- @brief
    mn.InventoryState["entity_get_first_free_" .. which .. "_slot"] = function(self, entity)
        meta.assert_isa(entity, bt.Entity)
        local setup = self.active.entities[entity]
        if setup == nil then return nil end
        local n = setup["n_" .. which .. "_slots"]
        for i = 1, n do
            if setup[which .. "s"][i] ==  nil then
                return i
            end
        end

        return nil
    end

    --- @brief
    mn.InventoryState["entity_get_n_" .. which .. "_slots"] = function(self, entity)
        meta.assert_isa(entity, bt.Entity)
        local setup = self.active.entities[entity]
        if setup == nil then return 0 end
        return setup["n_" .. which .. "_slots"]
    end

    --- @brief
    mn.InventoryState["entity_list_" .. which .. "_slots"] = function(self, entity)
        local out = {}
        local setup = self.active.entities[entity]
        if setup == nil then return nil end
        local n = setup["n_" .. which .. "_slots"]
        for i = 1, n do
            out[i] = setup[which .. "s"][i]
        end

        return n, out
    end
end

function mn.InventoryState:add_shared_object(object)
    if meta.isa(object, bt.Move) then
        self:add_shared_move(object)
    elseif meta.isa(object, bt.Equip) then
        self:add_shared_equip(object)
    elseif meta.isa(object, bt.Consumable) then
        self:add_shared_consumable(object)
    else
        rt.error("In mn.InventoryState.add_shared_object: unsupported object type `" .. meta.typeof(object) .. "`")
    end
end

--- @brief
function mn.InventoryState:set_grabbed_object(object)
    if self.grabbed_object ~= nil then
        if meta.isa(self.grabbed_object, bt.Move) then
            self:add_shared_move(self.grabbed_object)
        elseif meta.isa(self.grabbed_object, bt.Equip) then
            self:add_shared_equip(self.grabbed_object)
        elseif meta.isa(self.grabbed_object, bt.Consumable) then
            self:add_shared_consumable(self.grabbed_object)
        else
            rt.error("In mn.InventoryState.set_grabbed_object: unhandling item type `" .. meta.typeof(self.grabbed_object) .. "`")
        end
        self.grabbed_object = nil
    end

    self.grabbed_object = object
end

--- @brief
--- @return Table<bt.Move>, Table<bt.Equip>, Table<bt.Consumable>
function mn.InventoryState:entity_sort_inventory(entity)
    meta.assert_isa(entity, bt.Entity)

    local moves = {}
    local equips = {}
    local consumables = {}
    local setup = self.active.entities[entity]
    if setup == nil then
        rt.error("In mn.InventoryState.entity_sort_inventory: entity `" .. entity:get_id() .. "` is not part of state")
    end

    for i = 1, setup.n_move_slots do
        if setup.moves[i] ~= nil then
            table.insert(moves, setup.moves[i])
        end
        setup.moves[i] = nil
    end

    for i = 1, setup.n_equip_slots do
        if setup.equips[i] ~= nil then
            table.insert(equips, setup.equips[i])
        end
        setup.equips[i] = nil
    end

    for i = 1, setup.n_consumable_slots do
        if setup.consumables[i] ~= nil then
            table.insert(consumables, setup.consumables[i])
        end
        setup.consumables[i] = nil
    end

    for i, move in ipairs(moves) do
        setup.moves[i] = move
    end

    for i, equip in ipairs(equips) do
        setup.equips[i] = equip
    end

    for i, consumable in ipairs(consumables) do
        setup.consumables[i] = consumable
    end

    return moves, equips, consumables
end

--- @brief
function mn.InventoryState:take_grabbed_object()
    local out = self.grabbed_object
    self.grabbed_object = nil
    return out
end

--- @brief
function mn.InventoryState:peek_grabbed_object()
    return self.grabbed_object
end

--- @brief
function mn.InventoryState:add_template(template)
    meta.assert_isa(template, mn.Template)
    table.insert(self.templates, template)
end

--- @brief
function mn.InventoryState:load_template(template)
    meta.assert_isa(template, mn.Template)
    self.active = template
end

--- @brief synch .active with entities
function mn.InventoryState:export()
    for entity, setup in pairs(self.active.entities) do
        for slot_i = 1, setup.n_move_slots do
            local move = setup.moves[slot_i]
            entity:add_move(move, slot_i)
        end

        for slot_i = 1, setup.n_equip_slots do
            local equip = setup.equips[slot_i]
            entity:add_equip(equip, slot_i)
        end

        for slot_i = 1, setup.n_consumable_slots do
            local consumable = setup.consumables[slot_i]
            entity:add_consumable(consumable, slot_i)
        end
    end
end

--- @brief
function mn.InventoryState:list_entities()
    local out = {}
    for entity in keys(self.active.entities) do
        table.insert(out, entity)
    end
    return out
end

--- @brief
function mn.InventoryState:list_shared_moves()
    local out = {}
    for move, quantity in pairs(self.shared_moves) do
        out[move] = quantity
    end
    return out
end

--- @brief
function mn.InventoryState:list_shared_equips()
    local out = {}
    for equip, quantity in pairs(self.shared_equips) do
        out[equip] = quantity
    end
    return out
end

--- @brief
function mn.InventoryState:list_shared_consumables()
    local out = {}
    for consumable, quantity in pairs(self.shared_consumables) do
        out[consumable] = quantity
    end
    return out
end

--- @brief
function mn.InventoryState:list_templates()
    local out = {}
    for template in values(self.templates) do
        table.insert(out, template)
    end
    return out
end

--- @brief
function mn.InventoryState:get_n_entities()
    return sizeof(self.active.entities)
end

--- @brief
function mn.InventoryState:get_move_at(entity, move_slot_i)
    meta.assert_isa(entity, bt.Entity)
    local setup = self.active.entities[entity]
    if setup == nil then return nil end
    if move_slot_i > setup.n_move_slots then
        rt.error("In mn.InventoryState:get_move_at: slot `" .. move_slot_i .. "` is out of bounds for an entity with `" .. setup.n_move_slots .. "` slots")
    end
    return setup.moves[move_slot_i]
end

--- @brief
function mn.InventoryState:get_equip_at(entity, equip_slot_i)
    meta.assert_isa(entity, bt.Entity)
    local setup = self.active.entities[entity]
    if setup == nil then return nil end
    if equip_slot_i > setup.n_equip_slots then
        rt.error("In mn.InventoryState:get_equip_at: slot `" .. equip_slot_i .. "` is out of bounds for an entity with `" .. setup.n_equip_slots .. "` slots")
    end
    return setup.equips[equip_slot_i]
end

--- @brief
function mn.InventoryState:get_consumable_at(entity, consumable_slot_i)
    meta.assert_isa(entity, bt.Entity)
    local setup = self.active.entities[entity]
    if setup == nil then return nil end
    if consumable_slot_i > setup.n_consumable_slots then
        rt.error("In mn.InventoryState:get_consumable_at: slot `" .. consumable_slot_i .. "` is out of bounds for an entity with `" .. setup.n_consumable_slots .. "` slots")
    end
    return setup.consumables[consumable_slot_i]
end

--- @brief
function mn.InventoryState:take_shared_move(move)
    local current = self.shared_moves[move]
    if current == nil then
        rt.error("In mn.InventoryState.take_shared_move: move `" .. move:get_id() .. "` not in shared inventory")
        return nil
    end

    if current == 1 then
        self.shared_moves[move] = nil
    else
        self.shared_moves[move] = current - 1
    end

    return move
end




