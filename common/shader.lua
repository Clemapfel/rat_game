--- @class rt.Shader
rt.Shader = meta.new_type("Shader", function(filename, ...)
    local success, shader = pcall(love.graphics.newShader, filename, ...)
    if not success then
        rt.error("In rt.Shader: Error when evaluating shader at `" .. filename .. "`:\n" .. shader)
    end

    return meta.new(rt.Shader, {
        _native = shader,
        _filename = filename,
        _before = nil,
    })
end)

--- @brief set uniform
--- @param name String
--- @param value
function rt.Shader:send(name, value)
    if self._native:hasUniform(name) then
        self._native:send(name, value)
    end
end

--- @brief
function rt.Shader:get_buffer_format(name)
    return self._native:getBufferFormat(name)
end

--- @brief
function rt.Shader:has_uniform(name)
    return self._native:hasUniform(name)
end

--- @brief make shader the current on
function rt.Shader:bind()
    self._before = love.graphics.getShader()
    love.graphics.setShader(self._native)
end

--- @brief
function rt.Shader:unbind()
    love.graphics.setShader(self._before)
end

--- @brief
function rt.Shader:recompile()
    self._native = love.graphics.newShader(self._filename)
end