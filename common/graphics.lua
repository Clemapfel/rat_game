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

--- @brief no args to reset whole buffer to 0
--- @vararg rt.Drawable
function rt.graphics.stencil(new_value, ...)
    local n_drawables = _G._select("#", ...)
    if love.getVersion() >= 12 then
        if n_drawables > 0 then
            love.graphics.setStencilState("replace", "always", which(new_value, 255))
            for to_draw in range(...) do
                to_draw:draw()
            end
            love.graphics.setStencilMode()
        else
            love.graphics.setStencilMode("draw", new_value)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            love.graphics.setStencilMode()
        end
    else
        if n_drawables > 0 then
            local drawables = {...}
            love.graphics.stencil(function()
                for _, to_draw in pairs(drawables) do
                    to_draw:draw()
                end
            end, "replace", new_value, true)
        else
            -- reset whole screen
            love.graphics.stencil(function() end, "replace", new_value, false)
        end
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
        if mode == nil then
            love.graphics.setStencilMode()
        else
            love.graphics.setStencilState("keep", which(mode, "always"), which(value, 0))
        end
    else
        love.graphics.setStencilTest(which(mode, "always"), which(value, 0))
    end
end

