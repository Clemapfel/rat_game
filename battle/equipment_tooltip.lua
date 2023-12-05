rt.settings.equpment_tooltip.no_effect_label = "(no additional effect)"

--- @class bt.EquipmentTooltip
bt.EquipmentTooltip = meta.new_type("EquipmentTooltip", function(equpment)

    if meta.is_nil(env.equipment_spritesheet) then
        env.equipment_spritesheet = rt.Spritesheet("assets/sprites", "equipment")
    end

    local sprite_id = "default"
    local sprite_size_x, sprite_size_y = env.equipment_spritesheet:get_frame_size(sprite_id)

    local out = meta.new(bt.EquipmentTooltip, {
        _equipment = equpment,
        _sprite = rt.Sprite(env.equipment_spritesheet, sprite_id),
        _tooltip = {} -- bt.BattleTooltip
    }, rt.Widget, rt.Drawable)

    out._tooltip = bt.BattleTooltip(
        out._equipment.name,
        out:_format_stat_label(),
        out._equipment.effect_text,
        out._equipment.flavor_text,
        out._sprite
    )

    return out
end)

--- @overload rt.Widget.get_top_level_widget
function bt.EquipmentTooltip:get_top_level_widget()
    return self._tooltip:get_top_level_widget()
end

--- @brief [internal]
function bt.EquipmentTooltip:_format_stat_label()

    local get_n_digits = function(x)
        if x < 0 then x = math.abs(x) end
        if x == 0 then return 1 end
        return math.floor(math.log(x, 10)) + 1 + ternary(x < 0, 1, 0)
    end

    local n_digits = 0
    for _, modifier in pairs({equipment.attack_modifier, equipment.defense_modifier, equipment.speed, equipment.hp}) do
        n_digits = math.max(n_digits, get_n_digits(modifier))
    end

    local modifier_to_label = function(modifier)

        local out = ""
        for i = 1, n_digits - get_n_digits(modifier) do
            out = out .. " "
        end

        if modifier == 0 then
            out = out .. "±"
        elseif modifier > 0 then
            out = out .. "+"
        end

        return out .. tostring(modifier)
    end

    local stat_label_text = ""
    stat_label_text = stat_label_text
            .. ternary(equipment.attack_modifier ~= 0, "<color=ATTACK><b>ATK</b><mono> " .. modifier_to_label(equipment.attack_modifier) .. "</mono></color>\n", "")
            .. ternary(equipment.defense_modifier ~= 0, "<color=DEFENSE><b>DEF</b><mono> " .. modifier_to_label(equipment.defense_modifier) .. "</mono></color>\n", "")
            .. ternary(equipment.speed_modifier ~= 0, "<color=SPEED><b>SPD</b><mono> " .. modifier_to_label(equipment.speed_modifier) .. "</mono></color>\n", "")
            .. ternary(equipment.hp_modifier ~= 0, "<color=HP><b>HP  </b><mono> " .. modifier_to_label(equipment.hp_modifier) .. "</mono></color>\n", "")

    return stat_label_text
end
