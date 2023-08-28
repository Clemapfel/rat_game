--- @class Status
rt.Status = meta.new_type("Status", function(config)

    meta.assert_string(config.name)
    meta.assert_string(config.description)

    local out = meta.new(rt.Status, {
        name = "",
        description = "",

        duration = POSITIVE_INFINITY,

        on_turn_start = function(self)
            meta.assert_type(self, rt.BattleEntity)
        end,
        on_turn_end = function(self)
            meta.assert_type(self, rt.BattleEntity)
        end,
    })

    for key, value in pairs(config) do
        out[key] = value
    end
    meta.set_is_mutable(out, false)
    return out
end)

rt.STATUS = {

}

for id, config in pairs(rt.STATUS) do
    meta._install_property(config, "id", id)
end