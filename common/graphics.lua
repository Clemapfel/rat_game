rt.graphics = {}

--- @brief
function rt.graphics.translate(x, y)
    love.graphics.translate(x, y)
end

--- @brief
function rt.graphics.rotate(angle)
    love.graphics.rotate(angle)
end

--- @brief
function rt.graphics.scale(x, y)
    love.graphics.scale(x, y)
end

--- @brief
function rt.graphics.clear(r, g, b, a)
    love.graphics.clear(r, g, b, a, true, true)
end

--- @brief
function rt.graphics.get_width()
    return love.graphics.getWidth()
end

--- @brief
function rt.graphics.get_height()
    return love.graphics.getHeight()
end

rt.BlendMode = meta.new_enum({
    NONE = -1,
    NORMAL = 0,
    ADD = 1,
    SUBTRACT = 2,
    MULTIPLY = 3,
})

--- @brief
function rt.graphics.set_blend_mode(blend_mode)
    blend_mode = which(blend_mode, rt.BlendMode.NORMAL)
    if blend_mode == rt.BlendMode.NONE then
        love.graphics.setBlendMode("replace", "alphamultiply")
    elseif blend_mode == rt.BlendMode.NORMAL then
        love.graphics.setBlendMode("alpha", "alphamultiply")
    elseif blend_mode == rt.BlendMode.ADD then
        love.graphics.setBlendMode("add", "alphamultiply")
    elseif blend_mode == rt.BlendMode.SUBTRACT then
        love.graphics.setBlendMode("subtract", "alphamultiply")
    elseif blend_mode == rt.BlendMode.MULTIPLY then
        love.graphics.setBlendMode("multiply", "premultiplied")
    else
        rt.error("In rt.graphics.set_blend_mode: invalid blend mode `" .. tostring(blend_mode) .. "`")
    end
end

--- @brief write a stencil value to an area on screen occupied by drawables
--- @param new_value Number new stencil value
--- @vararg rt.Drawable
function rt.graphics.stencil(new_value, ...)
    local drawables = {...}
    if love.getVersion() >= 12 then
        local mask_r, mask_g, mask_b, mask_a = love.graphics.getColorMask()
        love.graphics.setStencilState("replace", "always", new_value, 255)
        love.graphics.setColorMask(false, false, false, false)
        for _, to_draw in pairs(drawables) do
            to_draw:draw()
        end
        love.graphics.setColorMask(mask_r, mask_g, mask_b, mask_a)
        love.graphics.setStencilState()
    else
        love.graphics.stencil(function()
            for _, to_draw in pairs(drawables) do
                to_draw:draw()
            end
        end, "replace", new_value, true)
    end
end

rt.StencilCompareMode = meta.new_enum({
    EQUAL = "equal",
    NOT_EQUAL = "notequal",
    LESS_THAN = "less",
    LESS_THAN_OR_EUAL = "lequal",
    GREATER_THAN = "greater",
    GREATER_THAN_OR_EQUAL = "gequal",
    ALWAYS = "always"
})

--- @brief
function rt.graphics.set_stencil_test(mode, value)
    if love.getVersion() >= 12 then
        love.graphics.setStencilState("keep", which(mode, "always"), which(value, 0))
    else
        love.graphics.setStencilTest(which(mode, "always"), which(value, 0))
    end
end

--- @brief
function rt.graphics.push()
    love.graphics.push()
end

--- @brief
function rt.graphics.pop()
    love.graphics.pop()
end