rt.settings.battle.battle = {
    config_path = "battle/configs/battles"
}

--- @class bt.Battle
bt.Battle = meta.new_type("Battle", function(id)
    local path = rt.settings.battle.battle.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Battle, {
        id = id,
        _path = path,
        _is_realized = false
    })
    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    entities = {},
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
    local throw_on_unexpected = function(key, expected, got)
        rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "` for key `" .. key .. "`: expected `" .. expected .. "`, got `" .. got .. "`")
    end

    local function throw_if_not_id(key, value)
        if not meta.string(self[id]) then
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
        rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "`: `entity` table is empty")
    end

    local i = 1
    for id in values(config[key_id]) do
        if meta.is_string(id) then
            self:add_entity(bt.Entity(id))
        else
            local entry = id

            if not meta.is_table(entry) and meta.is_string(entry.id) then
                rt.error("In rt.Battle:realize: error when loading config at `" .. path .. "`: `entity` table entry at `" .. i .. "` is not a table with key `id` that is an entity id")
            end

            local entity = bt.Entity(entry.id)
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
        end

        i = i + 1
    end

    self._is_realized = true
end


--- @brief
function bt.BattleState:list_global_statuses()
    local out = {}
    for entry in values(self.global_status) do
        table.insert(out, entry.status)
    end
    return out
end

--- @brief
function bt.BattleState:get_global_status(status_id)
    if self.global_status[status_id] == nil then return nil end
    return self.global_status[status_id].status
end

--- @brief
function bt.BattleState:add_global_status(status)
    self.global_status[status:get_id()] = {
        elapsed = 0,
        status = status
    }
end

--- @brief
function bt.BattleState:remove_global_status(status)
    local status_id = status:get_id()
    if self.global_status[status_id] == nil then
        rt.warning("In bt.BattleState:remove_global_status: trying to remove global status `" .. status_id .. "`, but no such status is available")
    end
    self.global_status[status_id] = nil
end

--- @brief
function bt.BattleState:get_global_status_n_turns_elapsed(status)
    local entry = self.global_status[status:get_id()]
    if entry ~= nil then
        return entry.elapsed
    else
        return 0
    end
end

--- @brief
function bt.BattleState:list_entities()
    local out = {}
    for entity in values(self.entities) do
        table.insert(out, entity)
    end
    return out
end

--- @brief
function bt.BattleState:get_entity(entity_id)
    for entity in values(self.entities) do
        if entity == entity_id then
            return entity
        end
    end

    return nil
end

--- @brief [internal]
function bt.BattleState:update_entity_id_offsets()
    local boxes = {}
    for entity in values(self.entities) do
        local type = entity._config_id
        if boxes[type] == nil then boxes[type] = {} end
        table.insert(boxes[type], entity)
    end

    for _, box in pairs(boxes) do
        if #box > 1 then
            for i, entity in ipairs(box) do
                entity:set_id_offset(i)
            end
        else
            box[1]:set_id_offset(0)
        end
    end
end

--- @brief
function bt.BattleState:get_entity_multiplicity(entity)
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
function bt.BattleState:add_entity(entity)
    table.insert(self.entities, entity)
    self:update_entity_id_offsets()
end

--- @brief
function bt.BattleState:remove_entity(entity_id)
    local removed = false
    for i, entity in ipairs(self.entities) do
        if entity:get_id() == entity_id then
            table.remove(self.entities, i)
            removed = true
            break
        end
    end

    if not removed then
        rt.warning("In bt.BattleState:remove_entity: trying to remove entity `" .. entity_id .. "` but no such entity is available")
    end
end

