rt.settings.battle.move = {
    config_path = "assets/battle/moves"
}

--- @class bt.Move
bt.Move = meta.new_type("Move", function(id)
    local path = rt.settings.battle.move.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Move, {
        id = id,
        name = "UNINITIALIZED MOVE @" .. path,
        _path = path,
        _is_realized = false
    })
    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    max_n_uses = POSITIVE_INFINITY,
    stance_alignment = bt.StanceAlignment.NONE,

    can_target_multiple = false,

    can_target_self = false,
    can_target_enemy = false,
    can_target_ally = false,
    -- targets_field = not (can_target_self or can_target_enemy or can_target_ally)

    priority = 0,

    effect = function(user, targets)
        meta.assert_isa(self, bt.Move)
        meta.assert_isa(user, bt.BattleEntity)
        meta.assert_isa(targets, bt.BattleEntity)
    end,

    sprite_id = "",
    sprite_index = 1,
    animation_id = "",
    animation_index = 1,

    description = "<No Effect>",
    bonus_description = "<No Bonus>"
})

--- @brief
function bt.Move:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Move:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()
    meta.set_is_mutable(self, true)

    -- numbers
    for which in range(
        "max_n_uses",
        "priority"
    ) do
        if config[which] ~= nil then
            self[which] = config[which]
            meta.assert_number(self[which])
        end
    end

    -- booleans
    for which in range(
        "can_target_multiple",
        "can_target_self",
        "can_target_enemy",
        "can_target_ally"
    ) do
        if config[which] ~= nil then
            self[which] = config[which]
            meta.assert_boolean(self[which])
        end
    end

    meta.assert_string(config.sprite_id)
    self.sprite_id = config.sprite_id
    if config.sprite_index ~= nil then
        self.sprite_index = config.sprite_index
    end

    meta.assert_string(config.animation_id)
    self.animation_id = config.animation_id
    if config.animation_index ~= nil then
        self.animation_index = config.animation_index
    end

    -- strings
    for which in range(
        "name",
        "description",
        "bonus_description",
        "stance_alignment"
    ) do
        if config[which] ~= nil then
            self[which] = config[which]
            meta.assert_string(self[which])
        end
    end

    -- behavior
    meta.assert_function(config.effect)
    self.effect = config.effect

    if config.bonus_effect ~= nil then
        self.bonus_effect = config.bonus_effect
        meta.assert_function(self.bonus_effect)
    end

    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Move:stance_matches(entity)
    if self.stance_alignment == bt.StanceAlignment.ALL then
        return true
    elseif self.stance_alignment == bt.StanceAlignment.NONE then
        return false
    else
        return entity:get_stance():matches_alignment(self.stance_alignment)
    end
end
