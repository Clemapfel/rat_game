rt.settings.battle.equipment.default_effect_text = "no additional effect"

--- @class bt.Equipment
--- @brief immutable config for equipment
bt.Equipment = meta.new_type("Equipment", function(id)

    local path = "battle/configs/equipment/" .. id .. ".lua"
    if meta.is_nil(love.filesystem.getInfo(path)) then
        rt.error("In Equipment(\"" .. id .. "\"): path `" .. path .. "` does not exist")
    end
    local config_file, error_maybe = load(love.filesystem.read(path))
    if meta.is_nil(config_file) then
        rt.error("In Equipment(\"" .. id .. "\"): error parsing file at `" .. path .. "`: " .. error_maybe)
    end

    local config = config_file()
    local out = meta.new(bt.Equipment, {
        id = id
    })

    local attack_modifier = config.attack_modifier
    if not meta.is_nil(attack_modifier) then
        meta.assert_number(attack_modifier)
        out.attack_modifier = attack_modifier
    end

    local defense_modifier = config.defense_modifier
    if not meta.is_nil(defense_modifier) then
        meta.assert_number(defense_modifier)
        out.defense_modifier = defense_modifier
    end

    local speed_modifier = config.speed_modifier
    if not meta.is_nil(speed_modifier) then
        meta.assert_number(speed_modifier)
        out.speed_modifier = speed_modifier
    end

    local hp_modifier = config.hp_modifier
    if not meta.is_nil(hp_modifier) then
        meta.assert_number(hp_modifier)
        out.hp_modifier = hp_modifier
    end

    if #config.name == 0 then
        rt.error("In Equipment(\"" .. id .. "\"): `name` field cannot be empty")
    end
    meta.assert_string(config.name)
    out.name = config.name

    local effect_text = config.effect_text
    if meta.is_nil(effect_text) then
        out.effect_text = rt.settings.battle.equipment.default_effect_text
    else
        meta.assert_string(effect_text)
        out.effect_text = effect_text
    end

    local flavor_text = config.flavor_text
    if meta.is_nil(flavor_text) then
        out.flavor_text = ""
    else
        meta.assert_string(flavor_text)
        out.flavor_text = flavor_text
    end

    local sprite_id = config.sprite_id
    meta.assert_string(sprite_id)
    out.sprite_id = sprite_id

    meta.set_is_mutable(out, false)
    return out
end)

-- stat buffs (absolute values)
bt.Equipment.attack_modifier = 0
bt.Equipment.defense_modifier = 0
bt.Equipment.speed_modifier = 0
bt.Equipment.hp_modifier = 0

--- cleartext name
bt.Equipment.name = "ERROR_EQUIPMENT"

--- clear text effect
bt.Equipment.effect_text = "No additional effect."

--- flavor text, optional
bt.Equipment.flavor_text = ""

-- sprite for inventory thumbnail
bt.Equipment.sprite_id = "default"

--- @brief
function bt.Equipment:create_sprite()
    if meta.is_nil(bt.Equipment.spritesheet) then
        bt.Equipment.spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end
    return rt.Sprite(bt.Equipment.spritesheet, self.sprite_id)
end