--- @class rt.Image
--- @param width_or_filename Number (or string)
--- @param height Number (or nil)
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

--- @brief load from file
--- @param file String
function rt.Image:create_from_file(file)
    meta.assert_isa(self, rt.Image)
    meta.assert_string(file)
    self._native = love.image.newImageData(file)
end

--- @brief create as given size
--- @param width Number
--- @param height Number
function rt.Image:create(width, height)
    meta.assert_isa(self, rt.Image)
    meta.assert_number(width, height)
    self._native = love.image.newImageData(width, height, rt.Image.FORMAT)
end

--- @brief save to file
--- @param file String
function rt.Image:save_to_file(file)
    meta.assert_isa(self, rt.Image)
    meta.assert_string(file)
    return self._native:encode("png", file)
end

--- @brief set pixel
--- @param x Number 1-based
--- @param y Number 1-based
--- @param rgba rt.RGBA
function rt.Image:set_pixel(x, y, rgba)
    meta.assert_number(x, y)
    meta.assert_isa(self, rt.Image)
    meta.assert_rgba(rgba)

    if x < 1 or x > self:get_width() or y < 1 or y > self:get_width() then
        error("[rt][ERROR] In Image:set_pixel: index (" .. tostring(x) .. ", " .. tostring(y) .. ") is out of range for image of size `" .. tostring(self:get_width()) .. " x " .. tostring(self:get_height()) .. "`")
    end
    self._native:setPixel(x - 1, y - 1, rgba.r, rgba.g, rgba.b, rgba.a)
end

--- @brief get pixel
--- @param x Number 1-based
--- @param y Number 1-based
--- @return rt.RGBA
function rt.Image:get_pixel(x, y)
    meta.assert_number(x, y)
    meta.assert_isa(self, rt.Image)

    if x < 1 or x > self:get_width() or y < 1 or y > self:get_width() then
        error("[rt][ERROR] In Image:get_pixel: index (" .. tostring(x) .. ", " .. tostring(y) .. ") is out of range for image of size `" .. tostring(self:get_width()) .. " x " .. tostring(self:get_height()) .. "`")
    end
    local r, g, b, a = self._native:getPixel(x - 1, y - 1)
    return rt.RGBA(r, g, b, a)
end

--- @brief get image resolution
--- @return (Number, Number)
function rt.Image:get_size()
    meta.assert_isa(self, rt.Image)
    return self._native:getDimensions()
end

--- @brief get horizontal resolution
--- @return Number
function rt.Image:get_width()
    meta.assert_isa(self, rt.Image)
    local w, h = self:get_size()
    return w
end

--- @brief get vertical resolution
--- @return Number
function rt.Image:get_height()
    meta.assert_isa(self, rt.Image)
    local w, h = self:get_size()
    return h
end

--- @brief test Image
function rt.test.image()
    error("TODO")
end
