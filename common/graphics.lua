rt.graphics = {}

--- @brief
rt.graphics.translate = love.graphics.translate

--- @brief
rt.graphics.origin = love.graphics.origin

--- @brief
rt.graphics.rotate = love.graphics.rotate

--- @brief
rt.graphics.scale = love.graphics.scale

--- @brief
function rt.graphics.clear(r, g, b, a)
    love.graphics.clear(r, g, b, a, true, true)
end

--- @brief
rt.graphics.get_width = love.graphics.getWidth

--- @brief
rt.graphics.get_height = love.graphics.getHeight

--- @class rt.BlendMode
rt.BlendMode = meta.new_enum({
    NONE = -1,
    NORMAL = 0,
    ADD = 1,
    SUBTRACT = 2,
    MULTIPLY = 3,
    MIN = 4,
    MAX = 5
})

--- @class rt.BlendOperation
rt.BlendOperation = meta.new_enum({
    ADD = "add",
    SUBTRACT = "subtract",
    REVERSE_SUBTRACT = "reversesubtract",
    MIN = "min",
    MAX = "max"
})

--- @class rt.BlendFactor
rt.BlendFactor = meta.new_enum({
    ZERO = "zero",
    ONE = "one",
    SOURCE_COLOR = "srccolor",
    ONE_MINUS_SOURCE_COLOR = "oneminussrccolor",
    SOURCE_ALPHA = "srcalpha",
    ONE_MINUS_SOURCE_ALPHA = "oneminussrcalpha",
    DESTINATION_COLOR = "dstcolor",
    ONE_MINUS_DESTINATION_COLOR = "oneminusdstcolor",
    DESTINATION_ALPHA = "dstalpha",
    ONE_MINUS_DESTINATION_ALPHA = "oneminusdstalpha"
})

--- @brief set blend mode
function rt.graphics.set_blend_mode(blend_mode_rgb, blend_mode_alpha)
    if blend_mode_alpha == nil then blend_mode_alpha = blend_mode_rgb end
    if love.getVersion() >= 12 then
        local mode_to_equation = function(mode)
            local operation, source_factor, destination_factor
            if mode == rt.BlendMode.NONE then
                operation = rt.BlendOperation.ADD
                source_factor = rt.BlendFactor.ZERO
                destination_factor = rt.BlendFactor.ONE
            elseif mode == rt.BlendMode.NORMAL then
                operation = rt.BlendOperation.ADD
                source_factor = rt.BlendFactor.SOURCE_ALPHA
                destination_factor = rt.BlendFactor.ONE_MINUS_SOURCE_ALPHA
            elseif mode == rt.BlendMode.ADD then
                operation = rt.BlendOperation.ADD
                source_factor = rt.BlendFactor.ONE
                destination_factor = rt.BlendFactor.ONE
            elseif mode == rt.BlendMode.SUBTRACT then
                operation = rt.BlendOperation.REVERSE_SUBTRACT
                source_factor = rt.BlendFactor.ONE
                destination_factor = rt.BlendFactor.ONE
            elseif mode == rt.BlendMode.MULTIPLY then
                operation = rt.BlendOperation.ADD
                source_factor = rt.BlendFactor.ZERO
                destination_factor = rt.BlendFactor.ONE
            elseif mode == rt.BlendMode.MIN then
                operation = rt.BlendOperation.MIN
                source_factor = rt.BlendFactor.ONE
                destination_factor = rt.BlendFactor.ONE
            elseif mode == rt.BlendMode.MAX then
                operation = rt.BlendOperation.MAX
                source_factor = rt.BlendFactor.ONE
                destination_factor = rt.BlendFactor.ONE
            else
                rt.error("In rt.graphics.set_blend_mode: invalid blend mode `" .. tostring(mode) .. "`")
            end

            return operation, source_factor, destination_factor
        end
        
        local rgb_operation, rgb_source_factor, rgb_destination_factor = mode_to_equation(blend_mode_rgb)
        local alpha_operation, alpha_source_factor, alpha_destination_factor = mode_to_equation(blend_mode_alpha)
        love.graphics.setBlendState(rgb_operation, alpha_operation, rgb_source_factor, alpha_source_factor, rgb_destination_factor, alpha_destination_factor)
    else
        local blend_mode = blend_mode_rgb
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
        elseif blend_mode == rt.BlendMode.MIN then
            love.graphics.setBlendMode("darken", "premultiplied")
        elseif blend_mode == rt.BlendMode.MAX then
            love.graphics.setBlendMode("lighten", "premultiplied")
        else
            rt.error("In rt.graphics.set_blend_mode: invalid blend mode `" .. tostring(blend_mode) .. "`")
        end
    end
end

--- @brief
function rt.graphics.set_color(color)
    local r, g, b, a = color, g, b, a
    if meta.is_rgba(color) then
        r, g, b, a = color.r, color.g, color.b, color.a
    elseif meta.is_hsva(color) then
        color = rt.hsva_to_rgba(color)
        r, g, b, a = color.r, color.g, color.b, color.a
    end

    love.graphics.setColor(r, g, b, a)
end

if love.getVersion() >= 12 then
    --- @brief write a stencil value to an area on screen occupied by drawables
    --- @param new_value Number new stencil value
    --- @vararg rt.Drawable
    function rt.graphics.stencil(new_value, stencil)
        local mask_r, mask_g, mask_b, mask_a = love.graphics.getColorMask()
        love.graphics.setStencilState("replace", "always", new_value, 255)
        love.graphics.setColorMask(false, false, false, false)
        stencil:draw()
        love.graphics.setColorMask(mask_r, mask_g, mask_b, mask_a)
        love.graphics.setStencilState()
    end
else
    --- @brief write a stencil value to an area on screen occupied by drawables
    --- @param new_value Number new stencil value
    --- @vararg rt.Drawable
    function rt.graphics.stencil(new_value, stencil)
        love.graphics.stencil(function()
            stencil:draw()
        end, "replace", new_value, true)
    end
end

function rt.graphics.clear_stencil()
    love.graphics.clear(false, true, false)
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

    rt.graphics._current_stencil_test_mode = mode
    rt.graphics._current_stencil_test_value = value
end

--- @brief
function rt.graphics.get_stencil_test()
    return rt.graphics._current_stencil_test_mode, rt.graphics._current_stencil_test_value
end

--- @brief
function rt.graphics.push()
    love.graphics.push()
end

--- @brief
function rt.graphics.pop()
    love.graphics.pop()
end

--- @brief
function rt.graphics.reset()
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
    love.graphics.setPointSize(1)
    love.graphics.setLineJoin(rt.LineJoin.NONE)
    love.graphics.setStencilState()
    love.graphics.origin()
end