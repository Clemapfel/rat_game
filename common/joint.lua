--- @class rt.JointType
rt.JointType = meta.new_enum({
    PIVOT = "PIVOT",
    FIXED = "FIXED",
    MAX_DISTANCE = "MAX_DISTANCE",
    FRICTION = "FRICTION"
})

--- @class rt.Joint
rt.Joint = meta.new_type("Joint", rt.Drawable, function(joint_type, collider_a, collider_b, x1, y1, x2, y2, ...)
    x2 = which(x2, x1)
    y2 = which(y2, y1)

    local out = meta.new(rt.Joint, {
        _collider_a = collider_a,
        _collider_b = collider_b,
        _type = joint_type,
        _native = {}, -- love.Joint
    })

    if out._type == rt.JointType.PIVOT then
        out._native = love.physics.newRevoluteJoint(
            collider_a._body,
            collider_b._body,
            x1, y1, x2, y2,
            false -- no collision between bodies
        )
    elseif out._type == rt.JointType.FIXED then
        out._native = love.physics.newWeldJoint(
            collider_a._body,
            collider_b._body,
            x1, y1, x2, y2
        )
    elseif out._type == rt.JointType.MAX_DISTANCE then
        local distance = _G._select(1, ...)
        distance = which(distance, 0)
        out._native = love.physics.newRopeJoint(
            collider_a._body,
            collider_b._body,
            x1, y1, x2, y2,
            distance
        )
    elseif out._type == rt.JointType.FRICTION then
        local distance = _G._select(1, ...)
        distance = which(distance, 0)
        out._native = love.physics.newFrictionJoint(
            collider_a._body,
            collider_b._body,
            x1, y1, x2, y2
        )
    else
        rt.error("In rt.Joint: unhandled joint type `" .. joint_type .. "`")
    end

    return out
end)

--- @brief
function rt.Joint:draw()
    local grey = 0.5
    love.graphics.setColor(grey, grey, grey, 0.75)
    local x1, y1, x2, y2 = self._native:getAnchors()
    love.graphics.circle("line", x1, y1, 3)

    love.graphics.setColor(grey, grey, grey, 0.5)
    love.graphics.circle("fill", x1, y1, 3)
end