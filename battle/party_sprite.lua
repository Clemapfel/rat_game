
--- @class bt.PartySprite
bt.PartySprite = meta.new_type("BattlePartySprite", bt.EntitySprite, function(entity)

    local entity_id_to_sprite_id = {
        ["RAT"] = "battle/rat_battle.png",
        ["GIRL"] = "battle/girl_battle.png",
        ["MC"] = "battle/mc_battle.png",
        ["PROF"] = "battle/prof_battle.png",
        ["WILDCARD"] = "battle/wildcard_battle.png"
    }

    return meta.new(bt.PartySprite, {
        _frame = rt.Frame(),

        _health_bar = bt.HealthBar(0, entity:get_hp_base(), entity:get_hp()),
        _speed_value = bt.SpeedValue(entity:get_speed()),
        _status_consumable_bar = bt.OrderedBox(),

        _sprite = rt.Sprite(entity_id_to_sprite_id(entity:get_id())),
        _sprite_is_visible = false,
    })
end)

--- @override
function bt.PartySprite:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._health_bar:realize()
    self._speed_value:realize()
    self._status_consumable_bar:realize()
    self._sprite:realize()
end

--- @override
function bt.PartySprite:size_allocate(x, y, width, height)
    https://github.com/thestk/rtmidi
end