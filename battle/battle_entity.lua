rt.settings.battle.entity = {
    config_path = "assets/battle/entities"
}

--- @class
bt.BattleEntity = meta.new_type("BattleEntity", function(scene, id)
    local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.BattleEntity, {
        id = id,
        id_offset = 0,
        name = "UNINITIALIZED ENTITY @" .. path,
        scene = scene,
        _path = path,
        _is_realized = false
    })
    out:realize()
    --meta.set_is_mutable(out, false)
    return out
end, {
    is_enemy = true,

    hp_base = 100,
    hp_current = 100,

    attack_base = 0,
    defense_base = 0,
    speed_base = 100,

    attack_modifier = 0,
    defense_modifier = 0,
    speed_modifier = 0,

    priority = 0,

    status = {}, -- Table<bt.Status>

    is_knocked_out = false,
    is_dead = false,

    -- non simulation
    sprite_id = "",
})

--- @brief
function bt.BattleEntity:realize()
    if self._is_realized then return end
    meta.set_is_mutable(self, true)

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.BattleEntity:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()

    local strings = {
        "name",
        "sprite_id"
    }

    for _, key in ipairs(strings) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
        meta.assert_string(self[key])
    end

    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.BattleEntity:get_is_enemy()
    return self.is_enemy
end

--- @brief
function bt.BattleEntity:set_id_offset(n)
    self.id_offset = n
end

--- @brief
function bt.BattleEntity:get_id()
    local offset = self.id_offset
    if offset == 0 then return self.id end
    return self.id .. "_" .. ternary(self.id_offset < 10, "0" .. offset,  offset)
end

--- @brief
function bt.BattleEntity:get_hp()
    return self.hp_current
end

--- @brief
function bt.BattleEntity:get_hp_base()
    return self.hp_base
end

--- @brief
function bt.BattleEntity:get_speed()
    return self.speed_base
end

--- @brief
function bt.BattleEntity:get_speed_base()
    return self.speed_base
end

--- @brief
function bt.BattleEntity:get_name()
    return self.name
end