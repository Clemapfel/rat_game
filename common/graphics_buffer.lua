do
    local _buffer_usage = {
        shaderstorage = true
    }

    --- @class rt.GraphicsBufferUsage
    rt.GraphicsBufferUsage = meta.new_enum("GraphicsBufferUsage", {
        DYNAMIC = "dynamic",
        STATIC = "static",
        STREAM = "stream"
    })

    --- @class rt.GraphicsBuffer
    rt.GraphicsBuffer = meta.new_type("GraphicsBuffer", function(format, n_elements, usage)
        if usage == nil then usage = "dynamic" end
        return meta.new(rt.GraphicsBuffer, {
            _native = love.graphics.newBuffer(format, n_elements, {
                shaderstorage = true,
                usage = usage
            })
        })
    end)

    --- @brief
    function rt.GraphicsBuffer:replace_data(data)
        self._native:setArrayData(data)
    end
end