
--- @class rt.RenderTexture
--- @param width Number
--- @param height Number
rt.RenderTexture = meta.new_type("RenderTexture", function(width, height, msaa)
    msaa = which(msaa, 0)
    local out = meta.new(rt.RenderTexture, {
        _native = love.graphics.newCanvas(width, height, {msaa = msaa}),
        _before = {}, -- love.Canvas
    }, rt.Texture)
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    return out
end)

--- @brief bind texture as render target, needs to be unbound manually later
function rt.RenderTexture:bind_as_render_target()
    self._before = love.graphics.getCanvas()
    love.graphics.setCanvas(self._native)
end

--- @brief unbind texture
function rt.RenderTexture:unbind_as_render_target()
    love.graphics.setCanvas(self._before)
end