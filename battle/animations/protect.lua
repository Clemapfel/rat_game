rt.settings.battle_animation.protect = {
    duration = 5,
    shield_color = rt.Palette.GRAY_4,
    shield_outline_color = rt.Palette.GRAY_2,
    sheen_color = rt.Palette.WHITE
}
--- @class
bt.Animation.PROTECT = meta.new_type("PROTECT", function(targets)
    local n_targets = sizeof(targets)
    local out = meta.new(bt.Animation.PROTECT, {
        _targets = targets,
        _n_targets = n_targets,

        _shields = {},           -- Table<rt.Shape>
        _shield_outlines = {},   -- Table<rt.Shape>
        _sheens = {},            -- Table<rt.Shape>
        _sheen_paths = {},       -- Table<rt.Spline>

        _elapsed = 0
    }, rt.StateQueueState)
    return out
end)

--- @overload
function bt.Animation.PROTECT:start()
    local settings = rt.settings.battle_animation.protect
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(false)
        local bounds = target:get_bounds()
        local shield = rt.Rectangle(bounds.x, bounds.y, bounds.width, bounds.height)
        shield:set_color(settings.shield_color)
        table.insert(self._shields, shield)

        local outline = rt.Rectangle(bounds.x, bounds.y, bounds.width, bounds.height)
        outline:set_color(settings.shield_outline_color)
        outline:set_is_outline(true)
        table.insert(self._shield_outlines, outline)

        local sheen_width = 30
        local function translate_point(point_x, point_y, distance, angle_dg)
            local rad = angle_dg * math.pi / 180
            return math3d.vec2(point_x + distance * math.cos(rad), point_y + distance * math.sin(rad))
        end

        local a = translate_point(bounds.x, bounds.y, 0.5 * sheen_width, -45)
        local b = translate_point(bounds.x + bounds.width, bounds.y + bounds.height, 0.5 * sheen_width, -45)
        local c = translate_point(bounds.x + bounds.width, bounds.y + bounds.height, 0.5 * sheen_width, 180 - 45)
        local d = translate_point(bounds.x, bounds.y, 0.5 * sheen_width, 180 - 45)

        local sheen = rt.Polygon(
            a.x, a.y, b.x, b.y, c.x, c.y, d.x, d.y
        )
        sheen:set_is_outline(false)
        sheen:set_color(settings.sheen_color)
        table.insert(self._sheens, sheen)

        local first = math3d.vec2(0, 0) --bounds.x, bounds.y)--translate_point(bounds.x + bounds.width, bounds.y, sheen_width, -45)
        local last = math3d.vec2(500, 800) --bounds.x + bounds.width, bounds.y + bounds.height)--translate_point(bounds.x, bounds.y + bounds.height, sheen_width, 180 - 45)
        local sheen_path = rt.Spline({first.x, first.y, last.x, last.y})
        table.insert(self._sheen_paths, sheen_path)
    end
end

--- @overload
function bt.Animation.PROTECT:update(delta)
    local duration = rt.settings.battle_animation.protect.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration
    for i = 1, self._n_targets do
        local sheen = self._sheens[i]
        local x, y = self._sheen_paths[i]:at(rt.linear(fraction))
        --x, y = sheen:get_centroid()
        --x = x + 1
        --y = y + 1
        self._sheens[i]:set_centroid(x, y)
    end
    return self._elapsed < duration
end

--- @overload
function bt.Animation.PROTECT:finish()
    for i = 1, self._n_targets do
        local target = self._targets[i]
        target:set_is_visible(true)
    end
end

--- @overload
function bt.Animation.PROTECT:draw()
    for i = 1, self._n_targets do
        --self._shields[i]:draw()
        --self._shield_outlines[i]:draw()

        local bounds = self._targets[i]:get_bounds()
        --love.graphics.setScissor(bounds.x, bounds.y, bounds.width, bounds.height)
        self._sheens[i]:draw()
        --love.graphics.setScissor()

        self._sheen_paths[i]:draw()
    end
end