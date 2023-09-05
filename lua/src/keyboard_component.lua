--- @brief singleton, handles keyboard key events
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

rt.KeyboardHandler._hash = 1
rt.KeyboardHandler._components = {}
rt.KeyboardHandler._state_now = rt.KeyboardHandler._new_state()
rt.KeyboardHandler._state_previous = rt.KeyboardHandler._new_state()

--- @brief update state, called once per frame
function rt.KeyboardHandler.update()
    for key, now in pairs(rt.KeyboardHandler._state_now) do

        local current = now

        local next = not now -- for debug
        if love ~= nil then
            next = love.keyboard.isDown(key)
        end

        rt.KeyboardHandler._state_previous[key] = current
        rt.KeyboardHandler._state_now[key] = next

        if current == true and next == false then
            for _, component in ipairs(rt.KeyboardHandler._components) do
                if getmetatable(component._instance).is_focused == true then
                    local res = component.signal:emit("key_released", key)
                    if res == true then
                        break
                    end
                end
            end
        elseif current == false and next == true then
            for _, component in ipairs(rt.KeyboardHandler._components) do
                if getmetatable(component._instance).is_focused == true then
                    local res = component.signal:emit("key_pressed", key)
                    if res == true then
                        break
                    end
                end
            end
        end
    end
end

--- @brief was key up last frame and down this frame
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.was_pressed(this, key)
    meta.assert_string(key)
    return this._state_previous[key] == false and this._state_now[key] == true
end

--- @brief was key down last frame and up this frame
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.was_released(this, key)
    meta.assert_string(key)
    return this._state_previous[key] == true and this._state_now[key] == false
end

--- @brief is key currently pressed
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.is_down(this, key)
    meta.assert_string(key)
    return this._state_now[key]
end

--- @class KeyboardComponent
--- @signal key_pressed (::KeyboardComponent, key::String) -> Boolean
--- @signal key_pressed (::KeyboardComponent, key::String) -> Boolean
rt.KeyboardComponent = meta.new_type("KeyboardComponent", function(holder)
    meta.assert_object(holder)
    local hash = rt.KeyboardHandler._hash
    local out = meta.new(rt.KeyboardComponent, {
        _hash = hash,
        _instance = holder
    })
    rt.add_signal_component(out)
    out.signal:add("key_pressed")
    out.signal:add("key_released")
    rt.KeyboardHandler._components[hash] = out
    rt.KeyboardHandler._hash = hash + 1

    local metatable = getmetatable(holder)
    if not meta.is_boolean(metatable.is_focused) then
        metatable.is_focused = true
    end

    return rt.KeyboardHandler._components[hash]
end)

--- @brief add a keyboard component to object, signals `key_pressed` and `key_released` are emitted when the global keyboard state changes
--- @param object meta.Object
function rt.add_keyboard_component(object)
    meta.assert_object(object)
    if not meta.is_nil(object.keyboard) then
        error("[rt] In rt.add_keyboard_component: Overriding property `keyboard` of object `" .. meta.typeof(object) .. "`")
    end
    object.keyboard = rt.KeyboardComponent(object)
    return object
end

--- @brief [internal] test keyboard component
rt.test.keyboard_component = function()

    local instance = meta._new("Object")
    local component = rt.KeyboardComponent(instance)
    assert(component._instance == instance)
    assert(meta.is_boolean(getmetatable(instance).is_focused))

    local pressed_called = false
    component.signal:connect("key_pressed", function(self, key)
        pressed_called = true
        return false
    end)

    local release_called = false
    component.signal:connect("key_released", function(self, key)
        release_called = true
        return true
    end)

    rt.KeyboardHandler:update()

    if love == nil then
        assert(component.signal:emit("key_pressed", "space") == false)
        assert(component.signal:emit("key_released", "space") == true)
    end

    -- assert(pressed_called)
    -- assert(release_called)

    Test = nil
end
rt.test.keyboard_component()
