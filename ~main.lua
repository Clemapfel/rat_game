require "include"

local x, y, w, h = 0, 0, love.graphics.getWidth(), love.graphics.getHeight()
shape = love.graphics.newMesh({
    {"VertexPosition", "float", 3},
    {"VertexTexCoord","float", 2},
    {"VertexColor", "float", 4},
}, {
    {x    , y    , 0,    0, 0,   1, 1, 1, 1},
    {x + w, y    , 0,    0, 0,   1, 1, 1, 1},
    {x + w, y + h, 0,    0, 0,   1, 1, 1, 1},
    {x    , y + h, 0,    0, 0,   1, 1, 1, 1},
})


shader = love.graphics.newShader("main_shader.glsl")

function love.draw()
    love.graphics.setShader(shader)
    love.graphics.draw(shape)
    love.graphics.setShader()
end

z_offset = 0
function love.keypressed(which)
    if which == "up" then
        z_offset = z_offset + 10
        for i = 1, 4 do
            local x, y, z =  shape:getVertexAttribute(i, 1)
            shape:setVertexAttribute(i, 1, x, y, z - 10)
        end
    end

    if which == "down" then
        z_offset = z_offset - 10
        for i = 1, 4 do
            local x, y, z =  shape:getVertexAttribute(i, 1)
            shape:setVertexAttribute(i, 1, x, y, z + 10)
        end
    end
end