--- @class bt.Event
bt.BattleEvent = meta.new_type("BattleEvent", function(config)
    return meta.new(bt.BattleEvent, {
        _config = config
    })
end, {
    on_battle_start = function(self, state, scene)
        return nil
    end,

    on_battle_end = function(self, state, scene)
        return nil
    end,

    on_turn_start = function(self, state, scene)

    end,

    on_turn_end = function(self, state, scene)

    end,
})