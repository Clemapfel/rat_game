--- @class b2.World
b2.World = meta.new_type("PhysicsWorld", function(gravity_x, gravity_y, n_threads)
    local out
    if n_threads == nil or n_threads <= 1 then
        local def = box2d.b2DefaultWorldDef()
        def.gravity = b2.Vec2(gravity_x, gravity_y)
        out = meta.new(b2.World, {
            _native = box2d.b2CreateWorld(def)
        })
    else
        MAX_TASKS = 64

        task_main = function(start_i, end_i, worker_i, context)
            local data = ffi.cast("b2TaskData*", context)
            data.callback(start_i, end_i, worker_i, data.context)
        end

        enqueue_task = function(task_callback, n_items, min_range, task_context, user_context_ptr)
            local context = ffi.cast("b2UserContext*", user_context_ptr)
            if context.n_tasks < 64 then
                local task = ffi.cast("void*", context.tasks[context.n_tasks]) -- enkiTaskSet*
                local data = context.task_data[context.n_tasks]
                data.callback = task_callback
                data.context = task_context

                local params = ffi.typeof("enkiParamsTaskSet")()
                params.minRange = min_range
                params.setSize = n_items
                params.pArgs = data
                params.priority = 0

                enkiTS.enkiSetParamsTaskSet(task, params)
                enkiTS.enkiAddTaskSet(context.scheduler, task)
                context.n_tasks = context.n_tasks + 1

                return task
            else
                -- not enough tasks for this step
                task_callback(0, n_items, 0, task_context)
                rt.warning("In b2.World:step: multi-threading stepping exceeded number of available tasks")
                return ffi.CNULL
            end
        end

        finish_task = function(task_ptr, user_context)
            if task_ptr == ffi.CNULL then return end
            local context = ffi.cast("b2UserContext*", user_context)
            local task = ffi.cast("void*", task_ptr) -- enkiTaskSet*
            enkiTS.enkiWaitForTaskSet(context.scheduler, task)
        end

        local def = box2d.b2DefaultWorldDef()
        def.gravity = ffi.typeof("b2Vec2")(gravity_x, gravity_y)

        def.workerCount = n_threads
        def.enqueueTask = enqueue_task
        def.finishTask = finish_task

        local context = ffi.cast("b2UserContext*", ffi.C.malloc(ffi.sizeof("b2UserContext")))
        context.n_tasks = 0
        context.scheduler = enkiTS.enkiNewTaskScheduler()
        local config = enkiTS.enkiGetTaskSchedulerConfig(context.scheduler)
        config.numTaskThreadsToCreate = n_threads - 1
        enkiTS.enkiInitTaskSchedulerWithConfig(context.scheduler, config)

        for task_i = 1, MAX_TASKS do
            context.tasks[task_i - 1] = enkiTS.enkiCreateTaskSet(context.scheduler, box2d.b2InvokeTask)
        end

        def.userTaskContext = context

        out =  meta.new(b2.World, {
            _native = box2d.b2CreateWorld(def),
            _user_context = context
        })
    end

    out._debug_draw = box2d.b2CreateDebugDraw(
        b2.World._draw_polygon,
        b2.World._draw_solid_polygon,
        b2.World._draw_circle,
        b2.World._draw_solid_circle,
        b2.World._draw_solid_capsule,
        b2.World._draw_segment,
        b2.World._draw_transform,
        b2.World._draw_point,
        b2.World._draw_string,
        true,   -- draw_shapes
        true,   -- draw_joints
        false,  -- draw_joints_extra
        false,  -- draw_aabb
        false,  -- draw_mass
        true,   -- draw_contacts,
        true,   -- draw_graph_colors,
        false,  -- draw_contact_normals,
        false,  -- draw_contact_impulses,
        false   -- draw_friction_impulses,
    )
    return out
end)

--- @brief
--- @return Number, Number
function b2.World:get_gravity()
    local out = box2d.b2World_GetGravity(self._native)
    return out.x, out.y
end

--- @brief
function b2.World:set_gravity(gravity_x, gravity_y)
    box2d.b2World_SetGravity(self._native, b2.Vec2(gravity_x, gravity_y))
end

--- @brief
function b2.World:step(delta, n_iterations)
    if n_iterations == nil then n_iterations = 4 end

    local step = 1 / 60
    while delta > step do
        box2d.b2World_Step(self._native, step, n_iterations)
        delta = delta - step
    end
    box2d.b2World_Step(self._native, delta, n_iterations)

    if self._user_context ~= nil then -- enki threading
        self._user_context.n_tasks = 0
    end
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
--- @param callback (b2.Shape, point_x, point_y, normal_x, normal_y, fraction) -> fraction
function b2.World:raycast(start_x, start_y, end_x, end_y, callback)
    box2d.b2World_CastRayWrapper(
        self._native,
        b2.Vec2(start_x, start_y),
        b2.Vec2(end_x - start_x, end_y - start_y),
        box2d.b2DefaultQueryFilter(),
        function (shape_id, point, normal, fraction)
            return callback(meta.new(b2.Shape, {_native = shape_id[0]}), point.x, point.y, normal.x, normal.y, fraction)
        end
    )
end

