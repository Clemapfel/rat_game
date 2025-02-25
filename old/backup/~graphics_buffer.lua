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
        _native = love.graphics.newBuffer(format, n_elements, _usage),
        _format = format
    })
end)

--- @class rt.AsyncReadback
rt.AsyncReadback = meta.new_type("AsyncReadback", function(native, format)
    return meta.new(rt.AsyncReadback, {
        _native = native,
        _format = format,
        _formatting_initialized = false
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
    return rt.AsyncReadback(
        love.graphics.readbackBufferAsync(self._native),
        self._format
    )
end

--- @brief
function rt.AsyncReadback:get_is_ready()
    return self._native:isComplete()
end

--- @brief
function rt.AsyncReadback:get_native()
    if self._native:isComplete() ~= true then return nil end
    return self._native:getBufferData()
end

--- @brief
function rt.AsyncReadback:_initialize_formatting()
    local _byte = 8
    local i = 1

    local _data = self:getBufferData()
    local _i_to_offset = {}
    local offset = 0
    for element in values(self._format) do
        local which = element.format
        if which.array_length > 0 then
            assert(false, "In rt.AsyncReadback:_initialize_formatting: unhandled case: array")
        end

        if which == "uint32" then
            _i_to_offset[i] = offset
            offset = offset + 32 / _byte
            i = i + 1

        elseif which == "int32" then
            format[i] = 32 / _byte
            i = i + 1
        elseif which == "float" then
            format[i] = 32 / _byte
            i = i + 1
        elseif which == "floatvec2" then
            format[i] = 32 / _byte
            format[i] = 32 / _byte
            i = i + 1
        elseif which == "floatvec3" then
            format[i] = 32 / _byte
            format[i] = 32 / _byte
            format[i] = 32 / _byte
            i = i + 1
        elseif which == "floatvec4" then

        else
            assert(false, "In rt.AsyncReadback:_initialize_formatting: unhandled format: " .. which)
        end
    end
end

--- @brief
function rt.AsyncReadback:get()
    if self._formatting_initialized == false then self:_initialize_formatting() end
end

--- @brief
function rt.AsyncReadback:wait()
    self._native:wait()
    return self._native:getBufferData()
end

local temp = {
    [1] = {
        name = "is_valid",
        location = -1,
        arraylength = 0,
        offset = 0,
        size = 4,
        format = "uint32"
    },
    [2] = {
        name = "a_from",
        location = -1,
        arraylength = 0,
        offset = 8,
        size = 8,
        format = "floatvec2"
    },
    [3] = {
        name = "b_from",
        location = -1,
        arraylength = 0,
        offset = 16,
        size = 8,
        format = "floatvec2"
    },
    [4] = {
        name = "a_to",
        location = -1,
        arraylength = 0,
        offset = 24,
        size = 8,
        format = "floatvec2"
    },
    [5] = {
        name = "b_to",
        location = -1,
        arraylength = 0,
        offset = 32,
        size = 8,
        format = "floatvec2"
    },
    [6] = {
        name = "color",
        location = -1,
        arraylength = 0,
        offset = 48,
        size = 12,
        format = "floatvec3"
    }
}
local attributeComponentCount = {
    float = 1,
    floatvec2 = 2,
    floatvec3 = 3,
    floatvec4 = 4,
    floatmat2x2 = 4,
    floatmat2x3 = 6,
    floatmat2x4 = 8,
    floatmat3x2 = 6,
    floatmat3x3 = 9,
    floatmat3x4 = 12,
    floatmat4x2 = 8,
    floatmat4x3 = 12,
    floatmat4x4 = 16,
    int32 = 1,
    int32vec2 = 2,
    int32vec3 = 3,
    int32vec4 = 4,
    uint32 = 1,
    uint32vec2 = 2,
    uint32vec3 = 3,
    uint32vec4 = 4,
    unorm8vec2 = 2,
    unorm8vec4 = 4,
}

--- the ffi types for each buffer component type
local ffiTypes = {
    float       = "float",
    floatvec2   = "float",
    floatvec3   = "float",
    floatvec4   = "float",
    floatmat2x2 = "float",
    floatmat2x3 = "float",
    floatmat2x4 = "float",
    floatmat3x2 = "float",
    floatmat3x3 = "float",
    floatmat3x4 = "float",
    floatmat4x2 = "float",
    floatmat4x3 = "float",
    floatmat4x4 = "float",
    int32       = "int32_t",
    int32vec2   = "int32_t",
    int32vec3   = "int32_t",
    int32vec4   = "int32_t",
    uint32      = "uint32_t",
    uint32vec2  = "uint32_t",
    uint32vec3  = "uint32_t",
    uint32vec4  = "uint32_t"
}
