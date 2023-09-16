--- @class Image
rt.Image = meta.new_type("Image", function(width_or_filename, height)
    if meta.is_string(width_or_filename) then
        return meta.new(rt.Image, {
            _native = love.image.newImageData(width_or_filename)
        })
    else
        meta.assert_number(width_or_filename, height)
        return meta.new(rt.Image, {
            _native = love.image.newImageData(width_or_filename, height, rt.Image.FORMAT)
        })
    end
end)

rt.Image.FORMAT = "rgba16"

--- @brief
function rt.Image:create_from_file(file)
    meta.assert_isa(self, rt.Image)
    meta.assert_string(file)
    self._native = love.image.newImageData(file)
end

--- @brief
function rt.Image:create(width, height)
    meta.assert_isa(self, rt.Image)
    meta.assert_number(width, height)
    self._native = love.image.newImageData(width, height, rt.Image.FORMAT)
end

--- @brief
function rt.Image:set_pixel(x, y, rgba)
    meta.assert_isa(self, rt.Image)
    rt.assert_rgba(rgba)
    self._native:setPixel(x, y, rgba.r, rgba.g, rgba.b, rgba.a)
end

--- @brief
function rt.Image:get_pixel(x, y)
    meta.assert_isa(self, rt.Image)
    local r, g, b, a = self._native:getPixel(x, y)
    return rt.RGBA(r, g, b, a)
end

--- @brief
function rt.Image:get_size()
    meta.assert_isa(self, rt.Image)
    self._image:getDimensions()
end

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