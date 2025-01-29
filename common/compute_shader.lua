rt.settings.compute_shader = {
    allow_unused_uniform = true
}
--- @class rt.ComputeShader
rt.ComputeShader = meta.new_type("ComputeShader", function(filename, defines)
    local success, shader = pcall(love.graphics.newComputeShader, filename, {
        defines = defines
    })
    if not success then
        rt.error("In rt.ComputeShader: Error when evaluating shader at `" .. filename .. "`:\n" .. shader)
    end

    return meta.new(rt.ComputeShader, {
        _native = shader,
        _filename = filename
    })
end)

--- @brief set uniform
--- @param name String
--- @param value
function rt.ComputeShader:send(name, value)
    assert(value ~= nil)
    if meta.isa(value, rt.GraphicsBuffer) or meta.isa(value, rt.Texture) then value = value._native end
    if self._native:hasUniform(name) then
        self._native:send(name, value)
    end
end

--- @brief
function rt.ComputeShader:has_uniform(name)
    return self._native:hasUniform(name)
end

--- @brief
function rt.ComputeShader:get_buffer_format(buffer)
    return self._native:getBufferFormat(buffer)
end

--- @brief
function rt.ComputeShader:dispatch(x, y)
    love.graphics.dispatchThreadgroups(self._native, x, y)
end