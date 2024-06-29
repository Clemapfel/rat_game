rt.settings.battle.entity = {
    config_path = "battle/configs/entities"
}

bt.EntityState = meta.new_enum({
    ALIVE = "ALIVE",
    KNOCKED_OUT = "KNOCKED_OUT",
    DEAD = "DEAD"
})

bt.AILevel = meta.new_enum({
    RANDOM = 0,
    LEVEL_1 = 1,
    LEVEL_2 = 2
})

bt.EquipType = meta.new_enum({
    TRINKET = "TRINKET",
    MALE_CLOTHING = "MALE_CLOTHING",
    FEMALE_CLOTHING = "FEMALE_CLOTHING",
    UNISEX_CLOTHING = "UNISEX_CLOTHING",
    WEAPON = "MELEE_WEAPON",
    UNKNOWN = "UNKNOWN"
})

--- @class bt.Entity
bt.Entity = meta.new_type("BattleEntity", function(id)
    meta.assert_string(id)
    local path = rt.settings.battle.entity.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Entity, {
        id = id,
        id_offset = 0,
        name = "UNINITIALIZED ENTITY @" .. path,
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

    hp_base = 0,
    hp_current = 0,

    attack_base = 0,
    defense_base = 0,
    speed_base = 0,

    priority = 0,

    status = {}, -- Table<bt.Status, {status: bt.Status, elapsed: Number}>
    moves = {}, -- Table<MoveID, {move: bt:move, n_uses: Number}>
    equips = {}, -- Table<EquipID, {equip: bt.Equip}>
    consumables = {}, --Table<ConsumableID, {consumable: bt.Consumable, n_consumed: Number}

    equip_slot_types = {bt.EquipType.UNKNOWN, bt.EquipType.UNKNOWN},
    state = bt.EntityState.ALIVE,

    -- non simulation
    sprite_id = "",
    sprite_index = 1,

    knocked_out_sprite_id = nil,
    knocked_out_sprite_index = nil,

    dead_sprite_id = nil,
    dead_sprite_index = nil,

    description = "(no description)",
    ai_level = bt.AILevel.RANDOM,
})

--- @brief
function bt.Entity:realize()
    if self._is_realized == true then return end
    meta.set_is_mutable(self, true)

    local template = {
        name = rt.STRING,

        is_enemy = rt.BOOLEAN,
        hp_base = rt.UNSIGNED,
        attack_base = rt.UNSIGNED,
        defense_base = rt.UNSIGNED,
        speed_base = rt.UNSIGNED,

        ai_level = rt.UNSIGNED,
        sprite_id = rt.STRING,
        sprite_index = {rt.UNSIGNED, rt.STRING},

        knocked_out_sprite_id = rt.STRING,
        knocked_out_sprite_index = {rt.UNSIGNED, rt.STRING},

        dead_sprite_id = rt.STRING,
        dead_sprite_index = {rt.UNSIGNED, rt.STRING},
    }

    meta.set_is_mutable(self, true)

    -- TODO
    rt.random.seed(meta.hash(self))
    self.hp_base = 100 --rt.random.integer(75, 150)
    self.attack_base = rt.random.integer(50, 100)
    self.defense_base = rt.random.choose({70, 80, 90, 100, 110})
    self.speed_base = rt.random.integer(5, 155)
    -- TODO

    rt.load_config(self._path, self, template)
    self.hp_current = 70 --self.hp_base

    self._is_realized = true
    meta.set_is_mutable(self, false)

    for stat in range("hp_base", "attack_base", "defense_base", "speed_base") do
        if self[stat] == nil then
            rt.error("In bt.Entity.realize: config at `" .. self._path .. "` does not define `" .. stat .. "`, which is required")
        end
    end
end

--- @brief calculate value of state, takes into account all statuses
function bt.Entity:_calculate_stat(which)
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
        value = value * equip[which .. "_base_factor"]
    end

    return math.ceil(value)
end

--- @brief
function bt.Entity:_calculate_stat_base(which)
    local value = self[which .. "_base"]
    for entry in values(self.equips) do
        local equip = entry.equip
        value = value + equip[which .. "_base_offset"]
    end

    if value < 0 then value = 1 end
    return math.ceil(value)
end

--- @brief
function bt.Entity:get_attack_base_raw()
    return self.attack_base
end

--- @brief
function bt.Entity:get_defense_base_raw()
    return self.defense_base
end

--- @brief
function bt.Entity:get_speed_base_raw()
    return self.speed_base
end

