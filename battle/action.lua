--- @class bt.TargetingMode
bt.TargetingMode = meta.new_enum({
    SINGLE = "SINGLE",
    MULTIPLE = "MULTIPLE",
    STAGE = "STAGE"
})

--- @class bt.ActionType
bt.ActionType = meta.new_enum({
    MOVE = "MOVE",
    CONSUMABLE = "CONSUMABLE",
    INTRINSIC = "INTRINSIC"
})

--- @class bt.Action
--- @brief immutable config for battle actions
bt.Action = meta.new_type("Action", function(id)

    local path = "battle/configs/actions/" .. id .. ".lua"
    if meta.is_nil(love.filesystem.getInfo(path)) then
        rt.error("In Action(\"" .. id .. "\"): path `" .. path .. "` does not exist")
    end
    local config_file, error_maybe = load(love.filesystem.read(path))
    if meta.is_nil(config_file) then
        rt.error("In Action(\"" .. id .. "\"): error parsing file at `" .. path .. "`: " .. error_maybe)
    end

    local config = config_file()
    local out = meta.new(bt.Action, {
        id = id,
        thumbnail = {}
    })

    local type = config.type
    meta.assert_enum(type, bt.ActionType)
    out.type = type

    local max_n_uses = config.max_n_uses
    if not meta.is_nil(max_n_uses) then
        meta.assert_number(max_n_uses)
        if max_n_uses <= 0 then
            rt.error("In Action(\"" .. id .. "\"): value `" .. tostring(max_n_uses) .. "` for field `max_n_uses` is out of range")
        end
        out.max_n_uses = max_n_uses
    else
        out.max_n_uses = POSITIVE_INFINITY
    end


    local targeting_mode = config.targeting_mode
    if not meta.is_nil(targeting_mode) then

        out.targeting_mode = targeting_mode
    end

    for _, which in pairs({"self", "ally", "enemy"}) do
        local value = config["can_target_" .. which]
        if not meta.is_nil(value) then

            out["can_target_" .. which] = value
        end
    end

    if #config.name == 0 then
        rt.error("In Action(\"" .. id .. "\"): `name` field cannot be empty")
    end
    out.name = config.name

    local effect_text = config.effect_text

    out.effect_text = effect_text

    local verbose_effect_text = config.verbose_effect_text

    out.verbose_effect_text = verbose_effect_text

    local flavor_text = config.flavor_text
    if not meta.is_nil(flavor_text) then
        meta.assert_string(flavor_text)
        out.flavor_text = flavor_text
    end

    local thumbnail_id = config.thumbnail_id

    out.thumbnail_id = thumbnail_id

    local animation_id = config.animation_id

    out.animation_id = animation_id

    meta.set_is_mutable(out, false)
    return out
end)

-- possible targets
bt.Action.targeting_mode = bt.TargetingMode.SINGLE
bt.Action.can_target_ally = true
bt.Action.can_target_enemy = true
bt.Action.can_target_self = true

-- maximum number of uses
bt.Action.max_n_uses = POSITIVE_INFINITY

--- whether an actions stacks can be replenished
bt.Action.type = "ERROR_TYPE"

-- cleartext name
bt.Action.name = "ERROR_ACTION"

-- clear text effect
bt.Action.effect_text = "No effect"
bt.Action.verbose_effect_text = "Has no additional effect"
bt.Action.flavor_text = "flavorless"

-- sprite for inventory thumbnail
bt.Action.thumbnail_id = "default"

-- sprite for in-battle animation
bt.Action.animation_id = "default"

--- @brief
function bt.Action:create_sprite()
    if meta.is_nil(bt.Action.spritesheet) then
        bt.Action.spritesheet = rt.Spritesheet("assets/sprites", "orbs")
    end
    return rt.Sprite(bt.Action.spritesheet, self.thumbnail_id)
end



