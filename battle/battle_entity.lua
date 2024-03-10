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
    meta.set_is_mutable(out, false)
    return out
end, {
    sprite_id = "",
    is_enemy = true
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
    meta.set_is_mutable(self, true)


    self._is_realized = true
    meta.set_is_mutable(self, false)
end