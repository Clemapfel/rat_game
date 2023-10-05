
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
rt.Texture = meta.new_type("Texture", function(path_or_image)
    local out
    if meta.is_string(path_or_image) then
        out =  meta.new(rt.Texture, {
            _native = love.graphics.newImage(path_or_image)
        })
    else
        meta.assert_isa(path_or_image, rt.Image)
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(path_or_image._native)
        })
    end
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

--- @brief test texture
function rt.test.texture()
    -- TODO
end
rt.test.texture()