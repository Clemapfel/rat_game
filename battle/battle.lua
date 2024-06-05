rt.settings.battle.battle = {
    config_path = "battle/configs/battles"
}

--- @class bt.Battle
bt.Battle = meta.new_type("Battle", function(id)
    local path = rt.settings.battle.battle.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Battle, {
        id = id,
        config = {},
        _path = path,
        _is_realized = false
    })
    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    background_id = "default",
    music_id = "default",

    turn_count = 0,
    entities = {},
    id_offsets = {},   -- Table<EntityID, Table<EntityHash>>

    global_status = {},
    current_move_selection = {
        user = nil,
        move = nil,
        targets = {}
    }
})

--- @brief
function bt.Battle:realize()
    if self._is_realized then return end

    -- don't use rt.load_config for fuzzy logic

    local path = self._path
    local chunk, error_maybe = love.filesystem.load(path)
    if error_maybe ~= nil then
        rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "`: " .. error_maybe)
    end

    local config = chunk()
    self._config = config
    local throw_on_unexpected = function(key, expected, got)
        rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "` for key `" .. key .. "`: expected `" .. expected .. "`, got `" .. got .. "`")
    end

    local function throw_if_not_id(key, value)
        if not meta.is_string(value) then
            rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "` for key `" .. key .. "`, expected ID, got `" .. tostring(key) .. "`")
        end
    end

    for id in range("background_id", "music_id") do
        if config[id] ~= nil then
            self[id] = config[id]
            throw_if_not_id(id, self[id])
        end
    end

    self.global_status = {}
    local key_id = "global_statuses"
    for id in values(config[key_id]) do
        throw_if_not_id(key_id, id)
        self:add_global_status(bt.GlobalStatus(id))
    end

    self.entities = {}
    key_id = "entities"
    if config[key_id] == nil or sizeof(config[key_id]) == 0 then
        rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "`: `entities` table is empty")
    end

    local i = 1
    for entry in values(config[key_id]) do
        if not meta.is_table(entry) or not meta.is_string(entry.id) then
            rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "`: `entities` table is malformatted, expected Table with entry `id`")
        end

        local id = entry.id
        local entity = bt.Entity(id)
        for status_id in values(entry.status) do
            entity:add_status(bt.Status(status_id))
        end

        for consumable_id in values(entry.consumables) do
            entity:add_consumable(bt.Consumable(consumable_id))
        end

        for equip_id in values(entry.equips) do
            entity:add_equip(bt.Equip(equip_id))
        end

        for move_id in values(entry.moveset) do
            entity:add_move(bt.Move(move_id))
        end

        self:add_entity(entity)
        i = i + 1
    end

    self:update_entity_id_offsets(true)
    self._is_realized = true
end

--- @brief
function bt.Battle:list_global_statuses()
    local out = {}
    for entry in values(self.global_status) do
        table.insert(out, entry.status)
    end
    return out
end

--- @brief
function bt.Battle:get_global_status(status_id)
    if self.global_status[status_id] == nil then return nil end
    return self.global_status[status_id].status
end

--- @brief
function bt.Battle:add_global_status(status)
    self.global_status[status:get_id()] = {
        elapsed = 0,
        status = status
    }
end

--- @brief
function bt.Battle:remove_global_status(status)
    local status_id = status:get_id()
    if self.global_status[status_id] == nil then
        rt.warning("In bt.Battle:remove_global_status: trying to remove global status `" .. status_id .. "`, but no such status is available")
    end
    self.global_status[status_id] = nil
end

--- @brief
function bt.Battle:get_global_status_n_turns_elapsed(status)
    local entry = self.global_status[status:get_id()]
    if entry ~= nil then
        return entry.elapsed
    else
        return 0
    end
end

--- @brief
--- @brief
function bt.Battle:get_global_status_n_turns_left(status)
    return clamp(status:get_max_duration() - self.global_status[status:get_id()].elapsed, 0)
end

--- @brief
function bt.Battle:global_status_advance(status)
    local entry = self.global_status[status:get_id()]
    if entry == nil then return false end

    entry.elapsed = entry.elapsed + 1
    return entry.elapsed
end

--- @brief
function bt.Battle:list_entities()
    local out = {}
    for entity in values(self.entities) do
        if not entity:get_is_dead() then
            table.insert(out, entity)
        end
    end
    return out
end

--- @brief
function bt.Battle:list_dead_entities()
    local out = {}
    for entity in values(self.entities) do
        if entity:get_is_dead() == true then
            table.insert(out, entity)
        end
    end
    return out
end

--- @brief
function bt.Battle:list_party()
    local out = {}
    for entity in values(self.entities) do
        if not entity:get_is_dead() and entity:get_is_enemy() == false then
            table.insert(out, entity)
        end
    end
    return out
end

--- @brief
function bt.Battle:list_enemies()
    local out = {}
    for entity in values(self.entities) do
        if not entity:get_is_dead() and entity:get_is_enemy() == true then
            table.insert(out, entity)
        end
    end
    return out
end

--- @brief
function bt.Battle:get_entity(entity_id)
    for entity in values(self.entities) do
        if entity == entity_id then
            return entity
        end
    end

    return nil
end

--- @brief [internal]
function bt.Battle:update_entity_id_offsets()
    for entity in values(self.entities) do
        if self.id_offsets[entity._config_id] == nil then
            self.id_offsets[entity._config_id] = {}
        end

        local offsets = self.id_offsets[entity._config_id]
        if offsets[meta.hash(entity)] == nil then
            offsets[meta.hash(entity)] = sizeof(offsets) + 1
        end
    end

    for entity in values(self.entities) do
        local offsets = self.id_offsets[entity._config_id]
        if sizeof(offsets) == 1 then
            entity:set_id_offset(0)
        else
            entity:set_id_offset(offsets[meta.hash(entity)])
        end
    end

    dbg(self.id_offsets)
