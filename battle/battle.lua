rt.settings.battle.battle = {
    config_path = "assets/configs/battles",
}

--- @class bt.Battle
bt.Battle = meta.new_type("Battle", function(id)
    local out = meta.new(bt.Battle, {
        _background_id = nil,
        _global_statuses = {}, -- Table<bt.GlobalStatus>
        _enemies = {} --[[
            [i] = {
                id = String,
                moves = Table<bt.Attack>,
                statuses = Table<bt.Statuses>,
                consumables = Table<bt.Consumables>
                equips = Table<bt.Equips>
            }
        ]]--
    })

    if id ~= nil then
        meta.assert_string(id)
        out:load_config(id)
    end
    return out
end)

do
    local _get_entry = function(self, scope, i)
        local entry = self._enemies[i]
        if entry == nil then
            rt.error("In bt.Battle." .. scope .. ": no enemy at position #" .. i)
            return nil
        end
        return entry
    end

    --- @brief
    function bt.Battle:get_enemy_id(i)
        local entry = _get_entry(self, "get_enemy_id", i)
        if entry ~= nil then return entry.id end
    end

    --- @brief
    function bt.Battle:get_enemy_moves(i)
        local entry = _get_entry(self, "get_enemy_moves", i)
        local out = {}
        if entry ~= nil and entry.moves ~= nil then
            for move in values(entry.moves) do
                table.insert(out, move)
            end
        end
        return out
    end

    --- @brief
    function bt.Battle:get_enemy_statuses(i)
        local entry = _get_entry(self, "get_enemy_statuses", i)
        local out = {}
        if entry ~= nil and entry.statuses ~= nil then
            for status in values(entry.statuses) do
                table.insert(out, status)
            end
        end
        return out
    end

    --- @brief
    function bt.Battle:get_enemy_equips(i)
        local entry = _get_entry(self, "get_enemy_statuses", i)
        local out = {}
        if entry ~= nil and entry.equips ~= nil then
            for equip in values(entry.equips) do
                table.insert(out, equip)
            end
        end
        return out
    end

    --- @brief
    function bt.Battle:get_enemy_consumables(i)
        local entry = _get_entry(self, "get_enemy_consumables", i)
        local out = {}
        if entry ~= nil and entry.consumables ~= nil then
            for consumable in values(entry.consumables) do
                table.insert(out, consumable)
            end
        end
        return out
    end
end

--- @brief
function bt.Battle:add_enemy(id, moves, consumables, equips, statuses)
    meta.assert_string(id)
    local entry = {
        id = id,
        moves = {},
        consumables = {},
        equips = {},
        statuses = {}
    }

    if moves == nil then moves = {} end
    for move in values(moves) do
        meta.assert_isa(move, bt.Move)
        table.insert(entry.moves, move)
    end

    if consumables == nil then consumables = {} end
    for consumable in values(consumables) do
        meta.assert_isa(consumable, bt.Consumable)
        table.insert(entry.consumables, consumable)
    end

    if equips == nil then equips = {} end
    for equip in values(equips) do
        meta.assert_isa(equip, bt.Equip)
        table.insert(entry.equips, equip)
    end

    if statuses == nil then statuses = {} end
    for status in values(statuses) do
        meta.assert_isa(status, bt.Status)
        table.insert(entry.statuses, status)
    end

    table.insert(self._enemies, entry)
end