--- @brief
function bt.Entity:get_attack_base()
    return self:_calculate_stat_base("attack")
end

--- @brief
function bt.Entity:get_defense_base()
    return self:_calculate_stat_base("defense")
end

--- @brief
function bt.Entity:get_speed_base()
    return self:_calculate_stat_base("speed")
end

--- @brief
function bt.Entity:get_attack()
    return self:_calculate_stat("attack")
end

--- @brief
function bt.Entity:get_defense()
    return self:_calculate_stat("defense")
end

--- @brief
function bt.Entity:get_speed()
    return self:_calculate_stat("speed")
end

--- @brief
function bt.Entity:get_priority()
    return self.priority
end

--- @brief
function bt.Entity:get_is_enemy()
    return self.is_enemy
end

--- @brief
function bt.Entity:set_id_offset(n)
    meta.set_is_mutable(self, true)
    self.id_offset = n
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Entity:get_id()
    local offset = self.id_offset
    if offset == 0 then return self.id end
    return self.id .. "_" .. ternary(self.id_offset < 10, "0" .. offset,  offset)
end

--- @brief
function bt.Entity:get_hp()
    return self.hp_current
end

--- @brief
function bt.Entity:get_hp_base()
    local value = self.hp_base
    for entry in values(self.equippables) do
        local equip = entry.equip
        value = value + equip.hp_base_offset
    end

    if value < 0 then value = 1 end
    return value
end

--- @brief
function bt.Entity:get_hp_base_raw()
    return self.hp_base
end

--- @brief
function bt.Entity:get_id_offset_suffix()
    if self.id_offset == 0 then
        return ""
    else
        return " " .. utf8.char(self.id_offset + 0x03B1 - 1) -- lowercase greek letters
        --return " №" .. tostring(self.id_offset)
    end
end

--- @brief
function bt.Entity:get_id_offset()
    return self.id_offset
end

--- @brief
function bt.Entity:get_name()
    return self.name .. self:get_id_offset_suffix()
end

--- @brief
function bt.Entity:get_sprite_id()
    return self.sprite_id, self._sprite_index
end

--- @brief
function bt.Entity:get_status_n_turns_elapsed(status)
    return self.status[status:get_id()].elapsed
end

--- @brief
function bt.Entity:get_status_n_turns_left(status)
    return clamp(status:get_max_duration() - self.status[status:get_id()].elapsed, 0)
end

--- @brief
function bt.Entity:get_status(status_id)
    if self.status[status_id] == nil then return nil end
    return self.status[status_id].status
end

--- @brief
function bt.Entity:add_status(status)
    self.status[status:get_id()] = {
        elapsed = 0,
        status = status
    }
end

--- @brief
function bt.Entity:remove_status(status)
    self.status[status:get_id()] = nil
end

--- @brief
function bt.Entity:list_statuses()
    local out = {}
    for entry in values(self.status) do
        table.insert(out, entry.status)
    end
    return out
end

--- @brief
function bt.Entity:clear_statuses()
    for id in keys(self.status) do
        self.status[id] = nil
    end
end

--- @brief
function bt.Entity:has_status(status)
    return self.status[status:get_id()] ~= nil
end

--- @brief
function bt.Entity:status_advance(status)
    local entry = self.status[status:get_id()]
    if entry == nil then return end

    entry.elapsed = entry.elapsed + 1
    return entry.elapsed
end

--- @brief
function bt.Entity:get_is_stunned(status)
    for entry in values(self.status) do
        if entry.status.is_stun == true then
            return true
        end
    end
    return false
end

--- @brief
--- @return Boolean true if status is past its intended duration, false otherwise
function bt.Entity:increase_status_elapsed(status)
    local entry = self.status[status:get_id()]
    if entry == nil then
        rt.warning("In bt.Entity:increase_status_elapsed: entity `" .. self:get_id() .. "` does not have status `" .. status:get_id() .. "`")
        return false
    else
        entry.elapsed = entry.elapsed + 1
        return entry.elapsed >= status:get_max_duration()
    end
end

--- @brief
function bt.Entity:get_state()
    return self.state
end

--- @brief
function bt.Entity:get_is_knocked_out()
    return self.state == bt.EntityState.KNOCKED_OUT
end

--- @brief
function bt.Entity:get_is_dead()
    return self.state == bt.EntityState.DEAD
end

--- @brief
function bt.Entity:get_is_alive()
    return (not self:get_is_knocked_out()) and (not self:get_is_dead())
end

--- @brief
function bt.Entity:get_hp_current()
    return self.hp_current
