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
    out.consumables = {}
    out.equips = {}

    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    is_enemy = true,

    hp_base = 100,
    hp_current = 0,

    attack_base = 0,
    defense_base = 0,
    speed_base = 0,

    priority = 0,

    status = {}, -- Table<bt.Status, {status: bt.Status, elapsed: Number}>

    n_move_slots = 25,
    moves = {}, -- List<{move: bt.Move, n_used: Number}>
    move_to_move_slot_i = {}, -- Table<bt.Move Number>

    n_equip_slots = 2,
    equips = {}, -- List<{equip: bt.Equip}>
    equip_to_equip_slot_i = {}, -- Table<bt.Equip, Number>

    n_consumable_slots = 1,
    consumables = {}, -- List<{consumable: bt.Consumable, n_consumed: Number}>
    consumable_to_consumable_slot_i = {}, -- Table<bt.Consumable, Number>

    state = bt.EntityState.ALIVE,
    ai_level = bt.AILevel.RANDOM,

    -- non simulation
    sprite_id = "",
    sprite_index = 1,

    knocked_out_sprite_id = nil,
    knocked_out_sprite_index = nil,

    dead_sprite_id = nil,
    dead_sprite_index = nil,

    description = "(no description)",
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

        n_move_slots = rt.INTEGER,
        n_equip_slots = rt.INTEGER,
        n_consumable_slots = rt.INTEGER,
    }

    meta.set_is_mutable(self, true)
    rt.load_config(self._path, self, template)

    assert(self.n_move_slots < POSITIVE_INFINITY)
    self.moves = {}
    self.move_to_move_slot_i = {}
    for i = 1, self.n_move_slots do
        table.insert(self.moves, {
            move = nil,
            n_uses_left = 0
        })
    end

    assert(self.n_equip_slots < POSITIVE_INFINITY)
    self.equips = {}
    for i = 1, self.n_equip_slots do
        table.insert(self.equips, {
            equip = nil,
        })
    end

    assert(self.n_equip_slots < POSITIVE_INFINITY)
    self.consumables = {}
    for i = 1, self.n_consumable_slots do
        table.insert(self.consumables, {
            consumable = nil,
            n_consumed = 0
        })
    end

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
        if equip ~= nil then
            value = value * equip[which .. "_base_factor"]
        end
    end

    return math.ceil(value)
end

--- @brief
function bt.Entity:_calculate_stat_base(which)
    local value = self[which .. "_base"]
    for entry in values(self.equips) do
        local equip = entry.equip
        if equip ~= nil then
            value = value + equip[which .. "_base_offset"]
        end
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
function bt.Entity:get_hp_current()
    return self.hp_current
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
function bt.Entity:get_hp_base_raw()
    return self.hp_base
end

--- @brief
function bt.Entity:get_hp_base()
    local value = self.hp_base
    for entry in values(self.equips) do
        local equip = entry.equip
        if equip ~= nil then
            value = value + equip.hp_base_offset
        end
    end

    if value < 0 then value = 1 end
    return value
end

--- @brief
function bt.Entity:get_hp()
    return self.hp_current
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

--- @brief [internal]
function bt.Entity:_assert_move_slot_i(i)
    if i < 1 or i > self.n_move_slots then
        rt.error("In bt.Entity:get_move: slot index `" .. i .. "` is out of range for entity with `" .. self.n_move_slots .. "` slots")
    end
end

--- @brief
function bt.Entity:add_move(move, move_slot_i)
    if move_slot_i == nil then
        for slot_i, entry in ipairs(self.moves) do
            if entry.move == nil then
                entry.move = move
                entry.n_uses_left = move:get_max_n_uses()
                self.move_to_move_slot_i[move] = slot_i
                return
            end
        end

        rt.error("In bt.Entity:add_move: entity has no free move slots")
    else
        self:_assert_move_slot_i(move_slot_i)
        local current = self.moves[move_slot_i].move
        if current ~= nil then
            self.move_to_move_slot_i[current] = nil
        end

        self.moves[move_slot_i].move = move
        if move ~= nil then
            self.move_to_move_slot_i[move] = move_slot_i
        end
    end
end

--- @brief
function bt.Entity:remove_move(move)
    local i = self.move_to_move_slot_i[move]
    if i == nil then return end
    self.moves[i] = {
        move = nil,
        n_uses_left = 0
    }
    self.move_to_move_slot_i[move] = nil
