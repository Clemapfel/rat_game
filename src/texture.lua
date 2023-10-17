
--- @class TextureScaleMode
rt.TextureScaleMode = meta.new_enum({
    LINEAR = "linear",
    NEAREST = "nearest"
})

--- @class TextureWrapMode
rt.TextureWrapMode = meta.new_enum({
    ZERO = "clampzero",
    ONE = "clampone",
    CLAMP = "clamp",
    REPEAT = "repeat",
    MIRROR = "mirroredrepeat"
})

--- @class Texture
rt.Texture = meta.new_type("Texture", function(path_or_image_or_width, height)
    local out
    if meta.is_string(path_or_image_or_width) then
        local path = path_or_image_or_width
        out =  meta.new(rt.Texture, {
            _native = love.graphics.newImage(path)
        })
    elseif meta.isa(path_or_image_or_width, rt.Image) then
        meta.assert_isa(path_or_image_or_width, rt.Image)
        local image = path_or_image_or_width
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(image._native)
        })
    elseif meta.is_number(path_or_image_or_width) then
        meta.assert_number(height)
        local width = path_or_image_or_width
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(width, height)
        })
    else
        meta.assert_nil(path_or_image_or_width)
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage()
        })
    end
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    return out
end)

--- @class RenderTexture
rt.RenderTexture = meta.new_type("RenderTexture", function(width, height)
    meta.assert_number(width, height)
    local out = meta.new(rt.RenderTexture, {
        _native = love.graphics.newCanvas(width, height)
    }, rt.Texture)
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    return out
end)

--- @brief
function rt.Texture:set_scale_mode(mode)
    meta.assert_isa(self, rt.Texture)
    meta.assert_enum(mode, rt.TextureScaleMode)
    self._native:setFilter(mode, mode)
end

--- @brief
function rt.Texture:get_scale_mode()
    meta.assert_isa(self, rt.Texture)
    return self._native:getFilter()
end

--- @brief
function rt.Texture:set_wrap_mode(mode)
    meta.assert_isa(self, rt.Texture)
    meta.assert_enum(mode, rt.TextureWrapMode)
    self._native:setWrap(mode, mode)
end

--- @brief
function rt.Texture:set_wrap_mode()
    meta.assert_isa(self, rt.Texture)
    self._native:getWrap()
end

--- @brief
--- @return (Number, Number)
function rt.Texture:get_size()
    meta.assert_isa(self, rt.Texture)
    return self._native:getDimension()
end

--- @brief
function rt.RenderTexture:bind_as_render_target()
    meta.assert_isa(self, rt.RenderTexture)
    love.graphics.setCanvas(self._native)
end

--- @brief
function rt.RenderTexture:unbind_as_render_target()
    meta.assert_isa(self, rt.RenderTexture)
    love.graphics.setCanvas()
end

--- @brief test texture
function rt.test.texture()
    -- TODO
end
rt.test.texture()