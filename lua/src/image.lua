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
    return self._native:getDimensions()
end

--- @brief test Image
function rt.test.image()
    -- TODO
end
rt.test.image()