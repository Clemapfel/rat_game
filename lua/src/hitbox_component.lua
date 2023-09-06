--- @class HitboxHandler
rt.HitboxHandler = {}

rt.HitboxHandler._world = love.physics.newWorld(0, 0, true)

--- @class HitboxType

--- @class HitboxComponent
rt.HitboxComponent = meta.new_type("HitboxComponent", function(holder)
    local out = meta.new(rt.HitboxComponent, {
        bounds = rt.Rectangle(0, 0, 0, 0)
    })
end)

--- @brief
function rt.HitboxComponent.set_centroid(self, x, y)
    meta.assert_isa(self, rt.HitboxComponent)

end