
--- @class rt.RenderTexture
--- @param width Number
--- @param height Number
rt.RenderTexture = meta.new_type("RenderTexture", rt.Texture, function(width, height, msaa, format)
    msaa = which(msaa, 0)
    local out = meta.new(rt.RenderTexture, {
        _native = love.graphics.newCanvas(width, height, {
            msaa = msaa,
            format = format
        }),
        _before = {}, -- love.Canvas
    })
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    return out
end)

--- @brief bind texture as render target, needs to be unbound manually later
function rt.RenderTexture:bind_as_render_target()
    self._before = love.graphics.getCanvas()
    love.graphics.setCanvas({self._native, stencil = true})
end

--- @brief unbind texture
function rt.RenderTexture:unbind_as_render_target()
    love.graphics.setCanvas({self._before, stencil = true})
end

--- @brief
function rt.RenderTexture:as_image()
    if love.getVersion() >= 12 then
        return rt.Image(love.graphics.readbackTexture(self._native))
    else
        return rt.Image(self._native:newImageData())
    end
end