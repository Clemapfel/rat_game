COUNT = 0

-- @class rt.RenderTexture
--- @param width Number
--- @param height Number
rt.RenderTexture = meta.new_type("RenderTexture", rt.Texture, function(width, height, msaa, format, is_compute)
    msaa = which(msaa, 0)
    local out = meta.new(rt.RenderTexture, {
        _native = love.graphics.newCanvas(which(width, 1), which(height, 1), {
            msaa = which(msaa, false),
            format = format,
            computewrite = which(is_compute, false)
        }),
        _width = width,
        _height = height,
    })
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)


    local test = love.graphics.newCanvas(nil, nil, {
        msaa = which(msaa, false),
        format = format,
        computewrite = which(is_compute, false)
    })
    return out
end)

--- @brief bind texture as render target, needs to be unbound manually later
function rt.RenderTexture:bind()
    love.graphics.setCanvas({self._native, stencil = true})
end

--- @brief unbind texture
function rt.RenderTexture:unbind()
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
    self._native:release()
end
