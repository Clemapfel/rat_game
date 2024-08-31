require "include"

state = rt.GameState()
state:initialize_debug_state()

inventory_scene = mn.InventoryScene(state)
option_scene = mn.OptionsScene(state)

which_scene = true

indicators = {}

local bindings = {
    rt.GamepadButton.TOP, rt.GamepadButton.RIGHT, rt.GamepadButton.BOTTOM, rt.GamepadButton.LEFT, "\n",
    rt.KeyboardKey.ARROW_UP, rt.KeyboardKey.W, rt.KeyboardKey.SPACE, rt.KeyboardKey.RETURN, "\n",
    rt.GamepadButton.DPAD_UP, rt.GamepadButton.DPAD_RIGHT, rt.GamepadButton.DPAD_DOWN, rt.GamepadButton.DPAD_LEFT, "\n",
    rt.GamepadButton.START, rt.GamepadButton.SELECT, rt.GamepadButton.LEFT_SHOULDER, rt.GamepadButton.RIGHT_SHOULDER, "\n",
    rt.GamepadButton.LEFT_STICK, rt.GamepadButton.RIGHT_STICK
}

local indicator_x, indicator_y = 50, 50
local indicator_w, indicator_h = 75, 75
local row_i, col_i = 0, 0
for which in values(bindings) do
    if which == "\n" then
        row_i = 0
        col_i = col_i + 1
    else
        local indicator = rt.KeybindingIndicator(which)
        indicator:realize()
        indicator:fit_into(math.round(indicator_x + row_i * indicator_w), math.round(indicator_y + col_i * indicator_h), indicator_w, indicator_h)

        row_i = row_i + 1
        table.insert(indicators, indicator)
    end
end

input = rt.InputController()
input:signal_connect("pressed", function(_, which)
    if which == rt.InputButton.L then
        which_scene = not which_scene
        if which_scene then
            state:set_current_scene(inventory_scene)
        else
            state:set_current_scene(option_scene)
        end
    end
end)

input:signal_connect("gamepad_pressed_raw", function(_, which, scancode)
    dbg(which)
end)

input:signal_connect("keyboard_pressed_raw", function(_, which, scancode)
    dbg(which, " ", scancode)
end)

love.load = function()
    state:_load()
    state:set_current_scene(inventory_scene)
    love.resize(love.graphics.getWidth(), love.graphics.getHeight())
end

love.update = function(delta)
    state:_update(delta)
end

love.draw = function()
    --state:_draw()
    for indicator in values(indicators) do
        indicator:draw()
    end
end

love.resize = function(new_width, new_height)
    state:_resize(new_width, new_height)
end

love.run = function()
    state:_run()
end