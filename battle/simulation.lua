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

--- @brief [internal] unlock entity, mutate, then lock again
function bt.mutate_entity(entity, f, ...)
    meta.set_is_mutable(entity, true)
    f(entity, ...)
    meta.set_is_mutable(entity, false)
end

--- @brief [internal]
function bt.BattleScene:_invoke_status_callback(entity, status, callback_id, ...)
    local scene = self

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

    return bt.safe_invoke(status, callback_id, status_proxy, holder_proxy, table.unpack(targets))
end

-- ### SIMULATION ACTIONS ###

--- @brief
function bt.BattleScene:start_turn()
    self:play_animation(table.first(self._entities), "TURN_START")
    for target in values(self._entities) do
        for status in values(target:list_statuses()) do
            println(target:get_id(), status:get_id())
            if status.on_turn_start ~= nil then
                if not status.is_silent then
                    local animation, _ = self:play_animation(target, "STATUS_APPLIED", status)
                    animation:register_start_callback(function()
                        self:send_message(self:format_name(status) .. " activated on turn start")
                    end)
                end
                self:_invoke_status_callback(target, status, "on_turn_start")
            end
        end
    end
end

--- @brief
function bt.BattleScene:end_turn()
    -- TODO: remove dead entities from priority queue and enemy sprites, also resolve game over
end

--- @brief
function bt.BattleScene:use_move(user, move_id, targets)
    local move = user:get_move(move_id)
    if move == nil then
        rt.error("In bt.Battlescene:use_move: entity `" .. user:get_id() .. "` does not have move `" .. move_id .. "` in moveset")
        return
    end

    self._current_move_user = user
    self._current_move = move

    local n_left = user:get_move_n_uses_left(move_id)
    if n_left < 1 then
        self:play_animation(user, "MESSAGE",
            move:get_name() .. " FAILED",
            self:format_name(user) .. " tried to use <b>" .. move:get_name() .. "</b> but it has no uses left"
        )
        return
    end

    self:play_animation(user, "MESSAGE",
        move:get_name(),
        self:format_name(user) .. " used <b>" .. move:get_name() .. "</b>"
    )

    bt.mutate_entity(user, function(target)
        target.moveset[move_id].n_uses = n_left - 1
    end)

    local user_proxy = bt.EntityInterface(self, user)
    if meta.isa(targets, bt.BattleEntity) then
        targets = {targets}
    end

    local target_proxies = {}
    for target in values(targets) do
        table.insert(target_proxies, bt.EntityInterface(self, target))
    end

    bt.safe_invoke(move, "effect", user_proxy, table.unpack(target_proxies))
end

--- @brief
function bt.BattleScene:kill(target)
    -- assertion
    if not target:get_is_knocked_out() then
        rt.warning("In bt.BattleScene:kill: entity `" .. target:get_id() .. "` was not knocked out before being killed")
    end

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
        return
    end

    -- animation
    local animation, sprite = self:play_animation(target, "KILLED")
    local statuses = target:list_statuses()

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
function bt.BattleScene:knock_out(target)
    -- assertion
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
    local statuses = target:list_statuses()

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
function bt.BattleScene:help_up(target)
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
function bt.BattleScene:add_hp(target, value)
    if value < 0 then
        self:reduce_hp(target, math.abs(value))
        return
    end

    if value == 0 then return end

    if target:get_is_dead() then
        self:_fizzle_on_dead(target)
        return
    end

    if target:get_is_knocked_out() then
        if rt.settings.battle.simulation.does_healing_cure_knock_out == true then
            self:help_up(target)
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

    local animation, sprite = self:play_animation(target, "HP_GAINED", value)
    animation:register_start_callback(function()
        sprite:set_ui_is_visible(true)
        sprite:set_hp(after, max)
        self:send_message(self:format_name(target) .. " gained " .. self:format_hp(value))
    end)

    bt.mutate_entity(target, function(target)
        target.hp_current = after
    end)
end

--- @brief
function bt.BattleScene:reduce_hp(target, value)
    if value < 0 then
        self:add_hp(math.abs(value))
        return
    end
    if value == 0 then return end

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
            self:kill(target)
        else
            if after <= 0 then
                self:knock_out(target)
            else
                bt.mutate_entity(target, function(target)
                    target.hp_current = after
                end)
            end
        end
    end
end

--- @brief
function bt.BattleScene:add_status(target, status_id)
    local status = bt.Status(status_id)

    if target:get_status(status_id) ~= nil then
        if not status.is_silent then
            self:send_message(self:format_name(target) .. " already has " .. status:get_name())
        end
        return
    end

    if not status.is_silent then
        local animation, sprite = self:play_animation(target, "STATUS_GAINED", status)
        animation:register_start_callback(function()
            sprite:add_status(status)
            self:send_message(self:format_name(target) .. " gained " .. status:get_name())
        end)
    end

    bt.mutate_entity(target, function(target)
        target:add_status(status)
    end)

    if status.on_gained ~= nil then
        if not status.is_silent then
            local animation, _ = self:play_animation(target, "STATUS_APPLIED", status)
            animation:register_start_callback(function()
                self:send_message(self:format_name(status) .. " activated on being acquired")
            end)
        end
        self:_invoke_status_callback(target, status, "on_gained")
    end
end

--- @brief
function bt.BattleScene:remove_status(target, status_id)
    local status = target:get_status(status_id)

    if status == nil then
        status = bt.Status(status_id)
        self:send_message(self:format_name(target) .. " does not have " .. status:get_name())
        return
    end

    if not status.is_silent then
        local animation, sprite = self:play_animation(target, "STATUS_LOST", status)
        animation:register_start_callback(function()
            sprite:remove_status(status)
            self:send_message(self:format_name(target) .. " lost " .. status:get_name())
        end)
    end

    bt.mutate_entity(target, function(target)
        target:remove_status(status)
    end)

    if status.on_lost ~= nil then
        if not status.is_silent then
            local animation, _ = self:play_animation(target, "STATUS_APPLIED", status)
            animation:register_start_callback(function()
                self:send_message(self:format_name(status) .. " activated when fading")
            end)
        end
        self:_invoke_status_callback(target, status, "on_lost")
    end
end
