require "include"

state = rt.GameState()
state:initialize_debug_state()
--scene = mn.InventoryScene(state)
scene = mn.OptionsScene(state)

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    dbg(which)
end)

input:signal_connect("keyboard_pressed_raw", function(_, raw, scancode)
    --dbg(raw, scancode)
end)

sdl2 = ffi.load("SDL2")
local cdef = [[
    int SDL_Init(uint32_t);
    void* SDL_CreateThread(int(*)(void), char*, void*);
    void SDL_WaitThread(void*, int*);
]]
ffi.cdef(cdef)

test = function()
    print("test")
    return 1
end

sdl2.SDL_Init(1)
local name = "Thread"
local cname = ffi.new("char[" .. #name .. "]")
ffi.copy(cname, name)
local thread = sdl2.SDL_CreateThread(test, cname, ffi.CNULL)

local status = ffi.new("int[1]")
sdl2.SDL_WaitThread(thread, status)


state:set_input_button_keyboard_key(rt.InputButton.UP, rt.KeyboardKey.A)

background = bt.Background.VORONOI_CRYSTALS()
background:realize()

love.load = function()
    if scene ~= nil then
        scene:realize()
        scene:create_from_state(state)
        love.resize()
    end
end

love.update = function(delta)
    if scene ~= nil then
        scene:update(delta)
    end

    if love.keyboard.isDown("space") then
        background:update(delta)
    end
end

love.draw = function()
    if scene ~= nil then
        scene:draw()
    end
    background:draw()
end

love.resize = function()
    local x, y, w, h = 0, 0, rt.graphics.get_width(), rt.graphics.get_height()
    if scene ~= nil then
        scene:fit_into(x, y, w, h)
    end

    background:fit_into(x, y, w, h)
end

love.run = function()
    state:run()
end
