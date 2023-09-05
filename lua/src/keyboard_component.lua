rt.KeyboardHandler = {}

--- @brief list of valid keyboard key identifiers
--- @see https://love2d.org/wiki/KeyConstant

rt.KeyboardKey = meta.new_enum((function()
    local out = {}
    local i = 1
    for _, key in ipairs({"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "space", "!", "\"", "#", "$", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", ":", ";", "<", "=", ">", "?", "@", "[", "\"", "]", "^", "_", "`", "kp0", "kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9", "kp.", "kp,", "kp/", "kp*", "kp-", "kp+", "kpenter", "kp=", "up", "down", "right", "left", "home", "end", "pageup", "pagedown", "insert", "backspace", "tab", "clear", "return", "delete", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "numlock", "capslock", "scrolllock", "rshift", "lshift", "rctrl", "lctrl", "ralt", "lalt", "rgui", "lgui", "mode", "www", "mail", "calculator", "computer", "appsearch", "apphome", "appback", "appforward", "apprefresh", "appbookmarks", "pause", "escape", "help", "printscreen", "sysreq", "menu", "application", "power", "currencyunit", "undo" }) do
        out[key] = i
        i = i + 1
    end
    return out
end)())

--- @brief [internal] create a new state, maps keyboard keys to whether it is pressed
function rt.KeyboardHandler._new_state()
    local out = {}
    for key, value in pairs(rt.KeyboardKey) do
        out[key] = false
    end
    return out
end

rt.KeyboardHandler._state_now = rt.KeyboardHandler._new_state()
rt.KeyboardHandler._state_previous = rt.KeyboardHandler._new_state()

--- @brief update state, called once per frame
function rt.KeyboardHandler.update()
    for key, now in pairs(rt.KeyboardHandler._state_now) do

        local current = now
        local next = love.keyboard.isDown(key)

        rt.KeyboardHandler._state_previous[key] = current
        rt.KeyboardHandler._state_now[key] = next

        if current == true and next == false then
            println("Pressed: ", key)
        elseif current == false and next == true then
            println("Released: ", key)
        end
    end
end

--- @brief was key up last frame and down this frame
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.was_pressed(this, key)
    return this._state_previous[key] == false and this._state_now[key] == true
end

--- @brief was key down last frame and up this frame
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.was_released(this, key)
    return this._state_previous[key] == true and this._state_now[key] == false
end

--- @brief is key currently pressed
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.is_down(this, key)
    return this._state_now[key]
end


