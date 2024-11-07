rt._render_texture_dummy = love.graphics.newCanvas(1, 1)

COUNT = 0
DELETE_COUNT = 0

-- @class rt.RenderTexture
--- @param width Number
--- @param height Number
rt.RenderTexture = meta.new_type("RenderTexture", rt.Texture, function(width, height, msaa, format, is_compute)
    if width == nil and height == nil then
        return meta.new(rt.RenderTexture, {
            _native = rt._render_texture_dummy,
            _width = 1,
            _height = 1,
            _is_valid = false,
        })
    end

    msaa = which(msaa, 0)
    local out = meta.new(rt.RenderTexture, {
        _native = love.graphics.newCanvas(which(width, 1), which(height, 1), {
            msaa = which(msaa, false),
            format = format,
            computewrite = which(is_compute, false)
        }),
        _width = width,
        _height = height,
        _is_valid = true
    })
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    COUNT = COUNT + 1
    dbg(COUNT, DELETE_COUNT, COUNT - DELETE_COUNT, string.find(debug.traceback(1, 1, 2), "label") ~= nil)
    return out
end)

--- @brief bind texture as render target, needs to be unbound manually later
function rt.RenderTexture:bind()
    if not self._is_valid then return end
    love.graphics.setCanvas({self._native, stencil = true})
end

--- @brief unbind texture
function rt.RenderTexture:unbind()
    if not self._is_valid then return end
    love.graphics.setCanvas()
end

--- @brief
function rt.RenderTexture:as_image()
    if love.getVersion() >= 12 then
        return rt.Image(love.graphics.readbackTexture(self._native))
    else
        return rt.Image(self._native:newImageData())
    end
end

--- @brief
function rt.RenderTexture:free()
    if not self._is_valid then return end
    assert(self._native:release(), "RenderTexture was already released")
    DELETE_COUNT = DELETE_COUNT + 1
    dbg(COUNT, DELETE_COUNT, COUNT - DELETE_COUNT, string.find(debug.traceback(1, 1, 2), "label") ~= nil)
end
