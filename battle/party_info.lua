rt.settings.party_info = {
    spd_font = rt.Font(40, "assets/fonts/pixel.ttf"),
    hp_font = rt.Font(20, "assets/fonts/pixel.ttf")
}

--- @class bt.PartyInfo
bt.PartyInfo = meta.new_type("PartyInfo", function(entity)
    meta.assert_isa(entity, bt.Entity)

    if meta.is_nil(env.party_info_spritesheet) then
        env.party_info_spritesheet = rt.SpriteSheet("assets/sprites/party_info.png")
    end

    local out = meta.new(bt.PartyInfo, {
        _entity = entity,
        _hp_label = {},  -- rt.Glyph
        _spd_label = {}, -- rt.Glyph
        _base = rt.Spacer(),
        _frame = rt.Frame(),

    })

    local hp_content = tostring(entity:get_hp()) .. " / " .. tostring(entity:get_hp_base())
    out._hp_label = rt.Glyph(rt.settings.party_info.hp_font, hp_content, {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.TRUE_WHITE
    })

    out._spd_label = rt.Glyph(rt.settings.party_info.spd_font, tostring(entity:get_speed()), {
        is_outlined = true,
        outline_color = rt.Palette.TRUE_BLACK,
        color = rt.Palette.SPEED
    })




end)