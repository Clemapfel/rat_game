--- @class rt.GraphicsBufferUsage
rt.GraphicsBufferUsage = meta.new_enum("GraphicsBufferUsage", {
    DYNAMIC = "dynamic",
    STATIC = "static",
    STREAM = "stream"
})

do
    local _usage = {
        shaderstorage = true,
        usage = "dynamic"
    }

    --- @class rt.GraphicsBuffer
    rt.GraphicsBuffer = meta.new_type("GraphicsBuffer", function(format, n_elements)
        return meta.new(rt.GraphicsBuffer, {
            _native = love.graphics.newBuffer(format, n_elements, _usage)
        })
    end)
end

--- @brief
function rt.GraphicsBuffer:replace_data(data)
    self._native:setArrayData(data)
end