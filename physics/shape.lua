--- @class b2.Shape
b2.Shape = meta.new_type("PhysicsShape", function()
    rt.error("In b2.Shape(): trying to initialize a shape without a shape primitve, use `CircleShape`, `SegmentShape`, `CapsuleShape`, or `PolygonShape` instead")
    return nil
end)

--- @brief
function b2.Shape:destroy()
    box2d.b2DestroyShape(self._native)
end

--- @enum b2.ShapeType
b2.ShapeType = {
    CIRCLE = box2d.b2_circleShape,
    CAPSULE = box2d.b2_capsuleShape,
    SEGMENT = box2d.b2_segmentShape,
    POLYGON = box2d.b2_polygonShape,
    SMOOTH_SEGMENT = box2d.b2_smoothSegmentShape
}

--- @brief
function b2.Shape._default_shape_def(is_sensor)
    local shape_def = box2d.b2DefaultShapeDef()
    shape_def.density = 1 / 100
    if is_sensor ~= nil then shape_def.isSensor = is_sensor end
    return shape_def
end

--- @brief
function b2.CircleShape(body, circle, is_sensor)
    local shape_def = b2.Shape._default_shape_def(is_sensor)
    return meta.new(b2.Shape, {
        _native = box2d.b2CreateCircleShape(body._native, shape_def, circle._native)
    })
end

--- @brief
function b2.CapsuleShape(body, capsule, is_sensor)
    local shape_def = b2.Shape._default_shape_def(is_sensor)
    return meta.new(b2.Shape, {
        _native = box2d.b2CreateCapsuleShape(body._native, shape_def, capsule._native)
    })
end

--- @brief
function b2.SegmentShape(body, segment, is_sensor)
    local shape_def = b2.Shape._default_shape_def(is_sensor)
    return meta.new(b2.Shape, {
        _native = box2d.b2CreateSegmentShape(body._native, shape_def, segment._native)
    })
end

--- @brief
function b2.PolygonShape(body, polygon, is_sensor)
    local shape_def = b2.Shape._default_shape_def(is_sensor)
    return meta.new(b2.Shape, {
        _native = box2d.b2CreatePolygonShape(body._native, shape_def, polygon._native)
    })
end

