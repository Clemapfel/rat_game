rt.settings.battle.entity = {
    config_path = "assets/battle/entity"
}

--- @class
bt.Entity = meta.new_type("BattleEntity", function(id)
    local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Entity, {
        id = id,
        name = "UNINITIALIZED ENTITY @" .. path,

        _path = path,
        _is_realized = false
    })
    --meta.set_is_mutable(out, false)
    return out
end, {
    sprite_id = "",
    is_enemy = true,

    hp_base = 100,
    hp_current = 100,

    attack_base = 0,
    defense_base = 0,
    speed_base = 100,

    attack_modifier = 0,
    defense_modifier = 0,
    speed_modifier = 0,

    priority = 0
})

--- @brief
function bt.Entity:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Entity:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()

    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Entity:get_hp()
    return self.hp_current
end

--- @brief
function bt.Entity:get_hp_base()
    return self.hp_base
end

--- @brief
function bt.Entity:get_speed()
    return self.speed_base
end

--- @brief
function bt.Entity:get_speed_base()
    return self.speed_base
end