end

--- @brief
--- @param move_slot_i Number
function bt.Entity:get_move(move_slot_i)
    self:_assert_move_slot_i(move_slot_i)
    local entry = self.moves[move_slot_i]
    if entry == nil then return nil end
    return entry.move
end

--- @brief
function bt.Entity:get_move_n_used(move)
    local i = self.move_to_move_slot_i[move]
    if i == nil then
        return 0
    else
        return move:get_max_n_uses() - self.moves[i].n_uses_left
    end
end

--- @brief
function bt.Entity:get_move_n_uses_left(move)
    local i = self.move_to_move_slot_i[move]
    if i == nil then
        return 0
    else
        return self.moves[i].n_uses_left
    end
end

--- @brief
function bt.Entity:has_move(move)
    return self.move_to_move_slot_i[move] ~= nil
end

--- @brief
function bt.Entity:list_moves()
    local to_sort = {}
    for move, slot_i in pairs(self.move_to_move_slot_i) do
        table.insert(to_sort, {move, slot_i})
    end
    table.sort(to_sort, function(a, b)
        return a[2] < b[2]
    end)

    local out = {}
    for pair in values(to_sort) do
        table.insert(out, pair[1])
    end
    return out
end

--- @brief
function bt.Entity:list_move_slots()
    local out = {}
    local n = self:get_n_move_slots()
    for i = 1, n do
        out[i] = self.moves[i].move
    end
    return out
end

--- @brief
--- @return Boolean true if move is depleted, false otherwise
function bt.Entity:reduce_move_n_uses(move)
    local i = self.move_to_move_slot_i(move)
    if i == nil then
        rt.warning("In bt.Entity:consume_move: entity `" .. self:get_id() .. "` does not have move `" .. move:get_id() .. "` equipped")
        return true
    end

    local entry = self.moves[i]
    entry.n_uses = entry.n_uses - 1
    return entry.n_uses <= 0
end

--- @brief [internal]
function bt.Entity:_assert_equip_slot_i(i)
    if i < 1 or i > self.n_equip_slots then
        rt.error("In bt.Entity:get_equip: slot index `" .. i .. "` is out of range for entity with `" .. self.n_equip_slots .. "` slots")
    end
end

--- @brief [internal]
function bt.Entity:_assert_consumable_slot_i(i)
    if i < 1 or i > self.n_consumable_slots then
        rt.error("In bt.Entity:get_consumable: slot index `" .. i .. "` is out of range for entity with `" .. self.n_consumable_slots  .. "` slots")
    end
end

--- @brief
function bt.Entity:add_equip(equip, equip_slot_i)
    if equip_slot_i == nil then
        for slot_i, entry in ipairs(self.equips) do
            if entry.equip == nil then
                entry.equip = equip
                self.equip_to_equip_slot_i[equip] = slot_i
                return
            end
        end

        rt.error("In bt.Entity:add_equip: entity has no free move slots")
    else
        self:_assert_equip_slot_i(equip_slot_i)
        local current = self.equips[equip_slot_i].equip
        if current ~= nil then
            self.equip_to_equip_slot_i[current] = nil
        end

        self.equips[equip_slot_i].equip = equip

        if equip ~= nil then
            self.equip_to_equip_slot_i[equip] = equip_slot_i
        end
    end
end

--- @brief
function bt.Entity:remove_equip(equip)
    local i = self.equip_to_equip_slot_i[equip]
    if equip == nil then return end
    self.equips[i].equip = nil
    self.equip_to_equip_slot_i[equip] = nil
end

--- @brief
function bt.Entity:get_equip(equip_slot_i)
    local entry = self.equips[equip_slot_i]
    if entry == nil then return nil end
    return entry.equip
end

--- @brief
function bt.Entity:list_equips()
    local out = {}
    for equip in values(self.equips) do
        table.insert(out, equip.equip)
    end
    return out
end

--- @brief
function bt.Entity:list_equip_slots()
    local out = {}
    local n = self:get_n_equip_slots()
    for i = 1, n do
        out[i] = self.equips[i].equip
    end
    return out
end

--- @brief
function bt.Entity:has_equip(equip)
    return self.equip_to_equip_slot_i[equip] ~= nil
end

