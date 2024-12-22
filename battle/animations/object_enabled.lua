rt.settings.battle.animation.object_enabled = {
    pre_compute_duration = 2,
    hold_duration = 1,
    duration = 1,
    use_caching = true
}

--- @class bt.Animation.OBJECT_ENABLED
bt.Animation.OBJECT_ENABLED = meta.new_type("OBJECT_ENABLED", rt.Animation, function(scene, object, entity, message)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(entity, bt.Entity)
    if message ~= nil then meta.assert_message(message) end
    assert(object.get_sprite_id ~= nil)
    return meta.new(bt.Animation.OBJECT_ENABLED, {
        _scene = scene,
        _object = object,
        _entity = entity,
        _target = nil,
        _triangles = {},

        _fade_out_animation = rt.TimedAnimation(0.3, 0, 1, rt.InterpolationFunctions.GAUSSIAN_LOWPASS),
        _position_animation = rt.TimedAnimation(rt.settings.battle.animation.object_enabled.duration,
            1, 0, rt.InterpolationFunctions.GAUSSIAN_LOWPASS
        ),
        _hold_animation = rt.TimedAnimation(rt.settings.battle.animation.object_enabled.hold_duration,
            1, 1, rt.InterpolationFunctions.CONSTANT
        ),

        _opacity = 1,

        _sprite_texture = rt.RenderTexture(),
        _triangles = {},

        _message = message,
        _message_done = false
    })
end, {
    _cache = {} -- store shards if caching enabled
})

