--- @brief
function bt.BattleScene:get_sprite(entity)
    for _, sprite in pairs(self._enemy_sprites) do
        if sprite._entity:get_id() == entity:get_id() then
            return sprite
        end
    end
end

--- @brief
--- @param animation_id String all caps, eg. "PLACEHOLDER_MESSAGE"
function bt.BattleScene:play_animation(entity, animation_id, ...)

    if bt.Animation[animation_id] == nil then
        rt.error("In bt.BattleScene:play_animation: no animation with id `" .. animation_id .. "`")
    end

    local sprite = self:get_sprite(entity)
    sprite:add_animation(bt.Animation[animation_id](self, sprite, ...))
end

--- @brief
function bt.BattleScene:get_entity(id)
    meta.assert_string(id)
    for entity in values(self._entities) do
        if entity:get_id() == id then
            return entity
        end
    end

    rt.error("In rt.BattleScene:get_entity: no entity with id `" .. id .. "`")
    return nil
end

--- @brief
function bt.BattleScene:kill(target_id)
    local target = self:get_entity(target_id)
    self:play_animation(target, "KILLED")
    table.clear(target.status)
    target.hp_current = 0
    target.priority = 0
    target.is_knocked_out = false
    target.is_dead = true
end

--- @brief
function bt.BattleScene:knock_out(target_id)
    local target = self:get_entity(target_id)

end