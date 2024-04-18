require "include"

lt = {}
lt.VertexFormat = {
    {name = "VertexPosition", format = "floatvec2"},
    {name = "VertexColor", format = "floatvec3"}
}

lt.Automaton = {}
function lt.Automaton.new(x1, y1, x2, y2, age)

    local out = {}
    local metatable = {
        __index = lt.Automaton
    }
    setmetatable(out, metatable)

    local width = 5
    local mx = (x1 + x2) / 2
    local my = (y1 + y2) / 2

    local dx = x2 - x1
    local dy = y2 - y1
    local length = math.sqrt(dx * dx + dy * dy)
    local angle = math.atan2(dy, dx)

    local halfLength = length / 2
    local halfWidth = width / 2

    local vertices = {}
    for i = -1, 1, 2 do
        for j = -1, 1, 2 do
            local lx = i * halfLength * math.cos(angle) - j * halfWidth * math.sin(angle)
            local ly = i * halfLength * math.sin(angle) + j * halfWidth * math.cos(angle)
            table.insert(vertices, {
                mx + lx, -- vertex x
                my + ly, -- vertex y
                1, 1, 1 --age -- age
            })
        end
    end

    out._mesh = love.graphics.newMesh(
        lt.VertexFormat,
        vertices,
        "strip",
        "static"
    )
    out._positions = {x1, y1, x2, y2}
    out._angle = angle
    out._age = 0
    return out
end

setmetatable(lt.Automaton, {
    __call = function(self, x1, y1, x2, y2, age)
        if age == nil then age = 0 end
        return lt.Automaton.new(x1, y1, x2, y2, age)
    end
})

lt.Automaton._shader = love.graphics.newShader("main_lichen.glsl")
function lt.Automaton:draw()
    love.graphics.draw(self._mesh)
end

function lt.Automaton:get_position()
    return self._mesh:getVertexAttribute(1, 1)
end

function lt.Automaton:set_position(x, y)
    return self._mesh:setVertexAttribute(1, x, y)
end

function lt.Automaton:get_age()
    local age, _ = self._mesh:getVertexAttribute(2, 2)
    return age
end

function lt.Automaton:set_age(age)
    local _, angle = self._mesh:getVertexAttribute(2, 2)
    self._mesh:setVertexAttribute(2, age, angle)
end

function lt.Automaton:get_angle(point)
    local _, angle = self._mesh:getVertexAttribute(2, 2)
    return angle
end

function lt.Automaton:set_age(angle)
    local age, _ = self._mesh:getVertexAttribute(2, 2)
    self._mesh:setVertexAttribute(2, age, angle)
end

lt.active_points = {}
lt.spritebatch = {}
lt.step_speed = 100 -- px per second

local test = lt.Automaton.new(50, 20, 300, 500)
dbg(test:get_position())

function lt.add_point(x1, y1, x2, y2, age)
    local to_add = lt.Automaton(x1, y1, x2, y2, age)
    lt.active_points[to_add] = true
    return to_add
end

function lt.add_seed(x, y)
    local angle = love.math.random(0, 2 * math.pi)
    local x2, y2 = rt.translate_point_by_angle(x, y, lt.step_speed, angle)
    lt.add_point(x, y, x2, y2)
end

lt.angle_width = 0.5 * math.pi
function lt.step(delta)
    local gaussian = function(x) return math.exp(-1 * 4 * x^2) end
    local step_distance = delta / 60 * lt.step_speed

    local points = {}
    for point, _ in pairs(lt.active_points) do
        table.insert(points, point)
    end

    for _, point in pairs(points) do
        local x1, y1 = point._positions[3], point._positions[4]
        local angle = point._angle + love.math.random(-0.5 * lt.angle_width, 0.5 * lt.angle_width)
        angle = angle * gaussian(love.math.random(-1, 1))
        local age = point._age + delta
        local x2, y2 = rt.translate_point_by_angle(x1, y1, step_distance, angle)
        lt.add_point(x1, y1, x2, y2)
        table.insert(lt.spritebatch, point)
        lt.active_points[point] = nil
    end
end

-- ################

love.load = function()
    local w, h = love.graphics.getWidth(), love.graphics.getHeight()
    local min_x, min_y, max_x, max_y = 0.1 * w, 0.1 * h, 0.9 * w, 0.9 * h
    lt.add_seed(w / 2, h / 2) --love.math.random(min_x, max_x), love.math.random(max_x, max_y))
    lt.canvas = love.graphics.newCanvas(love.graphics.getWidth(), love.graphics.getWidth(), {
        msaa = true
    })
end

love.keypressed = function(which)
    lt.step(10)
end

love.mousepressed = function(x, y, _, _)
    lt.add_seed(x, y)
end

love.draw = function()
    --love.graphics.setShader(lt.Automaton._shader)
    for _, point in pairs(lt.spritebatch) do
        point:draw()
    end
end

love.update = function()

end