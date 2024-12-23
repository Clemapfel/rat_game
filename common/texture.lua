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

--- @class rt.TextureFormat
rt.TextureFormat = meta.new_enum("TextureFormat", {
    --                      | #  | Size | Range
    --                      |----|------|-----------------
    NORMAL = "normal",   --	| 4  | 32 	| [0, 1]
    R8 = "r8",           --	| 1  | 8 	| [0, 1]
    RG8 = "rg8",         -- | 2  | 16 	| [0, 1]
    RGBA8 = "rgba8",     -- | 4  | 32 	| [0, 1]
    SRGBA8 = "srgba8",   -- | 4  | 32 	| [0, 1]
    R16 = "r16",         -- | 1  | 16 	| [0, 1]
    RG16 = "rg16",       -- | 2  | 32 	| [0, 1]
    RGBA16 = "rgba16",   -- | 4  | 64 	| [0, 1]
    R16F = "r16f",       -- | 1  | 16 	| [-65504, +65504]
    RG16F = "rg16f",     -- | 2  | 32 	| [-65504, +65504]
    RGBA16F = "rgba16f", -- | 4  | 64 	| [-65504, +65504]
    R32F = "r32f",       -- | 1  | 32 	| [-3.4028235e38, 3.4028235e38]
    RG32F = "rg32f",     -- | 2  | 64 	| [-3.4028235e38, 3.4028235e38]
    RGBA32F = "rgba32f", -- | 4  | 128 	| [-3.4028235e38, 3.4028235e38]
    RGBA4 = "rgba4",     -- | 4  | 16 	| [0, 1]
    RGB5A1 = "rgb5a1",   -- | 4  | 16 	| [0, 1]
    RGB565 = "rgb565",   -- | 3  | 16 	| [0, 1]
    RGB10a2 = "rgb10a2", -- | 4  | 32 	| [0, 1]
    RG11b10 = "rg11b10", -- | 3  | 32 	| [0, 65024]
})

--- @class rt.Texture
--- @param pathor_width String (or Number)
--- @param height Number (or nil)
rt.Texture = meta.new_type("Texture", rt.Drawable, function(path_or_image_or_width, height, ...)
    local out
    if meta.is_string(path_or_image_or_width) then
        local path = path_or_image_or_width
        out =  meta.new(rt.Texture, {
            _native = love.graphics.newImage(path, ...)
        })
    elseif meta.isa(path_or_image_or_width, rt.Image) then
        local image = path_or_image_or_width
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(image._native, ...)
        })
    elseif meta.is_number(path_or_image_or_width) then
        local width = path_or_image_or_width
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(width, height, ...)
        })
    else -- love.ImageData
        out = meta.new(rt.Texture, {
            _native = love.graphics.newImage(path_or_image_or_width, ...)
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
function rt.Texture:draw(x, y, r, g, b, a)
    if r == nil then
        love.graphics.setColor(1, 1, 1, 1)
    else
        if r == nil then r = 1 end
        if g == nil then g = 1 end
        if b == nil then b = 1 end
        if a == nil then a = 1 end
        love.graphics.setColor(r, g, b, a)
    end

    love.graphics.draw(self._native, x, y)
end

if love.getVersion() >= 12 then
    --- @overload
    function rt.Texture:download()
        return love.graphics.readbackTexture(self._native)
    end
end
