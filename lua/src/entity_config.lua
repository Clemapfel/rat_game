--- @class EntityConfig
rt.EntityConfig = meta.new_type("EntityConfig", function(config)

    meta.assert_number(config.hp_base)
    meta.assert_number(config.ap_base)
    meta.assert_number(config.attack_base)
    meta.assert_number(config.defense_base)
    meta.assert_number(config.speed_base)
    meta.assert_table(config.moveset)

    local out = meta.new(rt.EntityConfig, {

    })

    return out
end)

rt.ENTITIES = {
    TEST = rt.EntityConfig({
        hp_base = 0,
        ap_base = 0,
        attack_base = 0,
        defense_base = 0,
        speed_base = 0,
        moveset = {
            rt.TEST_MOVE
        }
    })
}

for id, config in pairs(rt.ENTITIES) do
    meta._install_property(config, "id", id)
end