rt.settings.battle.animation.object_disabled = {
    hold_duration = 1,
    shatter_duration = 1,
    fade_out_duration = 1,
    triangle_radius = 30
}

--- @class bt.Animation.OBJECT_DISABLED
bt.Animation.OBJECT_DISABLED = meta.new_type("OBJECT_DISABLED", rt.Animation, function(scene, object, sprite)
    meta.assert_isa(scene, bt.BattleScene)
    meta.assert_isa(sprite, bt.EnemySprite)
    assert(object.get_sprite_id ~= nil)
    return meta.new(bt.Animation.OBJECT_DISABLED, {
        _scene = scene,
        _object = object,
        _target = sprite,
        _triangles = {},
        _opacity_animation = rt.TimedAnimation(rt.settings.battle.animation.object_disabled.fade_out_duration, 0, 1, rt.InterpolationFunctions.GAUSSIAN_LOWPASS),
        _opacity = 1,

        _render_texture = rt.RenderTexture(),
        _render_texture_x = 0,
        _render_texture_y = 0,
        _sprite_texture = rt.RenderTexture(),

        _hold_elapsed = 0,
        _shatter_elapsed = 0
    })
end)

--- @override
function bt.Animation.OBJECT_DISABLED:start()
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

    local padding = step
    local w, h = max_x - min_x + 2 * padding, max_y - min_y + 2 * padding
    if self._render_texture:get_width() ~= w or self._render_texture:get_height() ~= h then
        self._render_texture = rt.RenderTexture(w, h)
    end
    self._render_texture_x = min_x - padding
    self._render_texture_y = min_y - padding

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
            -1 * rt.random.number(0.2, 0.4),
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
end

--- @override
function bt.Animation.OBJECT_DISABLED:update(delta)
    -- hold still, then shatter, then fade out
    self._hold_elapsed = self._hold_elapsed + delta
    local should_shatter = false
    if self._hold_elapsed > rt.settings.battle.animation.object_disabled.hold_duration then
        self._shatter_elapsed = self._shatter_elapsed + delta
        should_shatter = true
        if self._shatter_elapsed > rt.settings.battle.animation.object_disabled.shatter_duration then
            self._opacity_animation:update(delta)
        end
    end

    if should_shatter then
        local acceleration = 1 * self._shatter_elapsed
        local angular_acceleration = 10e-3
        for shape in values(self._triangles) do
            local current_x, current_y = shape.current_x, shape.current_y
            local next_x = shape.current_x + (shape.current_x - shape.last_x) + acceleration * delta * delta
            local next_y = shape.current_y + (shape.current_y - shape.last_y) + acceleration * delta * delta
            shape.current_x, shape.current_y = next_x, next_y
            shape.last_x, shape.last_y = current_x, current_y
            shape.angle = shape.angle + angular_acceleration * delta * math.pi * 2 * shape.rotation_weight
        end
    end

    self._render_texture:bind()
    love.graphics.clear(true, false, false)
    love.graphics.translate(-1 * self._render_texture_x, -1 * self._render_texture_y)
    for shape in values(self._triangles) do
        love.graphics.push()
        love.graphics.translate(shape.centroid_x, shape.centroid_y)
        love.graphics.rotate(shape.angle)
        love.graphics.translate(-shape.centroid_x, -shape.centroid_y)
        love.graphics.translate(shape.current_x, shape.current_y)
        shape:draw()
        love.graphics.pop()
    end
    love.graphics.translate(1 * self._render_texture_x, 1 * self._render_texture_y)
    self._render_texture:unbind()

    return self._opacity_animation:get_is_done()
end

--- @override
function bt.Animation.OBJECT_DISABLED:draw()
    self._render_texture:draw(
        self._render_texture_x, self._render_texture_y,
        1, 1, 1, self._opacity_animation:get_value()
    )
end
