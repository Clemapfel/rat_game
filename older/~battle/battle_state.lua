--- @class bt.BattleState
bt.BattleState = meta.new_type("BattleState", function(scene)
    return meta.new(bt.BattleState, {
        _scene = scene,
        _entities = {},      -- Table<bt.Entity>
        _status = {},        -- Table<GlobalStatusId, {status: bt.GlobalStatus, elapsed: Number}
        _current_move_selection = {
            user = nil,
            move = nil,
            targets = {}
        }
    })
end)

--- @brief
function bt.BattleState:list_entities()
    local out = {}
    for entity in values(self._entities) do
        table.insert(out, entity)
    end
    return out
end

--- @brief
function bt.BattleState:get_entity(entity_id)
    for entity in values(self._entities) do
        if entity == entity_id then
            return entity
        end
    end

    return nil
end

--- @brief [internal]
function bt.BattleState:update_entity_id_offsets()
    local boxes = {}
    for entity in values(self._entities) do
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
    for entity in values(self._entities) do
        if entity._config_id == type then
            n = n + 1
        end
    end
    return n
end

--- @brief
function bt.BattleState:add_entity(entity)
    table.insert(self._entities, entity)
    self:update_entity_id_offsets()
end

--- @brief
function bt.BattleState:remove_entity(entity_id)
    local removed = false
    for i, entity in ipairs(self._entities) do
        if entity:get_id() == entity_id then
            table.remove(self._entities, i)
            removed = true
            break
        end
    end

    if not removed then
        rt.warning("In bt.BattleState:remove_entity: trying to remove entity `" .. entity_id .. "` but no such entity is available")
    end
end

--- @brief
function bt.BattleState:list_global_statuses()
    local out = {}
    for entry in values(self._status) do
        table.insert(out, entry.status)
    end
    return out
end

--- @brief
function bt.BattleState:get_global_status(status_id)
    if self._status[status_id] == nil then return nil end
    return self._status[status_id].status
end

--- @brief
function bt.BattleState:add_global_status(status)
    self._status[status:get_id()] = {
        elapsed = 0,
        status = status
    }
end

--- @brief
function bt.BattleState:remove_global_status(status)
    local status_id = status:get_id()
    if self._status[status_id] == nil then
        rt.warning("In bt.BattleState:remove_global_status: trying to remove global status `" .. status_id .. "`, but no such status is available")
    end
    self._status[status_id] = nil
end

--- @brief
function bt.BattleState:get_global_status_n_turns_elapsed(status)
    local entry = self._status[status:get_id()]
    if entry ~= nil then
        return entry.elapsed
    else
        return 0
    end
end

--- @brief [internal] unlock entity, mutate, then lock again
function bt.BattleState:mutate_entity(entity, f, ...)
    meta.set_is_mutable(entity, true)
    f(entity, ...)
    meta.set_is_mutable(entity, false)
end

--- @brief [internal]
function bt.BattleState:_invoke_status_callback(entity, status, callback_id, ...)
    local scene = self._scene

    local holder_proxy = bt.EntityInterface(scene, entity)
    local status_proxy = bt.StatusInterface(scene, entity, status)
    local targets = {}

    for target in values({...}) do
        if meta.isa(target, bt.BattleEntity) then
            table.insert(targets, bt.EntityInterface(scene, target))
        elseif meta.isa(target, bt.Status) then
            table.insert(targets, bt.StatusInterface(scene, entity, target))
        else
            rt.error("In bt.invoke_status_callback: no interface available for unhandled argument type `" .. meta.typeof(target) .. "`")
        end
    end

    return bt.safe_invoke(self, status, callback_id, status_proxy, holder_proxy, table.unpack(targets))
end

--- @brief
function bt.BattleState:get_entities_in_order()
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
function bt.BattleState:swap(left_i, right_i)
    local left = self._entities[left_i]
    local right = self._entities[right_i]

    self._entities[right_i] = left
    self._entities[left_i] = right
end

--- @brief
function bt.BattleState:clear_current_move_selection()
    self._current_move_selection_before = self._current_move_selection
    self._current_move_selection = {
        user = nil,
        move = nil,
        targets = {}
    }
end

--- @brief
function bt.BattleState:restore_current_move_selection()
    self._current_move_selection = self._current_move_selection_before
    self._current_move_selection_before  = {
        user = nil,
        move = nil,
        targets = {}
    }
end

--- @brief
function bt.BattleState:set_current_move_selection(user, move, targets)
    self._current_move_selection.user = user
    self._current_move_selection.move = move
    table.clear(self._current_move_selection.targets)
    while #self._current_move_selection.targets > 0 do
        table.remove(self._current_move_selection.targets)
    end
    for entity in values(targets) do
        table.insert(self._current_move_selection.targets, entity)
    end
end

--- @brief
function bt.BattleState:get_current_move_user()
    return self._current_move_selection.user
end

--- @brief
function bt.BattleState:get_current_move_targets()
    return self._current_move_selection.targets
end

--- @brief
function bt.BattleState:get_current_move()
    return self._current_move_selection.move
end