end

--- @brief
function bt.Battle:get_entity_multiplicity(entity)
    local type = entity._config_id
    local n = 0
    for entity in values(self.entities) do
        if entity._config_id == type then
            n = n + 1
        end
    end
    return n
end

--- @brief
function bt.Battle:add_entity(entity)
    table.insert(self.entities, entity)
    self:update_entity_id_offsets()
end

--- @brief
function bt.Battle:remove_entity(to_remove)
    local removed = false
    for i, entity in ipairs(self.entities) do
        if entity == to_remove then
            table.remove(self.entities, i)
            removed = true
            break
        end
    end

    if not removed then
        rt.warning("In bt.Battle:remove_entity: trying to remove entity `" .. to_remove:get_id() .. "` but no such entity is available")
    end
end

--- @brief
function bt.Battle:replace_entity(to_remove, to_add)
    local replaced = false
    for i = 1, #self.entities do
        if self.entities[i] == to_remove then
            self.entities[i] = to_add
            replaced = true
            break
        end
    end

    if not replaced then
        rt.warning("In bt.Battle:replace_entity: trying to replace entity `" .. to_remove:get_id() .. "` but no such entity is available")
    end
end

--- @brief
function bt.Battle:list_entities_in_order()
    local entities = self:list_entities()

    table.sort(entities, function(a, b)
        if a:get_priority() == b:get_priority() then
            if a:get_speed() == b:get_speed() then
                return meta.hash(a) < meta.hash(b)
            else
                return a:get_speed() > b:get_speed()
            end
        else
            return a:get_priority() > b:get_priority()
        end
    end)

    return entities
end

--- @brief
function bt.Battle:list_stunned_entities()
    local out = {}

    for entity in values(self:list_entities()) do
        if entity:get_is_stunned() then
            table.insert(out, entity)
        end
    end

    return out
end

--- @brief
function bt.Battle:swap(left_i, right_i)
    local left = self.entities[left_i]
    local right = self.entities[right_i]

    self.entities[right_i] = left
    self.entities[left_i] = right
end

--- @brief
function bt.Battle:get_left_of(target)
    rt.warning("In bt.Battle:get_right_of: TODO currently returns index, but sprites are out of order")
    local i = 1
    for entity in values(self.entities) do
        if entity == target then
            return self.entities[i - 1]
        end
        i = i + 1
    end
    return nil
end

--- @brief
function bt.Battle:get_right_of(target)
    rt.warning("In bt.Battle:get_right_of: TODO currently returns index, but sprites are out of order")
    local i = 1
    for entity in values(self.entities) do
        if entity == target then
            return self.entities[i + 1]
        end
        i = i + 1
    end
    return nil
end

--- @brief
function bt.Battle:get_position(target)
    local i = 1
    for entity in values(self.entities) do
        if entity == target then
            return i
        end
        i = i + 1
    end
    return nil
end

--- @brief
function bt.Battle:clear_current_move_selection()
    self.current_move_selection_before = self.current_move_selection
    self.current_move_selection = {
        user = nil,
        move = nil,
        targets = {}
    }
end

--- @brief
function bt.Battle:restore_current_move_selection()
    self.current_move_selection = self.current_move_selection_before
    self.current_move_selection_before  = {
        user = nil,
        move = nil,
        targets = {}
    }
end

--- @brief
function bt.Battle:set_current_move_selection(user, move, targets)
    self.current_move_selection.user = user
    self.current_move_selection.move = move
    table.clear(self.current_move_selection.targets)
    while #self.current_move_selection.targets > 0 do
        table.remove(self.current_move_selection.targets)
    end
    for entity in values(targets) do
        table.insert(self.current_move_selection.targets, entity)
    end
end

--- @brief
function bt.Battle:reset_current_move_selection()
    self:set_current_move_selection(nil, nil, {})
end

--- @brief
function bt.Battle:get_current_move_user()
    return self.current_move_selection.user
end

--- @brief
function bt.Battle:get_current_move_targets()
    return self.current_move_selection.targets
end

--- @brief
function bt.Battle:get_current_move()
    return self.current_move_selection.move
end

--- @brief
--- @return Table<Table<Entity>>, all possible sets
function bt.Battle:get_possible_targets(user, move)
    local targets = {}

    local function is_enemy(other)
        return other:get_is_enemy() ~= user:get_is_enemy()
    end

    local function is_ally(other)
        return other:get_is_enemy() == user:get_is_enemy()
    end

    local me, enemies, allies = move.can_target_self, move.can_target_enemy, move.can_target_ally

    -- targets field
    if me == false and enemies == false and allies == false then
        return targets
    end

    -- targets entities
    if move.can_target_multiple == false then
        for entity in values(self:list_entities()) do
            if entity == user and me then
                table.insert(targets, {entity})
            elseif is_enemy(entity) and enemies then
                table.insert(targets, {entity})
            elseif is_ally(entity) and allies then
                table.insert(targets, {entity})
            end
        end
    else
        local to_insert = {}
        for entity in values(self:list_entities()) do
            if entity == user and me then
                table.insert(to_insert, {entity})
            elseif is_enemy(entity) and enemies then
                table.insert(to_insert, {entity})
            elseif is_ally(entity) and allies then
                table.insert(to_insert, {entity})
            end
        end
        table.insert(targets, to_insert)
    end

    return targets
end

