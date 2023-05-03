--- @class Weather
rt.Weather = meta.new_type("Weather", {

    id = "",
    name = "TODO",
    description = "TODO",

    turn_count = POSITIVE_INFINITY,

    --- @brief (Entity target) -> nil
    on_start_of_turn = rt.IgnitionEffect(),

    --- @brief (Entity target) -> nil
    on_end_of_turn = rt.IgnitionEffect(),

    --- @brief applied to every entity while weather is active
    continuous_effect = rt.ContinuousEffect(),

    --- @brief (Entity target) -> nil
    on_create = rt.IgnitionEffect(),

    --- @brief (Entity target) -> nil
    on_subside = rt.IgnitionEffect()
})

--- @brief add weather
--- @param id
--- @param args
function rt.new_weather(id, args)

    local out = meta.new(rt.Weather, args)
    out.id = id

    if (args.continuous_effect ~= nil) then
        meta.assert_type(rt.ContinuousEffect, args.continuous_effect, "new_weather", "continuous_effect")
    end

    out.on_start_of_turn = rt.IgnitionEffect(args.on_start_of_turn)
    out.on_end_of_turn = rt.IgnitionEffect(args.on_end_of_turn)
    out.on_create = rt.IgnitionEffect(args.on_create)
    out.on_subside = rt.IgnitionEffect(args.on_subside)

    return out
end