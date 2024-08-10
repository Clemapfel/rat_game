rt.settings.battle.animations.move = {
    duration = 2,
    n_rotations = 2
}

--- @class bt.Animation.MOVE
--- @param targets Table<bt.EntitySprite>
bt.Animation.MOVE = meta.new_type("MOVE", bt.Animation, function(scene, target, move)
    return meta.new(bt.Animation.MOVE, {
        _scene = scene,
        _target = target,
        _move = move,
        _per_target = {},

        _entity_texture = {}, -- rt.RenderTexture
        _entity_shape = {}, -- rt.VertexShape
        _entity_shape_bounds = {}, -- rt.AABB
        _angle = 0,

        _screen_texture = {}, -- rt.RenderTexture
        _screen_shape = {}, -- rt.VertexShape

        _elapsed = 0,
        _label_path = {},  -- rt.Spline
    })
end)

--- @override
function bt.Animation.MOVE:start()
    do
        local bounds = self._target:get_bounds()
        local label = rt.Label("<o>" .. self._move:get_name() .. "</o>")
        label:realize()
        label:set_alignment(rt.Alignment.START)
        label:fit_into(0, 0, bounds.width, bounds.height)

        local w, h = label:measure()
        local buffer_w, buffer_h = 0.1 * w, 0.1 * h
        self._entity_texture = rt.RenderTexture(w + 2 * buffer_w, h + 2 * buffer_h)

        love.graphics.push()
        self._entity_texture:bind_as_render_target()
        rt.graphics.translate(buffer_w, buffer_h)
        label:draw()
        self._entity_texture:unbind_as_render_target()
        love.graphics.pop()

        self._entity_shape = rt.VertexRectangle(bounds.x, bounds.y, bounds.width, bounds.height)
        self._entity_shape_bounds = bounds
        self._entity_shape:set_texture(self._entity_texture)
    end

    do
        local bounds = self._target:get_bounds()
        local label = rt.Label("<mono><b><color=BLACK>" .. string.gsub(string.upper(self._move:get_name()), " ", "") .. "</mono></b></color>", rt.settings.font.default_large)
        label:realize()
        label:set_alignment(rt.Alignment.START)
        label:fit_into(0, 0, bounds.width, bounds.height)

        local w, h = label:measure()
        local buffer_w, buffer_h = 0, 0
        self._screen_texture = rt.RenderTexture(w + 2 * buffer_w, h + 2 * buffer_h)
        self._screen_texture:set_scale_mode(rt.TextureScaleMode.LINEAR)

        love.graphics.push()
        self._screen_texture:bind_as_render_target()
        rt.graphics.translate(buffer_w, buffer_h)
        label:draw()
        self._screen_texture:unbind_as_render_target()
        love.graphics.pop()

        local min_x = w
        local max_x = 0
        local min_y = h
        local max_y = 0

        local image = self._screen_texture:as_image()
        for x = 1, w do
            for y = 1, h do
                local alpha = select(4, image:get_pixel(x, y))
                if alpha ~= 0 then
                    if x < min_x then min_x = x end
                    if x > max_x then max_x = x end
                    if y < min_y then min_y = y end
                    if y > max_y then max_y = y end
                end
            end
        end

        self._screen_shape = rt.VertexRectangle(0, 0, rt.graphics.get_width(), rt.graphics.get_height())
        self._screen_shape:set_texture(self._screen_texture)
        self._screen_shape:set_texture_rectangle(min_x / w, min_y / h, (max_x - min_x) / w, (max_y - min_y) / h)

        self._screen_shape_shader = rt.Shader([[
        vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
        {
            vec4 pixel = Texel(texture, texture_coords);
            vec4 result = pixel * color;
            if (result.a > 1 / 100.f)
                result.a = 1;
            return result;
        }
        ]])
    end
end

--- @override
function bt.Animation.MOVE:update(delta)
    if not self._is_started then return end

    local duration = rt.settings.battle.animations.move.duration
    self._elapsed = self._elapsed + delta
    local fraction = self._elapsed / duration

    local hold = 0.7
    local function spin(x)
        return math.atan(hold * math.tan(4 * math.pi * (x - 0.5)^3)) / math.pi + 0.5
    end

    self._angle = spin(fraction)
    self._angle = self._angle * 2 * math.pi * rt.settings.battle.animations.move.n_rotations

    self._entity_shape:set_opacity(rt.fade_ramp(fraction, 0.05))
    self._screen_shape:set_opacity(rt.fade_ramp(fraction, 0.25, 0.5))
    return self._elapsed < duration
end

--- @override
function bt.Animation.MOVE:finish()
end

--- @override
function bt.Animation.MOVE:draw()
    love.graphics.push()

    local x, y = self._entity_shape_bounds.x, self._entity_shape_bounds.y
    local w, h = self._entity_shape_bounds.width, self._entity_shape_bounds.height
    rt.graphics.translate(x + 0.5 * w, y + 0.5 * h)
    rt.graphics.rotate(self._angle)
    rt.graphics.translate(-1 * (x + 0.5 * w), -1 * (y + 0.5 * h))
    self._entity_shape:draw()
    love.graphics.pop()

    --self._screen_shape_shader:bind()
    --self._screen_shape:draw()
    --self._screen_shape_shader:unbind()
end


-- ###
