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
function rt.graphics.clear(r, g, b, a)
    love.graphics.clear(r, g, b, a, true, true)
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
    if blend_mode == rt.BlendMode.NONE then
        love.graphics.setBlendMode("replace", "premultiplied")
    elseif blend_mode == rt.BlendMode.NORMAL then
        love.graphics.setBlendMode("alpha", "premultiplied")
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
        love.graphics.setStencilState("replace", "always", new_value)
        for to_draw in range(...) do
            to_draw:draw()
        end
        love.graphics.setStencilState("keep", "always")
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
    GREATER_THAN_OR_EQUAL = "gequal"
})

--- @brief
function rt.graphics.set_stencil_test(mode, value)
    if love.getVersion() >= 12 then
        love.graphics.setStencilState("keep", which(mode, "always"), value, 0, 0)
    else
        love.graphics.setStencilTest(mode, value)
    end
end

