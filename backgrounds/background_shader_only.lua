--- @brief
function rt.Background.new_shader_only_background(name, shader_path)
    local out = meta.new_type(name, rt.BackgroundImplementation, function()
        return meta.new(rt.Background[name], {
            _shader_path = shader_path,
            _shader = nil, -- rt.Shader
            _bounds = rt.AABB(0, 0, 1, 1),
            _elapsed = 0
        })
    end)

    function out:realize()
        if self._is_realized == true then return end
        self._is_realized = true
        self._shader = rt.Shader(self._shader_path)
        self._elapsed = 0
    end

    function out:size_allocate(x, y, width, height)
        self._bounds = rt.AABB(x, y, width, height)
    end

    function out:draw()
        if self._is_realized ~= true then return end
        self._shader:bind()
        love.graphics.rectangle("fill", self._bounds.x, self._bounds.y, self._bounds.width, self._bounds.height)
        self._shader:unbind()
    end

    function out:update(delta, spectrum)
        self._elapsed = self._elapsed + delta
        if self._shader:has_uniform("elapsed") then
            self._shader:send("elapsed", self._elapsed)
        end
    end

    return out
end

-- ###

--- @class rt.Background.EYE
rt.Background.EYE = rt.Background.new_shader_only_background("EYE", "backgrounds/eye.glsl")

--- @class rt.Background.CLOUDS
rt.Background.CLOUDS = rt.Background.new_shader_only_background("CLOUDS", "backgrounds/clouds.glsl")

--- @class rt.Background.CONTRAST_TEST
rt.Background.CONTRAST_TEST = rt.Background.new_shader_only_background("CONTRAST_TEST", "backgrounds/contrast_test.glsl")

--- @class rt.Background.INK_IN_WATER
rt.Background.INK_IN_WATER = rt.Background.new_shader_only_background("INK_IN_WATER", "backgrounds/ink_in_water.glsl")

--- @class rt.Background.DOT_MATRIX
rt.Background.DOT_MATRIX = rt.Background.new_shader_only_background("DOT_MATRIX", "backgrounds/dot_matrix.glsl")

--- @class rt.Background.GRADIENT_DERIVATIVE
rt.Background.GRADIENT_DERIVATIVE = rt.Background.new_shader_only_background("GRADIENT_DERIVATIVE", "backgrounds/gradient_derivative.glsl")

--- @class rt.Background.GUITAR_STRINGS
rt.Background.GUITAR_STRINGS = rt.Background.new_shader_only_background("GUITAR_STRINGS", "backgrounds/guitar_strings.glsl")

--- @class rt.Background.LAVALAMP
rt.Background.LAVALAMP = rt.Background.new_shader_only_background("LAVALAMP", "backgrounds/lavalamp.glsl")

--- @class rt.Background.PARALLEL_LINES
rt.Background.PARALLEL_LINES = rt.Background.new_shader_only_background("PARALLEL_LINES", "backgrounds/parallel_lines.glsl")

--- @class rt.Background.STAINED_GLASS
rt.Background.STAINED_GLASS = rt.Background.new_shader_only_background("STAINED_GLASS", "backgrounds/stained_glass.glsl")

--- @class rt.Background.BUBBLEGUM
rt.Background.BUBBLEGUM = rt.Background.new_shader_only_background("BUBBLEGUM", "backgrounds/bubblegum.glsl")

--- @class rt.Background.COMPLEX_PLOT
rt.Background.COMPLEX_PLOT = rt.Background.new_shader_only_background("COMPLEX_PLOT", "backgrounds/complex_plot.glsl")

--- @class rt.Background.COMPLEX_TILING
rt.Background.COMPLEX_TILING = rt.Background.new_shader_only_background("COMPLEX_TILING", "backgrounds/complex_tiling.glsl")

--- @class rt.Background.FIREWORKS
rt.Background.FIREWORKS = rt.Background.new_shader_only_background("FIREWORKS", "backgrounds/fireworks.glsl")

--- @class rt.Background.CONFUSION
rt.Background.CONFUSION = rt.Background.new_shader_only_background("CONFUSION", "backgrounds/confusion.glsl")

--- @class rt.Background.HEART_BEAT
rt.Background.KARO_CROSSES = rt.Background.new_shader_only_background("KARO_CROSSES", "backgrounds/karo_crosses.glsl")

--- @class rt.Background.SQUIGGLY_DANCE
rt.Background.SQUIGGLY_DANCE = rt.Background.new_shader_only_background("SQUIGGLY_DANCE", "backgrounds/squiggly_dance.glsl")

--- @class rt.Background.CELEBRATION
rt.Background.CELEBRATION = rt.Background.new_shader_only_background("CELEBRATION", "backgrounds/celebration.glsl")