--- @brief [internal]
function bt.Entity:_assert_equip_slot_i(i)
    if i < 1 or i > self.n_equip_slots then
        rt.error("In bt.Entity:get_equip: slot index `" .. i .. "` is out of range for entity with `" .. self.n_consumable_slots .. "` slots")
    end
end

--- @brief
function bt.Entity:add_consumable(consumable, consumable_slot_i)
    if consumable_slot_i == nil then
        for slot_i, entry in ipairs(self.consumables) do
            if entry.consumable == nil then
                entry.consumable = consumable
                self.consumable_to_consumable_slot_i[consumable] = slot_i
                return
            end
        end

        rt.error("In bt.Entity:add_consumable: entity has no free consumable slots")
    else
        self:_assert_consumable_slot_i(consumable_slot_i)
        local current = self.consumables[consumable_slot_i].consumable
        if current ~= nil then
            self.consumable_to_consumable_slot_i[current] = nil
        end

        self.consumables[consumable_slot_i].consumable = consumable
        if consumable ~= nil then
            self.consumable_to_consumable_slot_i[consumable] = consumable_slot_i
        end
    end
end

--- @brief
function bt.Entity:remove_consumable(consumable)
    local i = self.consumable_to_consumable_slot_i[consumable]
    if i == nil then return end
    local entry = self.consumables[i]
    entry.consumable = nil
    entry.n_consumed = 0
    self.consumable_to_consumable_slot_i[consumable] = nil
end

--- @brief
function bt.Entity:get_consumable(consumable_slot_i)
    local entry = self.consumable[consumable_slot_i]
    if entry == nil then return nil end
    return entry.consumable
end

--- @brief
function bt.Entity:get_consumable_n_consumed(consumable)
    local entry = self.consumables[self.consumable_to_consumable_slot_i[consumable]]
    if entry == nil then return 0 end
    return entry.n_consumed
end

--- @brief
function bt.Entity:get_consumable_n_uses_left(consumable)
    local entry = self.consumables[self.consumable_to_consumable_slot_i[consumable]]
    if entry == nil then return 0 end
    return clamp(consumable:get_max_n_uses() - entry.n_consumed, 0)
end

--- @brief
function bt.Entity:has_consumable(consumable)
    return self.consumables[consumable] == nil
end

--- @brief
function bt.Entity:list_consumables()
    local out = {}
    for entry in values(self.consumables) do
        table.insert(out, entry.consumable)
    end
    return out
end

--- @brief
function bt.Entity:list_consumable_slots()
    local out = {}
    local n = self:get_n_consumable_slots()
    for i = 1, n do
        out[i] = self.consumables[i].consumable
    end
    return out
end

--- @brief
function bt.Entity:consume_consumable(consumable)
    local entry =  self.consumable_to_consumable_slot_i[consumable]
    if entry == nil then return end
    entry.n_consumed = entry.n_consumed + 1
    local n_left = entry.consumable:get_max_n_uses() - entry.n_consumed
    if n_left <= 0 then
        self:remove_consumable(consumable)
    end
    return n_left
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
--- @return hp_base, attack_base, defense_base, speed_base
function bt.Entity:preview_equip(equip_slot_i, new_equip)
    local before = self.equips[equip_slot_i].equip
    self:add_equip(new_equip, equip_slot_i)
    local after_stats = {
        self:_calculate_stat_base("hp"),
        self:_calculate_stat_base("attack"),
        self:_calculate_stat_base("defense"),
        self:_calculate_stat_base("speed"),
    }

    self:add_equip(before, equip_slot_i)
    return table.unpack(after_stats)
end

--- @brief
function bt.Entity:get_n_move_slots()
    return self.n_move_slots
end

--- @brief
function bt.Entity:get_n_consumable_slots()
    return self.n_consumable_slots
end

--- @brief
function bt.Entity:get_n_equip_slots()
    return self.n_equip_slots
end

--- @brief
function bt.Entity:list_intrinsic_moves()
    return {bt.Move("STRUGGLE"), bt.Move("PROTECT")}
    --[[
    local out = {}
    for move in keys(self.move_to_move_slot_i) do
        if move:get_is_intrinsic() then
            table.insert(out, move)
        end
    end
    table.sort(out, function(a, b)
        return self.move_to_move_slot_i[a] < self.move_to_move_slot_i[b]
    end)
    return out
    ]]--
end

--- @brief
function bt.Entity:get_n_intrinsic_moves()
    return #(self:list_intrinsic_moves())
end