end

--- @brief
function bt.Entity:get_hp_base()
    return self.hp_base
end

--- @brief
function bt.Entity:get_move(move_id)
    if self.moves[move_id] == nil then return nil end
    return self.moves[move_id].move
end

--- @brief
function bt.Entity:get_move_n_used(move)
    return move:get_max_n_uses() - self.moves[move:get_id()].n_uses
end

--- @brief
function bt.Entity:get_move_n_uses_left(move)
    return self.moves[move:get_id()].n_uses
end

--- @brief
function bt.Entity:add_move(move)
    self.moves[move:get_id()] = {
        move = move,
        n_uses = move.max_n_uses,
        is_disabled = false
    }
end

--- @brief
function bt.Entity:has_move(move)
    return self.moves[move:get_id()] ~= nil
end

--- @brief
function bt.Entity:list_moves()
    local out = {}
    for entry in values(self.moves) do
        table.insert(out, entry.move)
    end
    return out
end

--- @brief
function bt.Entity:set_move_is_disabled(move, b)
    local entry = self.moves[move:get_id()]
    if entry == nil then return end
    entry.is_disabled = b
end

--- @brief
function bt.Entity:get_move_is_disabled()
    local entry = self.moves[move:get_id()]
    if entry == nil then
        return true
    else
        return entry.is_disabled
    end
end

--- @brief
--- @return Boolean true if move is depleted, false otherwise
function bt.Entity:reduce_move_n_uses(move)
    local entry = self.moves[move:get_id()]
    if entry == nil then
        rt.warning("In bt.Entity:consume_move: entity `" .. self:get_id() .. "` does not have move `" .. move:get_id() .. "` equipped")
        return true
    else
        entry.n_uses = entry.n_uses - 1
        return entry.n_uses <= 0
    end
end

--- @brief
function bt.Entity:add_equip(equip)
    self.equips[equip:get_id()] = {
        equip = equip
    }
end

--- @brief
function bt.Entity:get_equip(equip_id)
    local entry = self.equips[equip_id]
    if entry == nil then
        return nil
    else
        return entry.equip
    end
end

--- @brief
function bt.Entity:list_equips()
    local out = {}
    for entry in values(self.equips) do
        table.insert(out, entry.equip)
    end
    return out
end

--- @brief
function bt.Entity:has_equip(equip)
    return self.equips[equip:get_id()] ~= nil
end

--- @brief
function bt.Entity:add_consumable(consumable)
    self.consumables[consumable:get_id()] = {
        consumable = consumable,
        n_consumed = 0
    }
end

--- @brief
function bt.Entity:remove_consumable(consumable)
    self.consumables[consumable:get_id()] = nil
end

--- @brief
function bt.Entity:get_consumable(consumable_id)
    return self.consumables[consumable_id].consumable
end

--- @brief
function bt.Entity:get_consumable_n_consumed(consumable)
    local entry = self.consumables[consumable:get_id()]
    if entry == nil then
        return 0
    else
        return entry.n_consumed
    end
end

--- @brief
function bt.Entity:get_consumable_n_uses_left(consumable)
    local entry = self.consumables[consumable:get_id()]
    if entry == nil then return 0 end
    return clamp(consumable:get_max_n_uses() - entry.n_consumed, 0)
end

--- @brief
function bt.Entity:has_consumable(consumable)
    return self.consumables[consumable:get_id()] ~= nil
end

--- @brief
function bt.Entity:list_consumables()
    local out = {}
    for entry in values(self.consumables) do
        if entry.n_consumed < entry.consumable:get_max_n_uses() then
            table.insert(out, entry.consumable)
        end
    end

    return out
end

--- @brief
--- @return Number n_left
function bt.Entity:consume_consumable(consumable)
    local entry = self.consumables[consumable:get_id()]
    if entry == nil then
        rt.warning("In bt.Entity:consume_move: entity `" .. self:get_id() .. "` does not have consumable `" .. consumable:get_id() .. "` equipped")
        return 0
    else
        entry.n_consumed = entry.n_consumed + 1
        local n_left = entry.consumable:get_max_n_uses() - entry.n_consumed
        if n_left <= 0 then
            self:remove_consumable(consumable)
        end
        return n_left
    end
end

--- @brief
function bt.Entity:get_description()
    return self.description
end

--- @brief
function bt.Entity:get_ai_level()
    return self.ai_level
end

--- @brief
function bt.Entity:get_equip_slot_types()
    return {table.unpack(self.equip_slot_types)}
end