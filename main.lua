require("include")

rt.current_scene = rt.add_scene("debug")

local gsl = ffi.load(love.filesystem.getSource() .. "/submodules/gsl-latest/gsl-2.7.1/libs/libgsl.so")
local gsl_cdef = [[
typedef int gsl_wavelet_direction;
typedef void* gsl_wavelet_type;
typedef void* gsl_wavelet;
typedef void* gsl_wavelet_workspace;

const gsl_wavelet_type *gsl_wavelet_daubechies;
const gsl_wavelet_type *gsl_wavelet_daubechies_centered;
const gsl_wavelet_type *gsl_wavelet_haar;
const gsl_wavelet_type *gsl_wavelet_haar_centered;
const gsl_wavelet_type *gsl_wavelet_bspline;
const gsl_wavelet_type *gsl_wavelet_bspline_centered;

gsl_wavelet *gsl_wavelet_alloc (const gsl_wavelet_type * T, size_t k);
void gsl_wavelet_free (gsl_wavelet * w);
const char *gsl_wavelet_name (const gsl_wavelet * w);

gsl_wavelet_workspace *gsl_wavelet_workspace_alloc (size_t n);
void gsl_wavelet_workspace_free (gsl_wavelet_workspace * work);

int gsl_wavelet_transform (const gsl_wavelet * w, double *data, size_t stride, size_t n, gsl_wavelet_direction dir, gsl_wavelet_workspace * work);
int gsl_wavelet_transform_forward (const gsl_wavelet * w, double *data, size_t stride, size_t n, gsl_wavelet_workspace * work);
int gsl_wavelet_transform_inverse (const gsl_wavelet * w, double *data, size_t stride, size_t n, gsl_wavelet_workspace * work);
]]

ffi.cdef(gsl_cdef)
local n, nc = 256, 20
local wavelet = gsl.gsl_wavelet_alloc(gsl.gsl_wavelet_daubechies, 4)
local workspace = gsl.gsl_wavelet_workspace_alloc(n);