--- @brief
--- @return (b2.Shape, Number, Number, Number, Number, Number) shape, point_x, point_y, normal_x, normal_y, fraction
function b2.World:raycast_closest(start_x, start_y, end_x, end_y)
    local result = box2d.b2World_CastRayClosest(
        self._native,
        b2.Vec2(start_x, start_y),
        b2.Vec2(end_x - start_x, end_y - start_y),
        box2d.b2DefaultQueryFilter()
    )

    if result.hit then
        local shape = meta.new(b2.Shape, {
            _native = result.shapeId
        })

        local point_x, point_y = result.point.x, result.point.y
        local normal_x, normal_y = result.normal.x, result.normal.y
        local fraction = result.fraction

        return shape, point_x, point_y, normal_x, normal_y, fraction
    else
        return nil
    end
end

--- @brief
function b2.World:explode(position_x, position_y, radius, impulse)
    box2d.b2World_Explode(self._native, b2.Vec2(position_x, position_y), radius, impulse)
end

--- @brief
function b2.World:draw()
    box2d.b2World_Draw(self._native, self._debug_draw)
end

function b2.World._bind_color(red, green, blue)
    love.graphics.setColor(red, 1 - green, blue)
end

--- @brief
--- void b2DrawPolygonFcn(const b2Vec2* vertices, int vertex_count, float red, float green, float blue);
function b2.World._draw_polygon(vertices, vertex_count, red, green, blue)
    b2.World._bind_color(red, green, blue)
    local to_draw = {}
    for i = 1, vertex_count do
        local vec = vertices[i - 1]
        table.insert(to_draw, vec.x)
        table.insert(to_draw, vec.y)
    end

    love.graphics.polygon("line", table.unpack(to_draw))
end

--- @brief
--- void b2DrawSolidPolygonFcn(b2Transform* transform, const b2Vec2* vertices, int vertex_count, float radius, float red, float green, float blue);
function b2.World._draw_solid_polygon(transform, vertices, vertex_count, radius, red, green, blue)
    b2.World._bind_color(red, green, blue)
    local translate_x, translate_y = transform.p.x, transform.p.y
    local angle = math.atan2(transform.q.s, transform.q.c)
    love.graphics.push()
    love.graphics.translate(translate_x, translate_y)
    love.graphics.rotate(angle)

    local to_draw = {}
    for i = 1, vertex_count do
        local vec = vertices[i - 1]
        table.insert(to_draw, vec.x)
        table.insert(to_draw, vec.y)
    end

    love.graphics.polygon("fill", table.unpack(to_draw))
    love.graphics.pop()
end

--- @brief
--- void b2DrawCircleFcn(b2Vec2* center, float radius, float red, float green, float blue);
function b2.World._draw_circle(center, radius, red, green, blue)
    b2.World._bind_color(red, green, blue)
    love.graphics.circle("line", center.x, center.y, radius)
end

--- @brief
--- void b2DrawSolidCircleFcn(b2Transform* transform, float radius, float red, float green, float blue);
function b2.World._draw_solid_circle(transform, radius, red, green, blue)
    b2.World._bind_color(red, green, blue)
    local translate_x, translate_y = transform.p.x, transform.p.y
    local angle = math.atan2(transform.q.s, transform.q.c)
    love.graphics.push()
    love.graphics.translate(translate_x, translate_y)
    love.graphics.rotate(angle)
    love.graphics.circle("fill", 0, 0, radius)
    love.graphics.pop()
end

--- @brief
--- void b2DrawSolidCapsuleFcn(b2Vec2* p1, b2Vec2* p2, float radius, float red, float green, float blue);
function b2.World._draw_solid_capsule(p1, p2, radius, red, green, blue)

    local x1, y1, x2, y2 = p1.x, p1.y, p2.x, p2.y

    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)
    local radius = radius

    love.graphics.push()
    love.graphics.translate(x1, y1)
    love.graphics.rotate(angle)

    b2.World._bind_color(red, green, blue)

    love.graphics.rectangle("fill", 0, -radius, length, 2 * radius)
    love.graphics.arc("fill", length, 0, radius, -math.pi / 2, math.pi / 2)
    love.graphics.arc("fill", 0, 0, radius, math.pi / 2, 3 * math.pi / 2)

    love.graphics.arc("line", length, 0, radius, -math.pi / 2, math.pi / 2)
    love.graphics.arc("line", 0, 0, radius, math.pi / 2, 3 * math.pi / 2)

    love.graphics.line(0, -radius, length, -radius)
    love.graphics.line(0, radius, length, radius)

    love.graphics.rotate(-angle)
    love.graphics.translate(-x1, -y1)
    love.graphics.pop()
end

--- @brief
--- void b2DrawSegmentFcn(b2Vec2* p1, b2Vec2* p2, float red, float green, float blue);
function b2.World._draw_segment(p1, p2, red, green, blue)
    love.graphics.setColor(red, green, blue)
    love.graphics.line(p1.x, p1.y, p2.x, p2.y)
end

--- @brief
--- void b2DrawTransformFcn(b2Transform*)
function b2.World._draw_transform(transform)
    local translate_x, translate_y = transform.p.x, transform.p.y
    local angle = math.atan2(transform.q.s, transform.q.c)
    -- noop
end

--- @brief
--- void b2DrawPointFcn(b2Vec2* p, float size, float red, float green, float blue);
function b2.World._draw_point(p, size, red, green, blue)
    love.graphics.setColor(red, green, blue)
    love.graphics.circle("fill", p.x, p.y, size / 2)
end

--- @brief
--- void b2DrawString(b2Vec2* p, const char* s);
function b2.World._draw_string(p, s)
    love.graphics.printf(ffi.string(s), p.x, p.y, POSITIVE_INFINITY)
end


