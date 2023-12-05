--- @class rt.Shader
rt.Shader = meta.new_type("Shader", function(code_or_filename)
    return meta.new(rt.Shader, {
        _native = love.graphics.newShader(code_or_filename)
    })
end)

--- @brief set uniform
--- @param name String
--- @param value
function rt.Shader:send(name, value)

    local to_send = value
    if meta.is_vector2(value) then
        to_send = {value.x, value.y}
    elseif meta.is_vector3(value) then
        to_send = {value.x, value.y, value.z}
    end
    self._native:send(name, value)
end

--- @brief make shader the current on
function rt.Shader:bind()
    love.graphics.setShader(self._native)
end

--- @brief
function rt.Shader:unbindg()
    love.graphics.setShader(nil)
end

rt.settings.default_fragment_shader = [[
vec4 effect(vec4 vertex_color, Image texture, vec2 texture_coords, vec2 vertex_position)
{
    vec2 screen_size = love_ScreenSize.xy;
    return Texel(texture, texture_coords) * vertex_color;
}
]]

rt.settings.default_vertex_shader = [[
vec4 position(mat4 transform, vec4 vertex_position)
{
    return transform * vertex_position;
}
]]