--- @class bt.BattleState
bt.BattleState = meta.new_type("BattleState", function(scene)
    return meta.new(bt.BattleState, {
        _scene = scene,
        _entities = {},      -- Table<bt.Entity>
        _status = {},        -- Table<GlobalStatusId, {status: bt.GlobalStatus, elapsed: Number}
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
        table.insert(out, entry._status)
    end
    return out
end

--- @brief
function bt.BattleState:get_global_status(status_id)
    if self._status[status_id] == nil then return nil end
    return self._status[status_id]._status
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
    return rt.random.shuffle(self:list_entities())
end


