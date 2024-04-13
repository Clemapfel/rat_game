rt.settings.battle.simulation = {
    does_healing_cure_knock_out = true,
    help_up_hp_value = 1
}

--- @brief
function bt.BattleScene:get_sprite(entity)
    for _, sprite in pairs(self._enemy_sprites) do
        if sprite._entity:get_id() == entity:get_id() then
            return sprite
        end
    end
end

--- @brief [internal]
function bt.BattleScene:_fizzle_on_dead(target)
    self:play_animation(target, "MESSAGE",
        "Already Dead"
    )
end

--- @brief [internal]
function bt.BattleScene:_fizzle_on_knocked_out(target)
    self:play_animation(target, "MESSAGE",
        "Already Knocked Out"
    )
end

--- @brief
--- @param animation_id String all caps, eg. "PLACEHOLDER_MESSAGE"
function bt.BattleScene:play_animation(entity, animation_id, ...)

    if bt.Animation[animation_id] == nil then
        rt.error("In bt.BattleScene:play_animation: no animation with id `" .. animation_id .. "`")
    end

    local sprite = self:get_sprite(entity)
    local animation = bt.Animation[animation_id](self, sprite, ...)
    sprite:add_animation(animation)
    return animation, sprite
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

function bt.mutate_entity(entity, f, ...)
    meta.set_is_mutable(entity, true) -- lock
    f(entity, ...)
    meta.set_is_mutable(entity, false) -- unlock
end

--- @brief
function bt.BattleScene:end_turn()
    -- TODO: remove dead entities from priority queue and enemy sprites, also resolve game over
end

--- @brief
function bt.BattleScene:kill(target_id)
    -- assertion
    local target = self:get_entity(target_id)
    if not target:get_is_knocked_out() then
        rt.warning("In bt.BattleScene:kill: entity `" .. target_id .. "` was not knocked out before being killed")
    end

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
        return
    end

    -- animation
    local animation, sprite = self:play_animation(target, "KILLED")
    local statuses = {}
    for status, _ in pairs(target.status) do
        table.insert(statuses, status)
    end

    animation:register_start_callback(function()
        self:send_message(self:format_name(target) .. " was <b>killed</b>")
    end)

    animation:register_finish_callback(function()
        sprite:set_hp(0, target.hp_base)
        for status in values(statuses) do
            sprite:remove_status(status)
        end
        sprite:set_priority(0)
        sprite:set_state(bt.BattleEntityState.DEAD)

        sprite:set_ui_is_visible(false)
        self:get_priority_queue():set_state(sprite:get_entity(), bt.BattleEntityState.DEAD)
    end)

    -- simulation
    bt.mutate_entity(target, function(target)
        target.hp_current = 0
        table.clear(target.status)
        target.priority = 0
        target.state = bt.BattleEntityState.DEAD
    end)
end

--- @brief
function bt.BattleScene:knock_out(target_id)
    -- assertion
    local target = self:get_entity(target_id)
    if target:get_is_knocked_out() then
        self:play_animation(target, "MESSAGE",
            "Already Knocked Out!",
            self:format_name(target) .. " is already knocked out"
        )
        return
    end

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
        return
    end

    -- animation
    local animation, sprite = self:play_animation(target, "KNOCKED_OUT")
    local statuses = {}
    for status, _ in pairs(target.status) do
        table.insert(statuses, status)
    end

    animation:register_start_callback(function()
        self:send_message(self:format_name(target) .. " was <b><color=LIGHT_RED_3>knocked out</color></b>")
        sprite:set_hp(0, target.hp_base)
        self:get_priority_queue():set_state(sprite:get_entity(), bt.BattleEntityState.KNOCKED_OUT)
        for status in values(statuses) do
            sprite:remove_status(status)
        end
        sprite:set_priority(0)
        sprite:set_state(bt.BattleEntityState.KNOCKED_OUT)
    end)

    animation:register_finish_callback(function()
        sprite:set_is_visible(true)
        sprite:set_ui_is_visible(true)
    end)

    -- simulation
    bt.mutate_entity(target, function(target)
        target.hp_current = 0
        table.clear(target.status)
        target.priority = 0
        target.state = bt.BattleEntityState.KNOCKED_OUT
    end)
end

--- @brief
function bt.BattleScene:help_up(target_id)
    -- assertion
    local target = self:get_entity(target_id)
    
    if not target:get_is_knocked_out() then
        -- fizzle
        self:play_animation(target, "MESSAGE",
            "Not Knocked Out!",
            self:format_name(target) .. " is not knocked out and can't be helped up"
        )
        return
    end

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
        return
    end

    local value = rt.settings.battle.simulation.help_up_hp_value
    local animation, sprite = self:play_animation(target, "HELPED_UP")
    animation:register_start_callback(function()
        sprite:set_ui_is_visible(true)
        self:send_message(self:format_name(target) .. " is no longer knocked out")
        sprite:set_hp(value, target.hp_base)
        self:get_priority_queue():set_state(sprite:get_entity(), bt.BattleEntityState.ALIVE)
        sprite:set_priority(0)
        sprite:set_state(bt.BattleEntityState.ALIVE)
    end)
    
    -- simulation
    bt.mutate_entity(target, function(target)
        target.hp_current = value
        table.clear(target.status)
        target.priority = 0
        target.state = bt.BattleEntityState.ALIVE
    end)
end

--- @brief
function bt.BattleScene:add_hp(target_id, value)
    if value < 0 then
        self:reduce_hp(target_id, math.abs(value))
        return
    end

    if value == 0 then return end

    local target = self:get_entity(target_id)

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
        return
    end

    if target:get_is_knocked_out() then
        if rt.settings.battle.simulation.does_healing_cure_knock_out == true then
            self:help_up(target_id)
            -- no return
        else
            local she, her, hers, is = self:format_pronouns(target)
            self:play_animation(target, "MESSAGE", "Already Knocked Out",
                self:format_name(target) .. " can't be healed because " .. she .. " " .. is .. " knocked out")
            return
        end
    end

    local current = target:get_hp_current()
    local max = target:get_hp_base()
    local after = clamp(current + value, 1, max)
    local offset = math.abs(after - current)

    local animation, sprite = self:play_animation(target, "HP_GAINED", offset)
    animation:register_start_callback(function()
        sprite:set_ui_is_visible(true)
        sprite:set_hp(after, max)
        self:send_message(self:format_name(target) .. " gained " .. self:format_hp(offset))
    end)

    bt.mutate_entity(target, function(target)
        target.hp_current = after
    end)
end

--- @brief
function bt.BattleScene:reduce_hp(target_id, value)
    if value < 0 then
        self:add_hp(math.abs(value))
        return
    end
    if value == 0 then return end

    local target = self:get_entity(target_id)
    local current = target:get_hp()
    local after = clamp(target:get_hp() - value, 0)
    local offset = math.abs(current - after)

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
    else
        local animation, sprite = self:play_animation(target, "HP_LOST", offset)
        animation:register_start_callback(function()
            sprite:set_ui_is_visible(true)
            sprite:set_hp(after)
            self:send_message(self:format_name(target) .. " lost " .. self:format_damage(offset))
        end)

        if target:get_is_knocked_out() then
            self:kill(target_id)
        else
            if after <= 0 then
                self:knock_out(target_id)
            else
                bt.mutate_entity(target, function(target)
                    target.hp_current = after
                end)
            end
        end
    end
end
