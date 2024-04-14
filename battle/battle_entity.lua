rt.settings.battle.entity = {
    config_path = "assets/battle/entities"
}

bt.BattleEntityState = meta.new_enum({
    ALIVE = "ALIVE",
    KNOCKED_OUT = "KNOCKED_OUT",
    DEAD = "DEAD"
})

bt.Gender = meta.new_enum({
    NEUTRAL = "NEUTRAL",
    MALE = "MALE",
    FEMALE = "FEMALE",
    MULTIPLE = "MULTIPLE",
    UNKNOWN = "UNKNOWN"
})

--- @class
bt.BattleEntity = meta.new_type("BattleEntity", function(scene, id)
    local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.BattleEntity, {
        id = id,
        id_offset = 0,
        name = "UNINITIALIZED ENTITY @" .. path,
        scene = scene,
        _path = path,
        _config_id = id,
        _is_realized = false,
    })

    out.status = {}
    out.moveset = {}

    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    is_enemy = true,

    hp_base = 100,
    hp_current = 100,

    attack_base = 0,
    defense_base = 0,
    speed_base = 100,

    priority = 0,
    status = {}, -- Table<bt.Status, Number>
    move = {}, -- Table<MoveID, {move: bt:move, n_uses: Number}>
    stance = bt.Stance("NEUTRAL"),

    state = bt.BattleEntityState.ALIVE,

    -- non simulation
    sprite_id = "",
    sprite_index = 1,

    knocked_out_sprite_id = nil,
    knocked_out_sprite_index = nil,

    dead_sprite_id = nil,
    dead_sprite_index = nil,

    gender = bt.Gender.UNKNOWN
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
        "sprite_id",
        "knocked_out_sprite_id",
        "dead_sprite_id"
    }

    for _, key in ipairs(strings) do
        if config[key] ~= nil then
            self[key] = config[key]
        end

        if self[key] ~= nil then
            meta.assert_string(self[key])
        end
    end

    local numbers = {
        "sprite_index",
        "knocked_out_index",
        "dead_sprite_index"
    }

    for _, key in ipairs(numbers) do
        if config[key] ~= nil then
            self[key] = config[key]
        end
    end

    self.knocked_out_sprite_id = which(self.knocked_out_sprite_id, self.sprite_id)
    self.knocked_out_index = which(self.knocked_out_sprite_index, self.sprite_index)
    self.dead_sprite_id = which(self.dead_sprite_id, self.sprite_id)
    self.dead_index = which(self.dead_sprite_index, self.sprite_index)

    if config.gender ~= nil then
        self.gender = config.gender
        meta.assert_enum(self.gender, bt.Gender)
    end

    -- TODO
    self.speed_base = rt.random.integer(1, 99)
    -- TODO

    config.moveset = which(config.moveset, {})
    for move_id in values(config.moveset) do
        local move = bt.Move(move_id)
        self.moveset[move_id] = {
            move = move,
            n_uses = move.max_n_uses
        }
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
    meta.set_is_mutable(self, true)
    self.id_offset = n
    meta.set_is_mutable(self, false)
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
function bt.BattleEntity:get_id_offset_suffix()
    if self.id_offset == 0 then
        return ""
    else
        return " " .. utf8.char(self.id_offset + 0x03B1 - 1) -- lowercase greek letters
    end
end

--- @brief
function bt.BattleEntity:get_name()
    return self.name .. self:get_id_offset_suffix()
end

--- @brief
function bt.BattleEntity:get_sprite_id()
    return self.sprite_id, self._sprite_index
end

--- @brief
function bt.BattleEntity:get_status_n_turns_elapsed(status)
    local id = status:get_id()
    return self.status[id].elapsed
end

--- @brief
function bt.BattleEntity:get_status(status_id)
    if self.status[status_id] == nil then return nil end
    return self.status[status_id].status
end

--- @brief
function bt.BattleEntity:add_status(status)
    self.status[status:get_id()] = {
        elapsed = 0,
        status = status
    }
end

--- @brief
function bt.BattleEntity:remove_status(status)
    self.status[status:get_id()] = nil
end

--- @brief
function bt.BattleEntity:get_stance()
    return self.stance
end

--- @brief
function bt.BattleEntity:get_state()
    return self.state
end

--- @brief
function bt.BattleEntity:get_is_knocked_out()
    return self.state == bt.BattleEntityState.KNOCKED_OUT
end

--- @brief
function bt.BattleEntity:get_is_dead()
    return self.state == bt.BattleEntityState.DEAD
end

--- @brief
function bt.BattleEntity:get_hp_current()
    return self.hp_current
end

--- @brief
function bt.BattleEntity:get_hp_base()
    return self.hp_base
end

--- @brief
function bt.BattleEntity:get_move(move_id)
    if self.status[move_id] == nil then return nil end
    return self.moveset[move_id].move
end

--- @brief
function bt.BattleEntity:get_move_n_uses_left(id)
    return self.moveset[id].n_uses
end