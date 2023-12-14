--- @class bt.Stats
bt.StatusAilment = meta.new_type("StatusAilment", function(id)

    local path = "battle/configs/status_ailments/" .. id .. ".lua"
    if meta.is_nil(love.filesystem.getInfo(path)) then
        rt.error("In StatusAilment(\"" .. id .. "\"): path `" .. path .. "` does not exist")
    end
    local config_file, error_maybe = load(love.filesystem.read(path))
    if meta.is_nil(config_file) then
        rt.error("In StatusAilment(\"" .. id .. "\"): error parsing file at `" .. path .. "`: " .. error_maybe)
    end

    local config = config_file()
    local out = meta.new(bt.StatusAilment, {
        id = id
    })

    for _, which in pairs({"attack", "defense", "speed"}) do
        local value = config[which .. "_factor"]
        if not meta.is_nil(value) then
            meta.assert_number(value)
            assert(value >= 0)
            out[which .. "_factor"] = value
        end
    end

    meta.assert_string(config.name)
    out.name = config.name

    local duration = config.duration
    meta.assert_number(duration)
    out.max_duration = duration

    for _, which in pairs({"description", "verbose_description", "sprite"}) do
        local value = config[which]
        if not meta.is_nil(value) then
            meta.assert_string(value)
            out[which] = value
        end
    end

    meta.set_is_mutable(out, false)
    return out
end)

-- cleartext name
bt.StatusAilment.name = ""
bt.StatusAilment.description = "has no effect"
bt.StatusAilment.verbose_description = "this status ailment has no effect, it is only used for testing"
bt.StatusAilment.flavor_text = "status statis"

-- sprite IDs
bt.StatusAilment.sprite_id = "default"

-- stats
bt.StatusAilment.attack_factor = 1
bt.StatusAilment.defense_factor = 1
bt.StatusAilment.speed_factor = 1

-- duration
bt.StatusAilment.max_duration = POSITIVE_INFINITY

--- @brief
function bt.StatusAilment:create_sprite()

    if meta.is_nil(bt.StatusAilment.spritesheet) then
        bt.StatusAilment.spritesheet = rt.Spritesheet("assets/sprites", "status_ailment")
    end
    return rt.Sprite(bt.StatusAilment.spritesheet, self.sprite_id)
end