--[[

map = ow.Map("debug_map", "assets/maps/debug")
--debug_tileset = ow.Tileset("debug_tileset", "assets/maps/debug")
--carpet_tileset = ow.Tileset("carpet", "assets/maps/debug")
--println(serialize(meta.get_properties(debug_tileset)))

camera = ow.Camera()
player = ow.Player(map._world)
player:set_position(love.graphics.getWidth() / 2, love.graphics.getHeight() / 2)

local input = rt.add_input_controller(player)
local flip = true

local x, y = 100, 100
local w, h, offset = love.graphics.getWidth() - x, love.graphics.getHeight() - y, 0

camera:signal_connect("reached", function(self)
    local random_pos_x, random_pos_y =
    ternary(flip, rt.random.integer(x - offset, x + offset), rt.random.integer(x + w - offset, x + offset), rt.random.integer(y + h- offset, y + offset)),
    ternary(flip, rt.random.integer(x - offset, x + offset), rt.random.integer(x + w - offset, x + offset), rt.random.integer(y + h- offset, y + offset))
    flip = not flip
    self:move_to(random_pos_x, random_pos_y)
    println("called")
end)

rt.current_scene.input:signal_connect("pressed", function(_, which)

   local random_pos_x, random_pos_y =
    ternary(flip, rt.random.integer(x - offset, x + offset), rt.random.integer(x + w - offset, x + offset), rt.random.integer(y + h- offset, y + offset)),
    ternary(flip, rt.random.integer(x - offset, x + offset), rt.random.integer(x + w - offset, x + offset), rt.random.integer(y + h- offset, y + offset))
    flip = not flip

    if which == rt.InputButton.A then
        camera:center_on(random_pos_x, random_pos_y)
    elseif which == rt.InputButton.B then
        camera:center_on(player:get_position())
    elseif which == rt.InputButton.X then
        camera:move_to(random_pos_x, random_pos_y)
    elseif which == rt.InputButton.Y then
        camera:move_to(player:get_position())
    elseif which == rt.InputButton.R then
       camera:rotate(rt.degrees(5))
    elseif which == rt.InputButton.L then
        camera:rotate(rt.degrees(-5))
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.DOWN then
    end
end)

-- ##

-- ##

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()

    camera:bind()
    map:draw()
    player:draw()

    camera:unbind()
    camera:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    map._world:update(delta)

    if input:is_down(rt.InputButton.B) then
        camera:center_on(player:get_position())
    end
end


--[[

rt.current_scene = rt.add_scene("debug")
background = bt.BattleBackground("mint_wave")
rt.current_scene:set_child(background)

sprites = {}
for i = 1, 5 do
    local color = rt.random.choose({"RED", "GREEN", "BLUE", "PINK", "PURPLE"})
    local label = rt.Label("<o><color=" .. color .. ">" .. rt.random.string(5) .. "</color></o>")
    local spacer = rt.Spacer()
    spacer:set_color(rt.color_darken(rt.Palette[rt.random.choose({"RED", "GREEN", "BLUE", "PINK", "PURPLE"})], 0.4))
    local overlay = rt.OverlayLayout()
    overlay:push_overlay(spacer)
    overlay:push_overlay(label)
    table.insert(sprites, overlay)
end
local x, y, w, h = 50, 150, love.graphics.getWidth() / #sprites - 25, 100
local m = (love.graphics.getWidth() - #sprites * w) / (#sprites + 1)
x = x + m

local hue = 0.05
for _, sprite in pairs(sprites) do
    sprite:realize()
    sprite:fit_into(x, rt.random.number(y, y + 50), w, h)
    x = x + w + m
    hue = hue + (0.9 / #sprites)
end

state_queue = rt.StateQueue()
rt.current_scene.input:signal_connect("pressed", function(_, which)
    local values = {}
    for i = 1, #sprites do
        table.insert(values, rt.random.integer(9, 9999))
    end

    if which == rt.InputButton.A then
        state_queue:push_back(bt.Animation.PLACEHOLDER(sprites, table.rep("TEST", #sprites)))
    elseif which == rt.InputButton.B then
        state_queue:push_back(bt.Animation.HP_LOST(sprites, values))
    elseif which == rt.InputButton.X then
        state_queue:push_back(bt.Animation.ENEMY_APPEARED(sprites))
    elseif which == rt.InputButton.Y then
        state_queue:push_back(bt.Animation.ENEMY_DIED(sprites))
    elseif which == rt.InputButton.R then
        local directions = {}
        local stats = {}
        for i = 1, #sprites do
            table.insert(directions, rt.random.choose({rt.Direction.UP, rt.Direction.DOWN}))
            table.insert(stats, rt.random.choose({bt.Stat.ATTACK, bt.Stat.DEFENCE, bt.Stat.SPEED}))
        end
        state_queue:push_back(bt.Animation.STAT_CHANGED(sprites, directions, stats))
    elseif which == rt.InputButton.L then
    elseif which == rt.InputButton.UP then
    elseif which == rt.InputButton.RIGHT then
    elseif which == rt.InputButton.LEFT then
    elseif which == rt.InputButton.DOWN then
    end
end)


love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()

    for _, sprite in pairs(sprites) do
        sprite:draw()
    end
    state_queue:draw()
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    state_queue:update(delta)
end

--[[

scene = ow.OverworldScene()
world = scene._world
player = ow.Player(world)

player._collider:set_allow_sleeping(false)
player._sensor:set_allow_sleeping(false)

local geometry = {
    ow.InteractTrigger(world, 150, 150, 100, 100, function(self, player)
        self._shape:set_color(rt.HSVA(rt.random.number(0, 1), 1, 1, 1))
    end),

    ow.IntersectTrigger(world, 300, 150, 100, 100, function(self, player)
        self._shape:set_color(rt.HSVA(rt.random.number(0, 1), 1, 1, 1))
    end)
}

-- ######################

love.load = function()
    love.window.setMode(800, 600, {
        vsync = 1,
        msaa = 8,
        stencil = true,
        resizable = true
    })
    love.window.setTitle("rat_game")
    rt.current_scene:run()
end

love.draw = function()
    love.graphics.clear(1, 0, 1, 1)
    rt.current_scene:draw()

    player:draw()
    for _, geometry in pairs(geometry) do
        geometry:draw()
    end
end

love.update = function()
    local delta = love.timer.getDelta()
    rt.current_scene:update(delta)
    world:update(delta)
end
]]--