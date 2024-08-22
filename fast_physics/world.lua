--- @class b2.World
b2.World = setmetatable({}, {
    __call = function(_, gravity_x, gravity_y, n_threads)
        return b2.World:new(gravity_x, gravity_y, n_threads)
    end
})

--- @brief
function b2.World:new(gravity_x, gravity_y, n_threads)
    local def = box2d.b2DefaultWorldDef()
    def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)

    if n_threads ~= nil then
        assert(type(n_threads) == "number" and n_threads > 0 and math.fmod(n_threads, 1) == 0)
        b2._initialize_threads(def, n_threads)
    end

    local world_id = ffi.gc(
        box2d.b2CreateWorld(def),
        box2d.b2DestroyWorld
    )

    return b2.World:new_from_id(world_id)
end

--- @brief
function b2.World:new_from_id(id)
    local out = setmetatable({
        _native = id,
        _debug_draw = ffi.typeof("b2DebugDraw")()
    }, {
        __index = b2.World
    })
    b2._initialize_debug_draw(out._debug_draw)
    return out
end

--- @brief
--- @return Number, Number
function b2.World:get_gravity()
    local out = box2d.b2World_GetGravity(self._native)
    return out.x, out.y
end

--- @brief
function b2.World:set_gravity(gravity_x, gravity_y)
    box2d.b2World_SetGravity(self._native, ffi.typeof("b2Vec2")(gravity_x, gravity_y))
end

--- @brief
function b2.World:step(delta, n_iterations)
    if n_iterations == nil then n_iterations = 4 end
    box2d.b2World_Step(self._native, delta, n_iterations)
end

--- @brief
function b2.World:set_sleeping_enabled(b)
    box2d.b2World_EnableSleeping(self._native, b)
end

--- @brief
function b2.World:set_continuous_enabled(b)
    box2d.b2World_EnableContinuous(self._native, b)
end

--- @brief
function b2.World:draw()
    box2d.b2World_Draw(self._native, self._debug_draw)
end

--- @brief
function b2._initialize_threads(world_def)
    -- TODO
end

-- void ( *DrawPolygon )( const b2Vec2* vertices, int vertexCount, b2HexColor color, void* context );
function b2._draw_polygon(transform, vertices, n_pointers, radius, color, context)
    local points = {}
    for i = 1, n_points do
        table.insert(points, vertices[i].x)
        table.insert(points, vertices[i].y)
    end

    love.graphics.push()
    love.graphics.rotate(math.atan(s, c))
    love.graphics.translate(transform.p.x, transform.p.y)
    local r, g, b = b2._b2_hex_color_to_rgb(hex)
    love.graphics.setColor(r, g, b, 1)
    love.graphics.setLineWidth(1)
    love.graphics.polygon("line", vertices)
    love.graphics.pop()
end

--- void ( *DrawPolygon )( const b2Vec2* vertices, int vertexCount, b2HexColor color, void* context );
function _draw_polygon(vertices, n_vertices, color, context)

end

-- void ( *DrawSolidPolygon )( b2Transform transform, const b2Vec2* vertices, int vertexCount, float radius, b2HexColor color,void* context );
function _draw_solid_polygon(transform, n_vertices, color, radius, context)

end

-- void ( *DrawCircle )( b2Vec2 center, float radius, b2HexColor color, void* context );
function _draw_circle(center, radius, color, context)

end

-- void ( *DrawSolidCircle )( b2Transform transform, float radius, b2HexColor color, void* context );
function _draw_solid_circle(transform, radius, color, context)

end

-- void ( *DrawCapsule )( b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context );
function _draw_capsule(p1, p2, radius, color, context)

end

-- void ( *DrawSolidCapsule )( b2Vec2 p1, b2Vec2 p2, float radius, b2HexColor color, void* context );
function _draw_solid_capsule(p1, p2, radius, color, context)

end

-- void ( *DrawSegment )( b2Vec2 p1, b2Vec2 p2, b2HexColor color, void* context );
function _draw_segment(p1, p2, color, context)

end

-- void ( *DrawTransform )( b2Transform transform, void* context );
function _draw_transform(transform, context)

end

-- void ( *DrawPoint )( b2Vec2 p, float size, b2HexColor color, void* context );
function _draw_point(p, size, color, context)

end

-- void ( *DrawString )( b2Vec2 p, const char* s, void* context );
function _draw_string(p, string, context)

end

--- @brief
--- @param b2DebugDraw
function b2._initialize_debug_draw(config)

    function b2._b2_hex_color_to_rgb(hex)
        -- Remove the hash at the start if it's there
        hex = tostring(hex):gsub("#", "")

        -- Convert the hex string to numbers
        dbg(hex)
        local r = tonumber(hex:sub(1, 2), 16)
        local g = tonumber(hex:sub(3, 4), 16)
        local b = tonumber(hex:sub(5, 6), 16)

        return r / 255, g / 255, b / 255
    end

    --config.drawShapes = true
    --config.drawAABBs = true
    --config.drawMass = true

    config.DrawPolygon = ffi.new("void (*)( const b2Vec2* vertices, int vertexCount, b2HexColor color, void* context )", _draw_polygon);
    config.DrawSolidPolygon = ffi.new("void (*)( b2Transform transform, const b2Vec2* vertices, int vertexCount, float radius, b2HexColor color, void* context )", _draw_solid_polygon)
    --config.DrawCircle = ffi.cast("void ( * )( b2Vec2 center, float radius, b2HexColor color, void* context )", _draw_circle)
    --config.DrawSolidCircle = ffi.cast("    void ( *DrawSolidCircle )( b2Transform transform, float radius, b2HexColor color, void* context )", _draw_solid_circle)
--[[
    config.DrawCapsule = _draw_capsule
    config.DrawSolidCapsule = _draw_solid_capsule
    config.DrawSegment = _draw_segment
    config.DrawTransform = _draw_transform
    config.DrawPoint = _draw_point
    config.DrawString = _draw_string
    ]]--
end

