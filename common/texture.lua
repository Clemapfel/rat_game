--- @class rt.TextureScaleMode
rt.TextureScaleMode = meta.new_enum("TextureScaleMode", {
    LINEAR = "linear",
    NEAREST = "nearest"
})

--- @class rt.TextureWrapMode
rt.TextureWrapMode = meta.new_enum("TextureWrapMode", {
    ZERO = "clampzero",
    ONE = "clampone",
    CLAMP = "clamp",
    REPEAT = "repeat",
    MIRROR = "mirroredrepeat"
})

--- @class rt.Texture
--- @param pathor_width String (or Number)
--- @param height Number (or nil)
rt.Texture = meta.new_type("Texture", rt.Drawable, function(path_or_image_or_width, height)
    local out
    if meta.is_string(path_or_image_or_width) then
        local path = path_or_image_or_width
        out =  meta.new(rt.Texture, {
            _native = love.graphics.newImage(path)
        })
    elseif meta.isa(path_or_image_or_width, rt.Image) then
        local image = path_or_image_or_width
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(image._native)
        })
    elseif meta.is_number(path_or_image_or_width) then
        local width = path_or_image_or_width
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(width, height)
        })
    elseif path_or_image_or_width == nil then
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage()
        })
    else -- love.ImageData
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(path_or_image_or_width)
        })
    end
    out:set_scale_mode(rt.TextureScaleMode.NEAREST)
    out:set_wrap_mode(rt.TextureWrapMode.CLAMP)
    return out
end)

--- @brief set scale mode
--- @param mode rt.TextureScaleMode
function rt.Texture:set_scale_mode(mode)
    self._native:setFilter(mode, mode)
end

--- @brief get scale mode
--- @return rt.TextureScaleMode
function rt.Texture:get_scale_mode()
    return self._native:getFilter()
end

--- @brief set wrap mode
--- @param mode rt.TextureWrapMode
function rt.Texture:set_wrap_mode(mode)
    self._native:setWrap(mode, mode)
end

--- @brief get wrap mode
--- @return rt.TextureWrapMode
function rt.Texture:get_wrap_mode()
    return self._native:getWrap()
end

--- @brief get resolution
--- @return (Number, Number)
function rt.Texture:get_size()
    return self._native:getWidth(), self._native:getHeight()
end

--- @brief get width
--- @return Number
function rt.Texture:get_width()
    return self._native:getWidth()
end

--- @brief get height
--- @return Number
function rt.Texture:get_height()
    return self._native:getHeight()
end

--- @overload rt.Drawable.draw
function rt.Texture:draw(x, y)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(self._native, x, y)
end

if love.getVersion() >= 12 then
    --- @overload
    function rt.Texture:download()
        return love.graphics.readbackTexture(self._native)
    end
end
