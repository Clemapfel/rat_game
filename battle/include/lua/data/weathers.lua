--- @brief noop weather
rt.NO_WEATHER = rt.new_weather("no_weather", {

    name = "Clear Sky",
    description = "TODO"
})

--- @brief sandstorm, does 1/16th at end of turn
rt.SANDSTORM = rt.new_weather("sandstorm", {

    turn_count = 5,

    on_end_of_turn = function(target)
        rt.log("The Sandstorm rages")
        rt.reduce_hp(target, 1 / 16 * rt.get_hp_base(target))
    end,

    on_create = function(target)
        rt.log("A Sandstorm started")
    end,

    on_subside = function(target)
        rt.log("Sandstorm stopped")
    end,

    name = "Sandstorm",
    description = "TODO"
})