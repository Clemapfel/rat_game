rt.settings.battle.battle_config = {
    config_path = "battle/configs/battles"
}

--- @class bt.BattleConfig
bt.BattleConfig = meta.new_type("BattleConfig", function(id)
    local out = bt.BattleConfig._atlas[id]
    if out == nil then
        local path = rt.settings.battle.battle_config.config_path .. "/" .. id .. ".lua"
        out = meta.new(bt.BattleConfig, {
            id = id,
            _path = path,
            _is_realized = false
        })
        out:realize()
        meta.set_is_mutable(out, false)
        bt.BattleConfig._atlas[id] = out
    end
    return out
end, {
    enemy_ids = {},           -- Table<EnemyID>
    global_status_ids = {},     -- Table<GlobalStatusID>
    background_id = {},     -- BattleBackgroundImplementationID
    music_id = {}              -- MusicID
})
bt.BattleConfig._atlas = {}

--- @brief
function bt.BattleConfig:realize()
    if self._is_realized == true then return end

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.BattleConfig:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()
    meta.set_is_mutable(self, true)

    if table.is_empty(config.enemies) then
        rt.error("In bt.BattleConfig:realize: config at `" .. self._path .. "` does not specify any enemies")
    end

    if not meta.is_table(config.enemies) then
        config.enemies = {config.enemies}
    end


    for i, enemy_id in ipairs(config.enemies) do
        if not meta.is_string(enemy_id) then
            rt.error("In bt.BattleConfig:realize: config at `" .. self._path .. "` expected string in `enemies`, got: " .. meta.typeof(enemy_id) .. "`")
        end
        table.insert(self.enemy_ids, enemy_id)
    end

    if not meta.is_table(config.global_status) then
        config.global_status = {config.global_status}
    end

    for i, status_id in ipairs(config.global_status) do
        if not meta.is_string(status_id) then
            rt.error("In bt.BattleConfig:realize: config at `" .. self._path .. "` expected string in `global_status`, got: " .. meta.typeof(status_id) .. "`")
        end
        table.insert(self.global_status_ids, status_id)
    end

    if not meta.is_string(config.background) then
        rt.error("In bt.BattleConfig:realize: config at `" .. self._path .. "` expected string for `background`, got: " .. meta.typeof(config.background) .. "`")
    end
    self.background_id = config.background

    if not meta.is_string(config.music) then
        rt.error("In bt.BattleConfig:realize: config at `" .. self._path .. "` expected string for `music`, got: " .. meta.typeof(config.music) .. "`")
    end
    self.music_id = config.music

    self._is_realized = true
    meta.set_is_mutable(self, false)
end

