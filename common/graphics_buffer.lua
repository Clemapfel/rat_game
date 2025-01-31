--- @class rt.GraphicsBufferUsage
rt.GraphicsBufferUsage = meta.new_enum("GraphicsBufferUsage", {
    DYNAMIC = "dynamic",
    STATIC = "static",
    STREAM = "stream"
})

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

--- @class rt.AsyncReadback
rt.AsyncReadback = meta.new_type("AsyncReadback", function(native)
    return meta.new(rt.AsyncReadback, {
        _native = native
    })
end)

--- @brief
function rt.GraphicsBuffer:replace_data(data)
    self._native:setArrayData(data)
end

--- @brief
function rt.GraphicsBuffer:readback_data()
    return love.graphics.readbackBuffer(self._native)
end

--- @brief
function rt.GraphicsBuffer:readback_data_async()
    return rt.AsyncReadback(love.graphics.readbackBufferAsync(self._native))
end

--- @brief
function rt.AsyncReadback:is_ready()
    return self._native:isComplete()
end

--- @brief
function rt.AsyncReadback:get()
    if self._native:isComplete() == true then
        return self._native:getBufferData()
    else
        return nil
    end
end

--- @brief
function rt.AsyncReadback:wait()
    self._native:wait()
    return self._native:getBufferData()
end