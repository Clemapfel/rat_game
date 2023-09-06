--- @brief singleton, handles keyboard key events
rt.KeyboardHandler = {}

--- @brief list of valid keyboard key identifiers
--- @see https://love2d.org/wiki/KeyConstant
rt.KeyboardKey = meta.new_enum((function()
    local out = {}
    for i, key in ipairs({"a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9", "space", "!", "\"", "#", "$", "&", "'", "(", ")", "*", "+", ",", "-", ".", "/", ":", ";", "<", "=", ">", "?", "@", "[", "\"", "]", "^", "_", "`", "kp0", "kp1", "kp2", "kp3", "kp4", "kp5", "kp6", "kp7", "kp8", "kp9", "kp.", "kp,", "kp/", "kp*", "kp-", "kp+", "kpenter", "kp=", "up", "down", "right", "left", "home", "end", "pageup", "pagedown", "insert", "backspace", "tab", "clear", "return", "delete", "f1", "f2", "f3", "f4", "f5", "f6", "f7", "f8", "f9", "f10", "f11", "f12", "f13", "f14", "f15", "f16", "f17", "f18", "numlock", "capslock", "scrolllock", "rshift", "lshift", "rctrl", "lctrl", "ralt", "lalt", "rgui", "lgui", "mode", "www", "mail", "calculator", "computer", "appsearch", "apphome", "appback", "appforward", "apprefresh", "appbookmarks", "pause", "escape", "help", "printscreen", "sysreq", "menu", "application", "power", "currencyunit", "undo" }) do
        out[key] = i
    end
    return out
end)())

--- @brief keyboard keys
rt.KeyboardKey = meta.new_enum({
    KEY_UNKNOWN = "unknown",
    KEY_A = "a",
    KEY_B = "b",
    KEY_C = "c",
    KEY_D = "d",
    KEY_E = "e",
    KEY_F = "f",
    KEY_G = "g",
    KEY_H = "h",
    KEY_I = "i",
    KEY_J = "j",
    KEY_K = "k",
    KEY_L = "l",
    KEY_M = "m",
    KEY_N = "n",
    KEY_O = "o",
    KEY_P = "p",
    KEY_Q = "q",
    KEY_R = "r",
    KEY_S = "s",
    KEY_T = "t",
    KEY_U = "u",
    KEY_V = "v",
    KEY_W = "w",
    KEY_X = "x",
    KEY_Y = "y",
    KEY_Z = "z",
    KEY_0 = "0",
    KEY_1 = "1",
    KEY_2 = "2",
    KEY_3 = "3",
    KEY_4 = "4",
    KEY_5 = "5",
    KEY_6 = "6",
    KEY_7 = "7",
    KEY_8 = "8",
    KEY_9 = "9",
    KEY_SPACE = "space",
    KEY_EXCLAMATION_MARK = "!",
    KEY_DOUBLE_QUOTE = "\"",
    KEY_HASHTAG = "#",
    KEY_DOLLAR_SIGN= "$",
    KEY_SINGLE_QUOTE = "'",
    KEY_LEFT_BRACKET = "(",
    KEY_RIGHT_BRACKET = ")",
    KEY_ASTERISK = "*",
    KEY_PLUS = "+",
    KEY_COMMA = ",",
    KEY_HYPHEN = "-",
    KEY_DOT = ".",
    KEY_SLASH = "/",
    KEY_COLON = ":",
    KEY_SEMICOLON = ";",
    KEY_LESS_THAN = "<",
    KEY_EQUAL = "=",
    KEY_MORE_THAN = ">",
    KEY_QUESTION_MARK = "?",
    KEY_AT = "@",
    KEY_LEFT_SQUARE_BRACKET = "[",
    KEY_RIGHT_SQUARE_BRACKET = "]",
    KEY_CIRCUMFLEX = "^",
    KEY_UNDERSCORE = "_",
    KEY_GRAVE_ACCENT = "`",
    KEY_UP_ARROW = "up",
    KEY_DOWN_ARROW = "down",
    KEY_RIGHT_ARROW = "right",
    KEY_LEFT_ARROW = "left",
    KEY_HOME = "home",
    KEY_END = "end",
    KEY_PAGE_UP = "pageup",
    KEY_PAGE_DOWN = "pagedown",
    KEY_INSERT = "insert",
    KEY_BACKSPACE = "backspace",
    KEY_TAB = "tab",
    KEY_CLEAR = "clear",
    KEY_RETURN = "return",
    KEY_DELETE = "delete",
    KEY_F1 = "f1",
    KEY_F2 = "f2",
    KEY_F3 = "f3",
    KEY_F4 = "f4",
    KEY_F5 = "f5",
    KEY_F6 = "f6",
    KEY_F7 = "f7",
    KEY_F8 = "f8",
    KEY_F9 = "f9",
    KEY_F10 = "f10",
    KEY_F11 = "f11",
    KEY_F12 = "f12",
    KEY_NUM_LOCK = "numlock",
    KEY_CAPS_LOCK = "capslock",
    KEY_RIGHT_SHIFT = "rshift",
    KEY_LEFT_SHIFT = "lshift",
    KEY_LEFT_CONTROL = "rcrtl",
    KEY_RIGHT_CONTROL = "lcrtl",
    KEY_RIGHT_ALT = "ralt",
    KEY_LEFT_ALT = "lalt",
    KEY_PAUSE = "pause",
    KEY_ESCAPE = "escape",
    KEY_HELP = "help",
    KEY_PRINT_SCREEN = "printscreen",
    KEY_SYSTEM_REQUEST = "sysreq",
    KEY_MENU = "menu",
    KEY_APPLICATION = "application",
    KEY_POWER = "power",
    KEY_EURO = "currencyunit",
    KEY_UNDO = "undo",
    KEY_SEARCH = "appsearch",
    KEY_HOME = "apphome",
    KEY_BACK = "appback",
    KEY_FORWARD = "appforward",
    KEY_REFRESH = "apprefresh",
    KEY_BOOKMARKS = "appbookmarks",
    KEY_NUMPAD_0 = "kp0",
    KEY_NUMPAD_1 = "kp1",
    KEY_NUMPAD_2 = "kp2",
    KEY_NUMPAD_3 = "kp3",
    KEY_NUMPAD_4 = "kp4",
    KEY_NUMPAD_5 = "kp5",
    KEY_NUMPAD_6 = "kp6",
    KEY_NUMPAD_7 = "kp7",
    KEY_NUMPAD_8 = "kp8",
    KEY_NUMPAD_DOT = "kp.",
    KEY_NUMPAD_COMMA = "kp,",
    KEY_NUMPAD_SLASH = "kp/",
    KEY_NUMPAD_ASTERISK = "kp*",
    KEY_NUMPAD_MINUS = "kp-",
    KEY_NUMPAD_PLUS = "kp+",
    KEY_NUMPAD_ENTER = "kpenter",
    KEY_NUMPAD_EQUALS = "kp=",
})

