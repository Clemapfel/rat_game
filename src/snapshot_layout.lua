--- @class rt.SnapshotLayout
--- @brief caches rendered child to a canvas, this can be used to apply color transforms or reduce load during rendering
rt.SnapshotLayout = meta.new_type("SnapshotLayout", function()
    local out = meta.new(rt.SnapshotLayout, {
        _child = {},
        _canvas = rt.RenderTexture(1, 1),
        _canvas_initialized = false,
        _shader = rt.Shader(rt.SnapshotLayout._shader_source),
        _rgb_offsets = {0, 0, 0},
        _hsv_offsets = {0, 0, 0},
        _alpha_offset = 0,
        _position_x = 0,
        _position_y = 0
    }, rt.Drawable, rt.Widget)
    return out
end)

rt.SnapshotLayout._shader_source = [[
#pragma glsl3

vec3 rgb_to_hsv(vec3 c)
{
    vec4 K = vec4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    vec4 p = mix(vec4(c.bg, K.wz), vec4(c.gb, K.xy), step(c.b, c.g));
    vec4 q = mix(vec4(p.xyw, c.r), vec4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return vec3(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x);
}

vec3 hsv_to_rgb(vec3 c)
{
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}

uniform float _r_offset;
uniform float _g_offset;
uniform float _b_offset;
uniform float _h_offset;
uniform float _s_offset;
uniform float _v_offset;
uniform float _a_offset;

vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coordinates, vec2 vertex_position)
{
    vec4 color = Texel(texture, texture_coordinates);

    vec3 as_rgb = color.rgb;
    as_rgb.r += _r_offset;
    as_rgb.g += _g_offset;
    as_rgb.b += _b_offset;

    as_rgb = clamp(as_rgb, vec3(0), vec3(1));

    vec3 as_hsv = rgb_to_hsv(as_rgb);
    as_hsv.x += _h_offset;
    as_hsv.y += _s_offset;
    as_hsv.z += _v_offset;

    as_hsv = clamp(as_hsv, vec3(0), vec3(1));

    as_rgb = hsv_to_rgb(as_hsv);
    return vec4(as_rgb, color.a + _a_offset) * vertex_color;
}
]]

--- @brief update internally held render canvas
function rt.SnapshotLayout:snapshot()

    if meta.is_widget(self._child) then
        self._canvas:bind_as_render_target()
        self._child:draw()
        self._canvas:unbind_as_render_target()
    end

    self._shader:send("_r_offset", self._rgb_offsets[1])
    self._shader:send("_g_offset", self._rgb_offsets[2])
    self._shader:send("_b_offset", self._rgb_offsets[3])
    self._shader:send("_h_offset", self._hsv_offsets[1])
    self._shader:send("_s_offset", self._hsv_offsets[2])
    self._shader:send("_v_offset", self._hsv_offsets[3])
    self._shader:send("_a_offset", self._alpha_offset)
end

--- @overload rt.Drawable.draw
function rt.SnapshotLayout:draw()
    
    if not self._canvas_initialized then
        self:snapshot()
        self._canvas_initialized = true
    end

    self._shader:bind()
    love.graphics.draw(self._canvas._native, self._position_x, self._position_y)
    self._shader:unbind()
end

--- @overload rt.Widget.size_allocate
function rt.SnapshotLayout:size_allocate(x, y, width, height)

    local canvas_w, canvas_h = self._canvas:get_size()
    self._position_x = x
    self._position_y = y

    if canvas_w ~= width or canvas_h ~= height or self._canvas_initialized == false then
        if meta.is_widget(self._child) and not self._is_locked then
            self._child:fit_into(rt.AABB(0, 0, width, height))
        end
        self._canvas = rt.RenderTexture(width, height)
    end

    self:snapshot()
end

--- @brief
function rt.SnapshotLayout:set_rgb_offset(r, g, b)
    self._rgb_offsets[1] = which(r, 0)
    self._rgb_offsets[2] = which(g, 0)
    self._rgb_offsets[3] = which(b, 0)
    self:snapshot()
end

--- @brief
function rt.SnapshotLayout:set_hsv_offset(h, s, v)
    self._hsv_offsets[1] = which(h, 0)
    self._hsv_offsets[2] = which(s, 0)
    self._hsv_offsets[3] = which(v, 0)
    self:snapshot()
end

--- @brief
function rt.SnapshotLayout:set_alpha_offset(value)
    self._alpha_offset = which(value, 0)
    self:snapshot()
end

--- @brief
function rt.SnapshotLayout:get_rgb_offset()
    return self._rgb_offsets[1], self._rgb_offsets[2], self._rgb_offsets[3]
end

--- @brief
function rt.SnapshotLayout:get_hsv_offset()
    return self._hsv_offsets[1], self._hsv_offsets[2], self._hsv_offsets[3]
end

--- @brief
function rt.SnapshotLayout:get_alpha_offset()
    return self._alpha_offset
end

--- @brief set singular child
--- @param child rt.Widget
function rt.SnapshotLayout:set_child(child)
    if not meta.is_nil(self._child) and meta.is_widget(self._child) then
        self._child:set_parent(nil)
    end

    self._child = child
    child:set_parent(self)

    if self:get_is_realized() then
        self._child:realize()
        self:reformat()
    end

    self:snapshot()
end

--- @brief get singular child
--- @return rt.Widget
function rt.SnapshotLayout:get_child()
    return self._child
end

--- @brief remove child
function rt.SnapshotLayout:remove_child()
    if not meta.is_nil(self._child) then
        self._child:set_parent(nil)
        self._child = nil
    end

    self:snapshot()
end

--- @overload rt.Widget.measure
function rt.SnapshotLayout:measure()
    if meta.is_nil(self._child) then return 0, 0 end
    return self._child:measure()
end

--- @overload rt.Widget.realize
function rt.SnapshotLayout:realize()
    if self:get_is_realized() then return end
    if meta.is_widget(self._child) then
        self._child:realize()
    end

    rt.Widget.realize(self)
    self:snapshot()
end