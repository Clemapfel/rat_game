--- @class Weather
rt.Weather = meta.new_type("Weather", {

    id = "",

    turn_count = POSITIVE_INFINITY,

    start_of_turn_effect = rt.IgnitionEffect(),
    end_of_turn_effect = rt.IgnitionEffect(),

    continuous_effect = rt.ContinuousEffect(),

    on_create_effect = rt.IgnitionEffect(),
    on_subside_effect = rt.IgnitionEffect()
})