--- @brief
function bt.Battle:load_config(id)
    local path = rt.settings.battle.battle.config_path .. "/" .. id .. ".lua"
    local load_success, chunk_or_error, love_error = pcall(love.filesystem.load, path)
    if not load_success then
        rt.error("In bt.Battle.load_config: error when parsing config at `" .. path .. "`: " .. chunk_or_error)
        return
    end

    if love_error ~= nil then
        rt.error("In bt.Battle.load_config: error when loading config at `" .. path .. "`: " .. love_error)
        return
    end

    local chunk_success, config_or_error = pcall(chunk_or_error)
    if not chunk_success then
        rt.error("In bt.Battle.load_config: error when running config at `" .. path .. "`: " .. config_or_error)
        return
    end

    local function throw(reason)
        rt.error("In bt.Battle.load_config: error when loading config at `" .. path .. "`: " .. reason)
    end

    local config = config_or_error

    if config.global_statuses == nil then config.global_statuses = {} end
    self._global_statuses = {}
    for status_id in values(config.global_statuses) do
        if not meta.is_string(id) then
            throw("in config.global_statuses: expected `string`, got `" .. meta.typeof(status_id) .. "`")
            return
        end
        table.insert(self._global_statuses, bt.GlobalStatus(status_id))
    end

    if config.enemies == nil or #config.enemies == 0 then
        throw("in config.enemies: expected 1 or more enemies, got 0")
        return
    end

    local enemy_i = 1
    for _, config_entry in pairs(config.enemies) do
        local enemy_id = config_entry.id
        if not meta.is_string(enemy_id) then
            throw("in config.enemies[" .. enemy_i .. "].id: expected `string`, got `" .. meta.typeof(config_entry.id) .. "`")
            return
        end

        local entry = {
            id = config_entry.id,
            moves = {},
            statuses = {},
            consumables = {},
            equips = {}
        }

        if config_entry.moves == nil then config_entry.moves = {} end
        if not meta.is_table(config_entry.moves) then
            throw("in config.enemies[" .. enemy_i .. "].moves: expected `table`, got `" .. meta.typeof(config_entry.moves) .. "`")
            return
        end

        do
            local move_i = 1
            for _, move_id in pairs(config_entry.moves) do
                if not meta.is_string(move_id) then
                    throw("in config.enemies[" .. enemy_i .. "].moves[" .. move_i .. "]: expected `string`, got `" .. meta.typeof(move_id) .. "`")
                    return
                end
                table.insert(entry.moves, bt.Move(move_id))
                move_i = move_i + 1
            end
        end

        if config_entry.statuses == nil then config_entry.statuses = {} end
        if not meta.is_table(config_entry.statuses) then
            throw("in config.enemies[" .. enemy_i .. "].statuses: expected `table`, got `" .. meta.typeof(config_entry.statuses) .. "`")
            return
        end

        do
            local status_i = 1
            for _, status_id in pairs(config_entry.statuses) do
                if not meta.is_string(status_id) then
                    throw("in config.enemies[" .. enemy_i .. "].statuses[" .. status_i .. "]: expected `string`, got `" .. meta.typeof(status_id) .. "`")
                    return
                end
                table.insert(entry.statuses, bt.Status(status_id))
                status_i = status_i + 1
            end
        end

        if config_entry.consumables == nil then config_entry.consumables = {} end
        if not meta.is_table(config_entry.consumables) then
            throw("in config.enemies[" .. enemy_i .. "].consumables: expected `table`, got `" .. meta.typeof(config_entry.consumables) .. "`")
            return
        end

        do
            local consumable_i = 1
            for _, consumable_id in pairs(config_entry.consumables) do
                if not meta.is_string(consumable_id) then
                    throw("in config.enemies[" .. enemy_i .. "].consumables[" .. consumable_i .. "]: expected `string`, got `" .. meta.typeof(consumable_id) .. "`")
                    return
                end
                table.insert(entry.consumables, bt.Consumable(consumable_id))
                consumable_i = consumable_i + 1
            end
        end

        if config_entry.equips == nil then config_entry.equips = {} end
        if not meta.is_table(config_entry.equips) then
            throw("in config.enemies[" .. enemy_i .. "].equips: expected `table`, got `" .. meta.typeof(config_entry.equips) .. "`")
            return
        end

        do
            local equip_i = 1
            for _, equip_id in pairs(config_entry.equips) do
                if not meta.is_string(equip_id) then
                    throw("in config.enemies[" .. enemy_i .. "].equips[" .. equip_i .. "]: expected `string`, got `" .. meta.typeof(equip_id) .. "`")
                    return
                end
                table.insert(entry.equips, bt.Equip(equip_id))
                equip_i = equip_i + 1
            end
        end

        table.insert(self._enemies, entry)
        enemy_i = enemy_i + 1
    end
end

--- @brief
function bt.Battle:get_background()
    return rt.Background[self._background_id]
end

--- @brief
function bt.Battle:get_n_enemies()
    return sizeof(self._enemies)
end

--- @brief
function bt.Battle:get_global_statuses()
    local out = {}
    for status in values(self._global_statuses) do
        table.insert(out, status)
    end
    return out
end