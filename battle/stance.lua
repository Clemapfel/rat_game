rt.settings.battle.stance = {
    config_path = "battle/configs/stances",
    default_color_id = "GRAY_1"
}

--- @class bt.StanceAlignment
bt.StanceAlignment = meta.new_enum({
    ALL = "ALL",
    NONE = "NONE",
})

--- @class bt.Stance
bt.Stance = meta.new_type("Stance", function(id)
    local path = rt.settings.battle.stance.config_path .. "/" .. id .. ".lua"
    local out = meta.new(bt.Stance, {
        id = id,
        name = "UNINITIALIZED STANCE @" .. path,
        _path = path,
        _is_realized = false
    })
    out:realize()
    meta.set_is_mutable(out, false)
    return out
end, {
    color_id = rt.settings.battle.stance.default_color_id,
    color = rt.Palette[rt.settings.battle.stance.default_color_id],
    sprite_id = "",
    sprite_index = 1
})

--- @brief
function bt.Stance:realize()
    if self._is_realized then return end

    local chunk, error_maybe = love.filesystem.load(self._path)
    if error_maybe ~= nil then
        rt.error("In bt.Stance:realize: error when loading config at `" .. self._path .. "`: " .. error_maybe)
    end

    local config = chunk()
    meta.set_is_mutable(self, true)

    self.name = config.name
    meta.assert_string(self.name)

    if config.color ~= nil then
        self.color_id = config.color
        self.color = rt.Palette[config.color]
    end

    if config.sprite_id ~= nil then
        self.sprite_id = config.sprite_id
        meta.assert_string(self.sprite_id)
    end

    if config.sprite_index ~= nil then
        self.sprite_index = config.sprite_index
    end

    self._is_realized = false
    meta.set_is_mutable(self, false)
end

--- @brief
function bt.Stance:get_id()
    return self.id
end

--- @brief
function bt.Stance:get_name()
    return self.name
end

--- @brief
function bt.Stance:matches_alignment(alignment)
    if alignment == bt.StanceAlignment.NONE then
        return false
    elseif alignment == bt.StanceAlignment.ALL then
        return true
    else
        return self.id == alignment
    end
end
