require "include"

Stall = meta.new_type("Stall", rt.Widget, {})

frame_start = love.timer.getTime()

function try_yield()
    if frame_start > 1 / 60 then
        coroutine.yield()
    end
end

function stall_frame(n)
    love.timer.sleep(n / 60)
end

function Stall:realize()
    local n = POSITIVE_INFINITY
    for i = 1, n do
        --stall_frame(0.01)
        println("realize: ", i .. " / " .. n)
        dbg(rt.graphics.get_frame_duration() / (1 / 60) * 100 .. "%")
        try_yield()
    end
end

function Stall:size_allocate(x, y, width, height)
    local n = 10
    for i = 1, n do
        stall_frame(0.5)
        println("realize: ", i .. " / " .. n)
    end
end

function Stall:realize_async()
    if self._realize_async_active ~= true then
        self._realize_async_active = true
        self._realize_async_coroutine = coroutine.create(function()
            self:realize()
        end)
    end
    coroutine.resume(self._realize_async_coroutine)
end

local stall = Stall()

state = rt.GameState()
state:initialize_debug_state()

inventory_scene = mn.InventoryScene(state)
inventory_scene:realize()

option_scene = mn.OptionsScene(state)
option_scene:realize()

local which_scene = true

state:set_current_scene(option_scene)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)

end)

state:set_input_button_keyboard_key(rt.InputButton.UP, rt.KeyboardKey.A)

background = bt.Background.VORONOI_CRYSTALS()
background:realize()

love.load = function()
    background:realize()
    state:_load()

    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    --background:update(delta)
    state:_update(delta)
    --stall:realize_async()
end

love.draw = function()
    --background:draw()
    state:_draw()
end

love.resize = function(new_width, new_height)
    background:fit_into(0, 0, state:get_resolution())
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end
