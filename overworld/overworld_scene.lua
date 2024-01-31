--- @class
ow.OverworldScene = meta.new_type("OverworldScene", function()
    local out = meta.new(ow.OverworldScene, {
        _world = rt.PhysicsWorld(0, 0)
    })

    out._world._native:setCallbacks(
        ow.OverworldScene._on_begin_contact,
        ow.OverworldScene._on_end_contact,
        ow.OverworldScene._on_pre_solve,
        ow.OverworldScene._on_post_solve
    )
    return out
end)

--- @brief [internal]
function ow.OverworldScene._on_begin_contact(fixture_a, fixture_b, contact)

end

--- @brief
function ow.OverworldScene._on_end_contact()
    --println("end")
end

--- @brief
function ow.OverworldScene._on_pre_solve()
    --println("pre")
end

--- @brief
function ow.OverworldScene._on_post_solve()
    --println("post")
end
