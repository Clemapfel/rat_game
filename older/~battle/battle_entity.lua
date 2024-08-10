rt.settings.battle.entity = {
    config_path = "battle/configs/entities"
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

--- @class bt.BattleEntity
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
    out.moves = {}
    out.equips = {}
    out.consumables = {}

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
    stance = bt.Stance("NEUTRAL"),

    status = {}, -- Table<bt.Status, {status: bt.Status, elapsed: Number}>
    moves = {}, -- Table<MoveID, {move: bt:move, n_uses: Number}>
    equips = {}, -- Table<EquipID, {equip: bt.Equip}>
    consumables = {}, --Table<ConsumableID, {consumable: bt.Consumable, n_consumed: Number}

    state = bt.BattleEntityState.ALIVE,

    max_n_uses = POSITIVE_INFINITY,
    restore_uses_after_battle = true,

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
    if self._is_realized == true then return end
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

    config.moves = which(config.moves, {})
    for move_id in values(config.moves) do
        local move = bt.Move(move_id)
        self:add_move(move)
    end

    if not meta.is_table(config.equips) then config.equips = {config.equips} end
    for equip_id in values(config.equips) do
        if not meta.is_string(equip_id) then
            rt.error("In bt.BattleEntity:realize: error when loading config at `" .. self._path .. "`, expected string for id in `equip`, got: `" .. meta.typeof(equip_id) .. "`")
        end
        self:add_equip(bt.Equip(equip_id))
    end

    if not meta.is_table(config.consumables) then config.consumables = {config.consumables} end
    for consumable_id in values(config.consumables) do
        if not meta.is_string(consumable_id) then
            rt.error("In bt.BattleEntity:realize: error when loading config at `" .. self._path .. "`, expected string for id in `consumables`, got: `" .. meta.typeof(equip_id) .. "`")
        end
        self:add_consumable(bt.Consumable(consumable_id))
    end

    self._is_realized = true
    meta.set_is_mutable(self, false)
end

--- @brief calculate value of state, takes into account all statuses
function bt.BattleEntity:_calculate_stat(which)
    local value = self["get_" .. which .. "_base"](self)

    -- additive
    for entry in values(self.status) do
        local status = entry.status
        value = value + status[which .. "_offset"]
    end

    -- multiplicative
    for entry in values(self.status) do
        local status = entry.status
        value = value * status[which .. "_factor"]
    end

    for entry in values(self.equips) do
        local equip = entry.equip
        value = value * equip[which .. "_factor"]
    end

    return value
end

--- @brief
function bt.BattleEntity:_calculate_stat_base(which)
    local value = self[which .. "_base"]
    for entry in values(self.equips) do
        local equip = entry.equip
        value = value + equip[which .. "_base_offset"]
    end

    if value < 0 then value = 1 end
    return value
end

--- @brief
function bt.BattleEntity:get_attack_base_raw()
    return self.attack_base
end

--- @brief
function bt.BattleEntity:get_defense_base_raw()
    return self.defense_base
end

--- @brief
function bt.BattleEntity:get_speed_base_raw()
    return self.speed_base
end

--- @brief
function bt.BattleEntity:get_attack_base()
    return self:_calculate_stat_base("attack")
end

--- @brief
function bt.BattleEntity:get_defense_base()
    return self:_calculate_stat_base("defense")
end

--- @brief
function bt.BattleEntity:get_speed_base()
    return self:_calculate_stat_base("speed")
end

--- @brief
function bt.BattleEntity:get_attack()
    return self:_calculate_stat("attack")
end

--- @brief
function bt.BattleEntity:get_defense()
    return self:_calculate_stat("defense")
end

--- @brief
function bt.BattleEntity:get_speed()
    return self:_calculate_stat("speed")
end

--- @brief
function bt.BattleEntity:get_priority()
    return self.priority
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
    local value = self.hp_base
    for entry in values(self.equippables) do
        local equip = entry.equip
        value = value + equip.hp_base_offset
    end

    if value < 0 then value = 1 end
    return value
end

--- @brief
function bt.BattleEntity:get_hp_base_raw()
    return self.hp_base
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
function bt.BattleEntity:get_id_offset()
    return self.id_offset
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
function bt.BattleEntity:list_statuses()
    local out = {}
    for entry in values(self.status) do
        table.insert(out, entry.status)
    end
    return out
end

--- @brief
function bt.BattleEntity:clear_statuses()
    for id in keys(self.status) do
        self.status[id] = nil
    end
end

--- @brief
function bt.BattleEntity:has_status(status)
    return self.status[status:get_id()] ~= nil
end

--- @brief
function bt.BattleEntity:get_is_stunned(status)
    for entry in values(self.status) do
        if entry.status.is_stun == true then
            return true
        end
    end
    return false
end

--- @brief
--- @return Boolean true if status is past its intended duration, false otherwise
function bt.BattleEntity:increase_status_elapsed(status)
    local entry = self.status[status:get_id()]
    if entry == nil then
        rt.warning("In bt.BattleEntity:increase_status_elapsed: entity `" .. self:get_id() .. "` does not have status `" .. status:get_id() .. "`")
        return false
    else
        entry.elapsed = entry.elapsed + 1
        return entry.elapsed >= status:get_max_duration()
    end
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
function bt.BattleEntity:get_is_alive()
    return (not self:get_is_knocked_out()) and (not self:get_is_dead())
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
    if self.moves[move_id] == nil then return nil end
    return self.moves[move_id].move
end

--- @brief
function bt.BattleEntity:get_move_n_uses_left(id)
    return self.moves[id].n_uses
end

--- @brief
function bt.BattleEntity:add_move(move)
    self.moves[move:get_id()] = {
        move = move,
        n_uses = move.max_n_uses
    }
end

--- @brief
function bt.BattleEntity:has_move(move)
    return self.moves[move:get_id()] ~= nil
end

--- @brief
--- @return Boolean true if move is depleted, false otherwise
function bt.BattleEntity:consume_move(move)
    local entry = self.moves[move:get_id()]
    if entry == nil then
        rt.warning("In bt.BattleEntity:consume_move: entity `" .. self:get_id() .. "` does not have move `" .. move:get_id() .. "` equipped")
        return false
    else
        entry.n_uses = entry.n_uses - 1
        return entry.n_uses <= 0
    end
end
--- @brief
function bt.BattleEntity:add_equip(equip)
    self.equips[equip:get_id()] = {
        equip = equip
    }
end

--- @brief
function bt.BattleEntity:get_equip(equip_id)
    local entry = self.equips[equip_id]
    if entry == nil then
        return nil
    else
        return entry.equip
    end
end

--- @brief
function bt.BattleEntity:list_equips()
    local out = {}
    for entry in values(self.equips) do
        table.insert(out, entry.equip)
    end
    return out
end

--- @brief
function bt.BattleEntity:has_equip(equip)
    return self.equips[equip:get_id()] ~= nil
end

--- @brief
function bt.BattleEntity:add_consumable(consumable)
    self.consumables[consumable:get_id()] = {
        consumable = consumable,
        n_consumed = 0
    }
end

--- @brief
function bt.BattleEntity:remove_consumable(consumable)
    self.consumables[consumable:get_id()] = nil
end

--- @brief
function bt.BattleEntity:get_consumable(consumable_id)
    return self.consumables[consumable_id].consumable
end

--- @brief
function bt.BattleEntity:get_consumable_n_consumed(consumable_id)
    local entry = self.consumables[consumable_id]
    if entry == nil then
        return 0
    else
        return entry.n_consumed
    end
end

--- @brief
function bt.BattleEntity:get_consumable_n_uses_left(consumable)
    local entry = self.consumables[consumable:get_id()]
    if entry == nil then return 0 end
    return clamp(consumable:get_max_n_uses() - entry.n_consumed, 0)
end

--- @brief
function bt.BattleEntity:has_consumable(consumable)
    return self.consumables[consumable:get_id()] ~= nil
end

--- @brief
function bt.BattleEntity:list_consumables()
    local out = {}
    for entry in values(self.consumables) do
        table.insert(out, entry.consumable)
    end

    return out
end

--- @brief
function bt.BattleEntity:consume_consumable(consumable)
    local entry = self.consumables[consumable:get_id()]
    if entry == nil then
        rt.warning("In bt.BattleEntity:consume_move: entity `" .. self:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equipped")
        return false
    else
        entry.n_consumed = entry.n_consumed + 1
        return entry.n_consumed >= entry.consumable:get_max_n_uses()
    end
end