--- @class bt.StatLevelIndicator
bt.StatLevelIndicator = meta.new_type("StatLevelIndicator", function(level, which)
    if meta.is_nil(bt.PartyInfo.spritesheet) then
        bt.StatLevelIndicator.spritesheet = rt.Spritesheet("assets/sprites", "party_info")
    end

    local out = meta.new(bt.StatLevelIndicator, {
        _sprite = rt.Sprite(bt.StatLevelIndicator.spritesheet , "neutral"),
        _level = 0
    }, rt.Widget, rt.Drawable)
    out:set_level(level)

    if not meta.is_nil(which) and level ~= 0 then
        out._sprite:set_color(rt.Palette[which])
    end
    return out
end)

--- @overload
function bt.StatLevelIndicator:get_top_level_widget()
    return self._sprite
end

--- @brief
function bt.StatLevelIndicator:set_level(level)

    if level == self._level then return end

    local id = "neutral"
    if level > 3 then
        id = "up_infinite"
    elseif level == 3 then
        id = "up_3"
    elseif level == 2 then
        id = "up_2"
    elseif level == 1 then
        id = "up_1"
    elseif level == 0 then
        id = "neutral"
    elseif level == -1 then
        id = "down_1"
    elseif level == -2 then
        id = "down_2"
    elseif level == -3 then
        id = "down_3"
    elseif level < -3 then
        id = "down_infinite"
    end

    self._level = level
    self._sprite:set_animation(id)
end

--- @brief
function bt.StatLevelIndicator:get_level()
    return self._level
end