--- @override
function bt.Animation.OBJECT_ENABLED:start()
    self._target = self._scene:get_sprite(self._entity)

    local sprite = rt.Sprite(self._object:get_sprite_id())
    sprite:realize()
    local sprite_w, sprite_h = sprite:measure()
    sprite:fit_into(0, 0)

    self._sprite_texture = rt.RenderTexture(sprite_w, sprite_h)
    self._sprite_texture:bind()
    sprite:draw()
    self._sprite_texture:unbind()

    local target_x, target_y = self._target:get_position()
    local target_width, target_height = self._target:get_snapshot():get_size()

    local x = target_x + 0.5 * target_width - 0.5 * sprite_w
    local y = target_y + 0.5 * target_height - 0.5 * sprite_h
    local width, height = sprite_w, sprite_h

    -- only compute shards once per sprite size
    if rt.settings.battle.animation.object_enabled.use_caching then
        local cache = bt.Animation.OBJECT_ENABLED._cache[sprite_w]
        if cache ~= nil then cache = cache[sprite_h] end
        if cache ~= nil then
            self._triangles = cache
            for shape in values(self._triangles) do
                shape.current_x = 0
                shape.current_y = 0
                shape:set_opacity(1)
                shape:set_texture(self._sprite_texture)
            end
            return
        end
    end

    local step = rt.settings.battle.animation.object_disabled.triangle_radius
    local perturbation_magnitude = step / 4

    local n_rows = math.ceil(height / step) + 1
    local n_cols = math.ceil(width / step) + 1 + 2

    local start_x = x + 0.5 * width - 0.5 * ((n_cols - 1) * step)
    local start_y = y + 0.5 * height - 0.5 * ((n_rows - 1) * step)
    local min_x, min_y, max_x, max_y = POSITIVE_INFINITY, POSITIVE_INFINITY, NEGATIVE_INFINITY, NEGATIVE_INFINITY

    self._vertices = {}
    for row_i = 1, n_rows do
        local row = {}
        local perturbation_row = {}
        for col_i = 1, n_cols do
            local current_x = start_x + (col_i - 1) * step - 0.5 * step
            local current_y = start_y + (row_i - 1) * step
            if row_i % 2 == 0 then current_x = current_x + 0.5 * step end

            local perturbation_x, perturbation_y = 0, 0
            if row_i > 1 and row_i < n_rows and col_i > 1 and col_i < n_cols then
                perturbation_x, perturbation_y = rt.translate_point_by_angle(0, 0, perturbation_magnitude, rt.random.number(0, 1) * math.pi * 2)
            end

            local x, y = current_x + perturbation_x, current_y + perturbation_y
            table.insert(row, {x, y})
            min_x = math.min(min_x, x)
            min_y = math.min(min_y, y)
            max_x = math.max(max_x, x)
            max_y = math.max(max_y, y)
        end
        table.insert(self._vertices, row)
    end

    self._triangles = {}
    local function get(i, j)
        local v = self._vertices[i][j]
        return v[1], v[2]
    end

    local function push_triangle(a_x, a_y, b_x, b_y, c_x, c_y)
        local centroid_x = (a_x + b_x + c_x) / 3
        local centroid_y = (a_y + b_y + c_y) / 3

        local shape = rt.VertexShape({
            {a_x, a_y, 0},
            {b_x, b_y, 0},
            {c_x, c_y, 0}
        })

        shape.angle = 0
        shape.rotation_weight = rt.random.number(-1, 1)
        shape.centroid_x = centroid_x
        shape.centroid_y = centroid_y

        shape.current_x = 0
        shape.current_y = 0

        local angle = rt.angle(shape.centroid_x - (x + 0.5 * width), shape.centroid_y - (y + 0.5 * height))
        shape.last_x, shape.last_y = rt.translate_point_by_angle(
            0, 0,
            -1,
            angle
        )

        shape:set_vertex_texture_coordinate(1, (a_x - x) / width, (a_y - y) / height)
        shape:set_vertex_texture_coordinate(2, (b_x - x) / width, (b_y - y) / height)
        shape:set_vertex_texture_coordinate(3, (c_x - x) / width, (c_y - y) / height)
        shape:set_texture(self._sprite_texture)
        table.insert(self._triangles, shape)
    end

    for row_i = 1, n_rows - 1 do
        for col_i = 1, n_cols - 1 do
            if row_i % 2 == 0 then
                do
                    local a_x, a_y = get(row_i, col_i)
                    local b_x, b_y = get(row_i + 1, col_i)
                    local c_x, c_y = get(row_i + 1, col_i + 1)
                    push_triangle(a_x, a_y, b_x, b_y, c_x, c_y)
                end

                do
                    local a_x, a_y = get(row_i, col_i)
                    local b_x, b_y = get(row_i, col_i + 1)
                    local c_x, c_y = get(row_i + 1, col_i + 1)
                    push_triangle(a_x, a_y, b_x, b_y, c_x, c_y)
                end
            else
                do
                    local a_x, a_y = get(row_i, col_i)
                    local b_x, b_y = get(row_i, col_i + 1)
                    local c_x, c_y = get(row_i + 1, col_i)
                    push_triangle(a_x, a_y, b_x, b_y, c_x, c_y)
                end

                do
                    local a_x, a_y = get(row_i, col_i + 1)
                    local b_x, b_y = get(row_i + 1, col_i)
                    local c_x, c_y =  get(row_i + 1, col_i + 1)
                    push_triangle(a_x, a_y, b_x, b_y, c_x, c_y)
                end
            end
        end
    end

    -- pre-generate paths
    local duration = rt.settings.battle.animation.object_enabled.pre_compute_duration
    local step = duration / 100
    for shape in values(self._triangles) do
        local points = {
            shape.current_x,
            shape.current_y
        }

        local elapsed = 0
        local n = 0
        while elapsed < duration do
            local acceleration = 1 * elapsed
            local angular_acceleration = 10e-3
            local current_x, current_y = shape.current_x, shape.current_y
            local next_x = shape.current_x + (shape.current_x - shape.last_x) + acceleration * step * step
            local next_y = shape.current_y + (shape.current_y - shape.last_y) + acceleration * step * step
            shape.current_x, shape.current_y = next_x, next_y
            shape.last_x, shape.last_y = current_x, current_y
            shape.angle = shape.angle + angular_acceleration * step * math.pi * 2 * shape.rotation_weight

            table.insert(points, 1, shape.current_y)
            table.insert(points, 1, shape.current_x)
            n = n + 1
            elapsed = elapsed + step
        end

        shape.path = rt.Path(points)
        shape.n_points = n
    end

    if rt.settings.battle.animation.object_enabled.use_caching then
        bt.Animation.OBJECT_ENABLED._cache[sprite_w] = {
            [sprite_h] = self._triangles
        }
    end

    self._scene:send_message(self._message, function()
        self._message_done = true
    end)
end

--- @override
function bt.Animation.OBJECT_ENABLED:update(delta)
    if self._position_animation:update(delta) then
        if self._hold_animation:update(delta) then
            self._fade_out_animation:update(delta)
            self._opacity = self._fade_out_animation:get_value()
            for shape in values(self._triangles) do
                shape:set_opacity(self._opacity)
            end
        end
    end

    local fraction = self._position_animation:get_value()
    for shape in values(self._triangles) do
        shape.current_x, shape.current_y = shape.path:at(fraction)
    end

    return self._fade_out_animation:get_is_done() and self._fade_out_animation:get_is_done() and self._message_done
end

--- @override
function bt.Animation.OBJECT_ENABLED:draw()
    for shape in values(self._triangles) do
        love.graphics.translate(shape.current_x, shape.current_y)
        shape:draw()
        love.graphics.translate(-shape.current_x, -shape.current_y)
    end
end

