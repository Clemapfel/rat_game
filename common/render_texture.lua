--- @class rt.RenderTexture
--- @param width Number
--- @param height Number
rt.RenderTexture = meta.new_type("RenderTexture", rt.Texture, function(width, height, msaa, format, is_compute)
    msaa = which(msaa, 0)

    local out = meta.new(rt.RenderTexture, {
        _native = love.graphics.newCanvas(width, height, {
            msaa = which(msaa, false),
            format = format,
            computewrite = which(is_compute, false)
        }),
        _width = width,
        _height = height,
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
    local hue = (meta.hash(self) % 255) / 255
    love.graphics.setColor(rt.color_unpack(rt.hsva_to_rgba(rt.HSVA(hue, 1, 1, 1))))
    love.graphics.rectangle("fill", 0, 0, rt.graphics.get_width(), rt.graphics.get_height())
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

--- @brief
function rt.RenderTexture:free()
    self._native:release()
end
