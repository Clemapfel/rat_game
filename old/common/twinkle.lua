--- @class rt.Twinkle
rt.Twinkle = meta.new_type("Twinkle", rt.Widget, rt.Updatable, function()
    local out = meta.new(rt.Twinkle, {
        _halo_mesh = nil, -- rt.VertexShape
        _star_mesh = nil, -- "

        _halo_mesh_data = {},
        _star_mesh_data = {},
        _n_arms = 5,
        _n_outer_vertices = 32,

        _radius_animation = rt.TimedAnimation(1, 0.05, 1, rt.InterpolationFunctions.TRIANGLE_WAVE),
        _is_initialized = false
    })
    out._radius_animation:set_should_loop(true)
    return out
end)

--- @override
function rt.Twinkle:realize()
    if self:already_realized() then return end
end

--- @override
function rt.Twinkle:size_allocate(x, y, width, height)
    local center_x, center_y = 0, 0

    local outer_radius = math.min(0.5 * width, 0.5 * height)
    local middle_radius = 0.2 * outer_radius
    local inner_radius = 0.15 * outer_radius

    self._outer_radius = outer_radius
    self._middle_radius = middle_radius
    self._inner_radius = inner_radius

    local function create_vertex(angle, radius)
        return {
            center_x + math.cos(angle) * radius,
            center_y + math.sin(angle) * radius,
            0, 0, 1, 1, 1, 1
        }
    end

    local step = 2 * math.pi / self._n_arms
    self._star_mesh_data = {{0, 0, 0, 0, 1, 1, 1, 0}}
    for angle = 0, 2 * math.pi, step do
        table.insert(self._star_mesh_data, create_vertex(angle, outer_radius))
        table.insert(self._star_mesh_data, create_vertex(angle + 0.15 * step, middle_radius))
        table.insert(self._star_mesh_data, create_vertex(angle + 0.5 * step, inner_radius))
        table.insert(self._star_mesh_data, create_vertex(angle + (1 - 0.15) * step, middle_radius))
    end
    self._star_mesh = rt.VertexShape(self._star_mesh_data)

    local halo_radius = 0.8 * outer_radius
    local halo_alpha = 0.5
    self._halo_radius = halo_radius
    step = 2 * math.pi / self._n_outer_vertices
    self._halo_mesh_data = {{0, 0, 0, 0, 1, 1, 1, 0}}
    for angle = 0, 2 * math.pi, step do
        table.insert(self._halo_mesh_data, {
            center_x + math.cos(angle) * halo_radius,
            center_y + math.sin(angle) * halo_radius,
            0, 0, 1, 1, 1, halo_alpha
        })
    end
    self._halo_mesh = rt.VertexShape(self._halo_mesh_data)

    self._position_x = x + 0.5 * width
    self._position_y = y + 0.5 * height

    self._is_initialized = true
end

--- @override
function rt.Twinkle:update(delta)
    if not self._is_initialized then return end

    local function set_xy(i, angle, radius)
        local vertex = self._star_mesh_data[i]
        vertex[1] = math.cos(angle) * radius
        vertex[2] = math.sin(angle) * radius
    end

    self._radius_animation:update(delta)
    local value = self._radius_animation:get_value()
    local outer_radius = self._outer_radius * value
    local middle_radius = self._middle_radius * value
    local inner_radius = self._inner_radius * value

    local step = 2 * math.pi / self._n_arms
    local i = 2
    for angle = 0, 2 * math.pi, step do
        set_xy(i + 0, angle, outer_radius)
        set_xy(i + 1, angle + 0.15 * step, middle_radius)
        set_xy(i + 2, angle + 0.5 * step, inner_radius)
        set_xy(i + 3, angle + (1 - 0.15) * step, middle_radius)
        i = i + 4
    end
    self._star_mesh:replace_data(self._star_mesh_data)

    local i = 2
    local step = 2 * math.pi / self._n_outer_vertices
    local halo_radius = self._halo_radius
    for angle = 0, 2 * math.pi, step do
        self._halo_mesh_data[i][1] = math.cos(angle) * halo_radius
        self._halo_mesh_data[i][2] = math.sin(angle) * halo_radius
    end
    self._halo_mesh:replace_data(self._halo_mesh_data)
end

--- @override
function rt.Twinkle:draw()
    --love.graphics.setWireframe(true)
    love.graphics.push()
    love.graphics.translate(self._position_x, self._position_y)
    self._halo_mesh:draw()
    self._star_mesh:draw()
    love.graphics.pop()
    --love.graphics.setWireframe(false)
end