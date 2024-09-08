rt.settings.battle.background.eye = {
    shader_path = "battle/backgrounds/eye.glsl"
}

bt.Background.FOCUS_RACK_DOTS = meta.new_type("FOCUS_RACK_DOTS", bt.Background, function()
    return meta.new(bt.Background.FOCUS_RACK_DOTS, {
        _shader = {},   -- rt.Shader
        _shape_mesh = rt.VertexRectangle(0, 0, 10, 10),
        _shape_texture = rt.RenderTexture(50, 50),
        _elapsed = 0,
        _focus_point = 0.5; -- in [0, 1]
        _bounds = rt.AABB(0, 0, 1, 1),
        _radius = 100,
        _n_dots = 1000,
        
    })
end)

--- @override
function bt.Background.FOCUS_RACK_DOTS:realize()
    if self._is_realized == true then return end
    self._is_realized = true

    self._shader = rt.Shader("battle/backgrounds/focus_rack_dots.glsl")

    self._input = rt.InputController()
    self._input:signal_connect("pressed", function(_, which)
        if which == rt.InputButton.UP then
            self._focus_point = self._focus_point + 0.1
        elseif which == rt.InputButton.DOWN then
            self._focus_point = self._focus_point - 0.1
        elseif which == rt.InputButton.A then
            self._focus_point = 0.1
        end
    end)

    local data_vertex_format = {
        {name = "xyzw", format = "floatvec4"},
    }

    local z_values = {}
    for i = 1, self._n_dots do
        table.insert(z_values, rt.random.number(0, 1))
    end
    table.sort(z_values, function(x, y)
        return x < y
    end)

    for i = 1, self._n_dots do
        z_values[i] = z_values[i]
    end

    local padding = 0
    local data_vertices = {}
    for i = 1, self._n_dots do
        local z = z_values[i] * 0.8
        table.insert(data_vertices, {
            rt.random.number(0, 1),
            rt.random.number(0, 1),
            z,
            z,
        })
    end
    self._data_mesh = love.graphics.newMesh(data_vertex_format, data_vertices, "points")
    self._shape_mesh._native:attachAttribute("xyzw", self._data_mesh, "perinstance", "xyzw")
end

--- @override
function bt.Background.FOCUS_RACK_DOTS:size_allocate(x, y, width, height)
    self._bounds = rt.AABB(x, y, width, height)
    local r = self._radius

    do
        local x, y, width, height = -r, -r, 2 * r, 2 * r
        self._shape_mesh:set_vertex_position(1, x, y)
        self._shape_mesh:set_vertex_position(2, x + width, y)
        self._shape_mesh:set_vertex_position(3, x + width, y + height)
        self._shape_mesh:set_vertex_position(4, x, y + height)
    end
end

--- @override
function bt.Background.FOCUS_RACK_DOTS:update(delta, intensity)
    self._elapsed = self._elapsed + delta

    if self._input:is_down(rt.InputButton.UP) then
        self._focus_point = self._focus_point + 0.01
    elseif self._input:is_down(rt.InputButton.DOWN) then
        self._focus_point = self._focus_point - 0.01
    end

    local x, y, width, height = 0, 0, 1, 1
    for i = 1, self._n_dots do
        local current_x, current_y, current_z, current_w = self._data_mesh:getVertexAttribute(i, 1)
        current_y = current_y + 2 * delta * 0.1 * clamp(current_z, 0.1) * 0.1
        --current_z = current_z + 1
        --current_w = current_w + 0.01

        if current_x > x + width then current_x = (current_x - x) % width end
        if current_y > y + height then current_y = (current_y - y) % height end
        if current_z > 1 then current_z = current_z % 1 end
        self._data_mesh:setVertexAttribute(i, 1, current_x, current_y, current_z, current_w)
    end
end

--- @override
function bt.Background.FOCUS_RACK_DOTS:draw()
    love.graphics.clear(0.1, 0.1, 0.1, 1)

    local x, y, w, h = rt.aabb_unpack(self._bounds)
    local scale = 1.3
    rt.graphics.push()
    rt.graphics.translate(0.5 * w, 0.5 * h)
    rt.graphics.scale(scale, scale)
    rt.graphics.translate(-0.5 * w, -0.5 * h)

    self._shader:bind()
    --self._shader:send("focus_point", self._focus_point)
    love.graphics.drawInstanced(self._shape_mesh._native, self._n_dots)
    self._shader:unbind()

    rt.graphics.pop()

    --[[
    self._shader:bind()
    --self._shader:send("elapsed", self._elapsed)
    --self._shader:send("instance_count", self._n_dots)
    --self._shader:send("focus", self._focus_point)
    self._shape:draw()
    self._shader:unbind()
    ]]--
end
