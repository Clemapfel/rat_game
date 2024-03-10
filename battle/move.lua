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
    meta.set_is_mutable(out, false)
    return out
end, {
    max_n_uses = POSITIVE_INFINITY,

    can_target_multiple = false,

    can_target_self = false,
    can_target_enemy = false,
    can_target_ally = false,
    -- targets_field = not (can_target_self or can_target_enemy or can_target_ally)

    priority = 0,
    effect = function(user, targets)
        meta.assert_isa(self, bt.Move)
        meta.assert_isa(user, bt.Entity)
        meta.assert_isa(targets, bt.Entity)
    end
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

    if config.max_n_uses ~= nil then
        self.max_n_uses = config.max_n_uses
    end
    meta.assert_number(self.max_n_uses)
    assert(self.max_n_uses > 0)

    local booleans = {
        "can_target_multiple",
        "can_target_self",
        "can_target_ally",
        "can_target_self"
    }

    for _, key in ipairs(booleans) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_boolean(self[key])
    end

    if config.priority ~= nil then
        self.priority = 0
    end
    meta.assert_number(self.priority)


    meta.assert_function(config.effect)
    self.effect = config.effect

    self._is_realized = true
    meta.set_is_mutable(self, false)
end