--[[
function b2.ChainShape(body, ...)
    local chain_def = box2d.b2DefaultChainDef()
    local points = {...}
    local vec2s = ffi.new("b2Vec2[" .. #points / 2 .. "]")
    for i = 1, #points, 2 do
        local vec2 = b2.Vec2(points[i], points[i+1])
        vec2s[i] = vec2
        chain_def.count = chain_def.count + 1
    end
    chain_def.points = vec2s
    return meta.new(b2.Shape, {
        _native = box2d.b2CreateChain(body._native, chain_def)
    })
end
]]--

--- @brief
function b2.Shape:get_body()
    return b2.Body:new_from_id(box2d.b2Shape_GetBody(self._native))
end

--- @brief
function b2.Shape:get_type()
    return box2d.b2Shape_GetType(self._native)
end

--- @brief
function b2.Shape:get_is_circle()
    return box2d.b2Shape_GetType(self._native) == box2d.b2_circleShape
end

--- @brief
--- @return b2.Circle
function b2.Shape:get_circle()
    assert(self:get_is_circle())
    return b2.Circle:new_from_id(box2d.b2Shape_GetCircle(self._native))
end

--- @brief
function b2.Shape:set_circle(circle)
    box2d.b2Shape_SetCircle(self._native, circle._native)
end

--- @brief
function b2.Shape:get_is_capsule()
    return box2d.b2Shape_GetType(self._native) == box2d.b2_capsuleShape
end

--- @brief
--- @return b2.Capsule
function b2.Shape:get_capsule()
    assert(self:get_is_capsule())
    return b2.Capsule:new_from_id(box2d.b2Shape_GetCircle(self._native))
end

--- @brief
function b2.Shape:set_capsule(capsule)
    box2d.b2Shape_SetCapsule(self._native, capsule._native)
end

--- @brief
function b2.Shape:get_is_polygon()
    return box2d.b2Shape_GetType(self._native) == box2d.b2_polygonShape
end

--- @brief
--- @return b2.Polygon
function b2.Shape:get_polygon()
    assert(self:get_is_polygon())
    return b2.Polygon:new_from_id(box2d.b2Shape_GetCircle(self._native))
end

--- @brief
function b2.Shape:set_polygon(polygon)
    box2d.b2Shape_SetPolygon(self._native, polygon._native)
end

--- @brief
function b2.Shape:get_is_segment()
    return box2d.b2Shape_GetType(self._native) == box2d.b2_segmentShape
end

--- @brief
--- @return b2.Segment
function b2.Shape:get_segment()
    assert(self:get_is_segment())
    return b2.Segment:new_from_id(box2d.b2Shape_GetCircle(self._native))
end

--- @brief
function b2.Shape:set_segment(segment)
    box2d.b2Shape_SetSegment(self._native, segment._native)
end

--- @brief
function b2.Shape:is_sensor()
    return box2d.b2Shape_IsSensor(self._native)
end

--- @brief
function b2.Shape:set_density(density)
    box2d.b2Shape_SetDensity(self._native, density)
end

--- @brief
function b2.Shape:get_density()
    return box2d.b2Shape_GetDensity(self._native)
end

--- @brief
function b2.Shape:set_friction(friction)
    box2d.b2Shape_SetFriction(self._native, friction)
end

--- @brief
function b2.Shape:get_friction()
    return box2d.b2Shape_GetFriction(self._native)
end

--- @brief
function b2.Shape:set_restitution(restitution)
    box2d.b2Shape_SetRestitution(self._native, restitution)
end

--- @brief
function b2.Shape:get_restitution()
    return box2d.b2Shape_GetRestitution(self._native)
end

--- @brief
function b2.Shape:set_are_sensor_events_enabled(b)
    box2d.b2Shape_EnableSensorEvents(self._native, b)
end

--- @brief
function b2.Shape:get_are_sensor_events_enabled()
    return box2d.b2Shape_AreSensorEventsEnabled(self._native)
end

--- @brief
function b2.Shape:set_are_contact_events_enabled(b)
    box2d.b2Shape_EnableContactEvents(self._native, b)
end

--- @brief
function b2.Shape:get_are_contact_events_enabled()
    return box2d.b2Shape_AreContactEventsEnabled(self._native)
end

--- @brief
function b2.Shape:get_closest_point(position_x, position_y)
    local out = box2d.b2Sape_GetClosestPoint(b2.Vec2(position_x, position_y))
    return out.x, out.y
end

--- @brief
function b2.Shape:set_filter_data(category_bits, mask_bits, group_index)
    local filter = box2d.b2DefaultFilter();
    if category_bits ~= nil then
        filter.categoryBits = category_bits
    end

    if mask_bits ~= nil then
        filter.maskBits = mask_bits;
    end

    if group_index ~= nil then
        filter.groupIndex = group_index;
    end

    box2d.b2Shape_SetFilter(self._native, filter);
end

--- @brief
function b2.Shape:set_collision_group(group)
    local filter = box2d.b2DefaultFilter()
    if group == b2.CollisionGroup.ALL then
        filter.categoryBits = 0xFFFF
        filter.maskBits = 0xFFFF
        filter.groupIndex = 0
    elseif group == b2.CollisionGroup.NONE then
        filter.categoryBits = 0x0000
        filter.maskBits = 0x0000
        filter.groupIndex = 0
    else
        filter.categoryBits = group
        filter.maskBits = group
        filter.groupindex = 0
    end

    box2d.b2Shape_SetFilter(self._native, filter)
end

--- @brief
function b2.Shape:draw()
    local type = box2d.b2Shape_GetType(self._native)
    local body = box2d.b2Shape_GetBody(self._native)
    local transform = box2d.b2Body_GetTransform(body)

    love.graphics.push()
    love.graphics.translate(transform.p.x, transform.p.y)
    love.graphics.rotate(math.atan(transform.q.s, transform.q.c))

    local hue = (meta.hash(self) % 16) / 16
    love.graphics.setColor(rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(hue, 1, 1, 0.5))))

    if type == box2d.b2_circleShape then
        b2._draw_circle(box2d.b2Shape_GetCircle(self._native))
    elseif type == box2d.b2_polygonShape then
        b2._draw_polygon(box2d.b2Shape_GetPolygon(self._native))
    elseif type == box2d.b2_segmentShape then
        b2._draw_segment(box2d.b2Shape_GetSegment(self._native))
    elseif type == box2d.b2_capsuleShape then
        b2._draw_capsule(box2d.b2Shape_GetCapsule(self._native))
    elseif type == box2d.b2_smoothSegmentShape then
        b2._draw_smooth_segment(box2d.b2Shape_GetSmoothSegment(self._native))
    else
        error("In b2.Shape:draw: unhandlined shape type `" .. type .. "`")
    end

    love.graphics.pop()
end

--- @brief
function b2._draw_circle(circle, body)
    love.graphics.circle("fill", circle.center.x, circle.center.y, circle.radius)
    love.graphics.circle("line", circle.center.x, circle.center.y, circle.radius)
end

--- @brief
function b2._draw_polygon(polygon)
    local points = {}
    for i = 1, polygon.count do
        table.insert(points, polygon.vertices[i-1].x)
        table.insert(points, polygon.vertices[i-1].y)
    end
    love.graphics.polygon("fill", points)
    love.graphics.polygon("line", points)
end

--- @brief
function b2._draw_segment(segment)
    love.graphics.line(segment.point1.x, segment.point1.y, segment.point2.x, segment.point2.y)
end

--- @brief
function b2._draw_smooth_segment(smooth)
    love.graphics.line(smooth.segment.point1.x, smooth.segment.point1.y, smooth.segment.point2.x, smooth.segment.point2.y)
end

--- @brief
function b2._draw_capsule(capsule)
    local x1, y1, x2, y2 = capsule.center1.x, capsule.center1.y, capsule.center2.x, capsule.center2.y
    local radius = capsule.radius

    love.graphics.line(x1 - radius, y1, x2 - radius, y2)
    love.graphics.line(x1 + radius, y1, x2 + radius, y2)

    love.graphics.arc("line", "open", x1, y1, radius, -math.pi, 0)
    love.graphics.arc("line", "open", x2, y2, radius, 0, math.pi)
end