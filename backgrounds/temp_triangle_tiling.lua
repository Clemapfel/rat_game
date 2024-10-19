rt.Background.TEMP_TRIANGLE_TILING = meta.new_type("TEMP_TRIANGLE_TILING", rt.BackgroundImplementation, function()
    return meta.new(rt.Background.TEMP_TRIANGLE_TILING, {
        _elapsed = 0,
        _triangles = {},
        _vertices = {},
        _perturbation = {},
        _max_perturbation = 100,
        _n_rows = 0,
        _n_cols = 0
    })
end)

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:realize()
    if self._is_realized == true then return end
    self._is_realized = true
end

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:size_allocate(x, y, width, height)
    local step = 100

    local row_n = math.ceil(height / step) + 1
    local col_n = math.ceil(width / step) + 1 + 2
    self._n_rows = row_n
    self._n_cols = col_n

    local start_x = x + 0.5 * width - 0.5 * ((col_n - 1) * step)
    local start_y = y + 0.5 * height - 0.5 * ((row_n - 1) * step)

    local perturbation_magnitude = self._max_perturbation

    self._vertices = {}
    self._perturbation = {}
    for row_i = 1, row_n do
        local row = {}
        local perturbation_row = {}
        for col_i = 1, col_n do
            local current_x = start_x + (col_i - 1) * step - 0.5 * step
            local current_y = start_y + (row_i - 1) * step
            if row_i % 2 == 0 then current_x = current_x + 0.5 * step end

            local perturbation_x = 0--rt.random.number(-perturbation_magnitude, perturbation_magnitude)
            local perturbation_y = 0--rt.random.number(-perturbation_magnitude, perturbation_magnitude)

            table.insert(row, {current_x, current_y})
            table.insert(perturbation_row, {perturbation_x, perturbation_y})
        end
        table.insert(self._vertices, row)
        table.insert(self._perturbation, perturbation_row)
    end

    self:_update_triangles()
end

--- @brief
function rt.Background.TEMP_TRIANGLE_TILING:_update_triangles()
    self._triangles = {}
    
    local function get(i, j)  
        local v = self._vertices[i][j]
        local p = self._perturbation[i][j]
        return v[1] + p[1], v[2] + p[2]
    end
  
    for row_i = 1, self._n_rows - 1 do
        for col_i = 1, self._n_cols - 1 do
            if row_i % 2 == 0 then
                do
                    local a_x, a_y = get(row_i, col_i)
                    local b_x, b_y = get(row_i + 1, col_i)
                    local c_x, c_y = get(row_i + 1, col_i + 1)
                    table.insert(self._triangles, {
                        a_x, a_y, b_x, b_y, c_x, c_y
                    })
                end

                do
                    local a_x, a_y = get(row_i, col_i)
                    local b_x, b_y = get(row_i, col_i + 1)
                    local c_x, c_y = get(row_i + 1, col_i + 1)
                    table.insert(self._triangles, {
                        a_x, a_y, b_x, b_y, c_x, c_y
                    })
                end
            else
                do
                    local a_x, a_y = get(row_i, col_i)
                    local b_x, b_y = get(row_i, col_i + 1)
                    local c_x, c_y = get(row_i + 1, col_i)
                    table.insert(self._triangles, {
                        a_x, a_y, b_x, b_y, c_x, c_y
                    })
                end

                do
                    local a_x, a_y = get(row_i, col_i + 1)
                    local b_x, b_y = get(row_i + 1, col_i)
                    local c_x, c_y =  get(row_i + 1, col_i + 1)
                    table.insert(self._triangles, {
                        a_x, a_y, b_x, b_y, c_x, c_y
                    })
                end
            end
        end
    end
end

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:update(delta)
    if self._is_realized ~= true then return end
    self._elapsed = self._elapsed + delta

    local speed = 100
    local bound = POSITIVE_INFINITY--self._max_perturbation
    for row_i = 1, self._n_rows do
        for col_i = 1, self._n_cols do
            local perturbation = self._perturbation[row_i][col_i]
            --perturbation[1] = clamp(perturbation[1] + delta * speed * rt.random.number(-1, 1), -bound, bound)
            --perturbation[2] = clamp(perturbation[1] + delta * speed * rt.random.number(-1, 1), -bound, bound)
            perturbation[1] = math.sin(self._elapsed + love.math.simplexNoise(row_i * math.pi, col_i * math.pi)) * self._max_perturbation
            perturbation[2] = math.cos(self._elapsed + love.math.simplexNoise(row_i * math.pi, col_i * math.pi)) * self._max_perturbation
        end
    end

    self:_update_triangles()
end

--- @override
function rt.Background.TEMP_TRIANGLE_TILING:draw()
    if self._is_realized ~= true then return end

    love.graphics.setPointSize(5)
    local hue, hue_step = 0, math.pi / 4
    love.graphics.setPointSize(5)

    love.graphics.push()
    love.graphics.translate(0.5 * love.graphics.getWidth(), 0.5 * love.graphics.getHeight())
    love.graphics.scale(1 / 1)
    love.graphics.translate(-0.5 * love.graphics.getWidth(), -0.5 * love.graphics.getHeight())

    for triangle in values(self._triangles) do
        love.graphics.setColor(rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(hue, 1, 1, 1))))
        love.graphics.polygon("fill", triangle)
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.polygon("line", triangle)
        hue = (hue + hue_step) % 1
    end

    love.graphics.pop()
end