rt.KeyboardHandler._hash = 1
rt.KeyboardHandler._components = {}
rt.KeyboardHandler._components_meta = { __mode = "v" }
setmetatable(rt.KeyboardHandler._components, rt.KeyboardHandler._components_meta)


--- @class KeyboardComponent
--- @signal key_pressed (::KeyboardComponent, key::String) -> Boolean
--- @signal key_released (::KeyboardComponent, key::String) -> Boolean
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

--- @brief on key pressed
--- @param key String
function rt.KeyboardHandler.handle_key_pressed(key)
    for _, component in ipairs(rt.KeyboardHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            local res = component.signal:emit("key_released", key)
            if res == true then
                break
            end
        end
    end
end
love.keypressed = function(key) rt.KeyboardHandler.handle_key_pressed(key) end

--- @brief on key released
--- @param key String
function rt.KeyboardHandler.handle_key_released(key)
    for _, component in ipairs(rt.KeyboardHandler._components) do
        if getmetatable(component._instance).is_focused == true then
            local res = component.signal:emit("key_pressed", key)
            if res == true then
                break
            end
        end
    end
end
love.keyreleased = function(key) rt.KeyboardHandler.handle_key_released(key) end

--- @brief is key currently pressed
--- @param key String
--- @return Boolean
function rt.KeyboardHandler.is_down(this, key)
    meta.assert_string(key)
    return this._state_now[key]
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

    rt.KeyboardHandler.handle_key_pressed("space")
    rt.KeyboardHandler.handle_key_released("space")

    assert(pressed_called)
    assert(release_called)
end
rt.test.keyboard_component()
