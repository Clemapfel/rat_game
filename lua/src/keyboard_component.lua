--- @class rt.KeyboardHandler
rt.KeyboardHandler = {}

--- @class rt.KeyboardKey
--- @see https://love2d.org/wiki/KeyConstant
rt.KeyboardKey = meta.new_enum({
    UNKNOWN = "unknown",
    A = "a",
    B = "b",
    C = "c",
    D = "d",
    E = "e",
    F = "f",
    G = "g",
    H = "h",
    I = "i",
    J = "j",
    K = "k",
    L = "l",
    M = "m",
    N = "n",
    O = "o",
    P = "p",
    Q = "q",
    R = "r",
    S = "s",
    T = "t",
    U = "u",
    V = "v",
    W = "w",
    X = "x",
    Y = "y",
    Z = "z",
    ZERO = "0",
    ONE = "1",
    TWO = "2",
    THREE = "3",
    FOUR = "4",
    FIVE = "5",
    SIX = "6",
    SEVEN = "7",
    EIGHT = "8",
    NINE = "9",
    SPACE = "space",
    EXCLAMATION_MARK = "!",
    DOUBLE_QUOTE = "\"",
    HASHTAG = "#",
    DOLLAR_SIGN= "$",
    SINGLE_QUOTE = "'",
    LEFT_BRACKET = "(",
    RIGHT_BRACKET = ")",
    ASTERISK = "*",
    PLUS = "+",
    COMMA = ",",
    HYPHEN = "-",
    DOT = ".",
    SLASH = "/",
    COLON = ":",
    SEMICOLON = ";",
    LESS_THAN = "<",
    EQUAL = "=",
    MORE_THAN = ">",
    QUESTION_MARK = "?",
    AT = "@",
    LEFT_SQUARE_BRACKET = "[",
    RIGHT_SQUARE_BRACKET = "]",
    CIRCUMFLEX = "^",
    UNDERSCORE = "_",
    GRAVE_ACCENT = "`",
    UP_ARROW = "up",
    DOWN_ARROW = "down",
    RIGHT_ARROW = "right",
    LEFT_ARROW = "left",
    HOME = "home",
    END = "end",
    PAGE_UP = "pageup",
    PAGE_DOWN = "pagedown",
    INSERT = "insert",
    BACKSPACE = "backspace",
    TAB = "tab",
    CLEAR = "clear",
    RETURN = "return",
    DELETE = "delete",
    F1 = "f1",
    F2 = "f2",
    F3 = "f3",
    F4 = "f4",
    F5 = "f5",
    F6 = "f6",
    F7 = "f7",
    F8 = "f8",
    F9 = "f9",
    F10 = "f10",
    F11 = "f11",
    F12 = "f12",
    NUM_LOCK = "numlock",
    CAPS_LOCK = "capslock",
    RIGHT_SHIFT = "rshift",
    LEFT_SHIFT = "lshift",
    LEFT_CONTROL = "rcrtl",
    RIGHT_CONTROL = "lcrtl",
    RIGHT_ALT = "ralt",
    LEFT_ALT = "lalt",
    PAUSE = "pause",
    ESCAPE = "escape",
    HELP = "help",
    PRINT_SCREEN = "printscreen",
    SYSTEM_REQUEST = "sysreq",
    MENU = "menu",
    APPLICATION = "application",
    POWER = "power",
    EURO = "currencyunit",
    UNDO = "undo",
    SEARCH = "appsearch",
    HOME = "apphome",
    BACK = "appback",
    FORWARD = "appforward",
    REFRESH = "apprefresh",
    BOOKMARKS = "appbookmarks",
    NUMPAD_0 = "kp0",
    NUMPAD_1 = "kp1",
    NUMPAD_2 = "kp2",
    NUMPAD_3 = "kp3",
    NUMPAD_4 = "kp4",
    NUMPAD_5 = "kp5",
    NUMPAD_6 = "kp6",
    NUMPAD_7 = "kp7",
    NUMPAD_8 = "kp8",
    NUMPAD_DOT = "kp.",
    NUMPAD_COMMA = "kp,",
    NUMPAD_SLASH = "kp/",
    NUMPAD_ASTERISK = "kp*",
    NUMPAD_MINUS = "kp-",
    NUMPAD_PLUS = "kp+",
    NUMPAD_ENTER = "kpenter",
    NUMPAD_EQUALS = "kp=",
})

rt.KeyboardHandler._hash = 1
rt.KeyboardHandler._components = {}

--- @brief
rt.KeyboardComponent = meta.new_type("KeyboardComponent", function(instance)
    local hash = rt.KeyboardHandler._hash
    rt.KeyboardHandler._hash = rt.MouseHandler._hash + 1

    if meta.is_nil(instance.get_bounds) then
        error("[rt] In KeyboardComponent: instance of type `" .. instance .. "` does not have a `get_bounds` function")
    end

    local out = meta.new(rt.KeyboardComponent, {
        instance = instance,
        _hash = hash
    })
    rt.add_signal_component(out)
    out.signal:add("key_pressed")
    out.signal:add("key_released")

    rt.KeyboardHandler._components[hash] = out
    return out
end)


--- @brief on key pressed
--- @param key String
function rt.KeyboardHandler.handle_key_pressed(key)
    for _, component in pairs(rt.KeyboardHandler._components) do
        if component.instance:get_has_focus() then
            component.signal:emit("key_pressed", key)
        end
    end
end
love.keypressed = function(key) rt.KeyboardHandler.handle_key_pressed(key) end

--- @brief on key released
--- @param key String
function rt.KeyboardHandler.handle_key_released(key)
    for _, component in pairs(rt.KeyboardHandler._components) do
        if component.instance:get_has_focus() then
            component.signal:emit("key_released", key)
        end
    end
end
love.keyreleased = function(key) rt.KeyboardHandler.handle_key_released(key) end


--- @brief add an keyboard component
function rt.add_keyboard_component(target)
    meta.assert_object(target)
    getmetatable(target).components.keyboard = rt.KeyboardComponent(target)
    return getmetatable(target).components.keyboard
end

--- @brief
function rt.get_keyboard_component(target)
    meta.assert_object(target)
    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.keyboard
end

--[[
--- @class rt.KeyboardComponent
--- @signal key_pressed (::KeyboardComponent, key::String) -> Boolean
--- @signal key_released (::KeyboardComponent, key::String) -> Boolean
rt.KeyboardComponent = meta.new_type("KeyboardComponent", function(holder)
    meta.assert_object(holder)
    local hash = rt.KeyboardHandler._hash
    local out = meta.new(rt.KeyboardComponent, {
        _hash = hash,
        instance = holder
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

    local metatable = getmetatable(holder)
    metatable.components.keyboard = out
    metatable.__gc = function(self)
        rt.KeyboardHandler._components[self._hash] = nil
    end

    return rt.KeyboardHandler._components[hash]
end)

--- @brief on key pressed
--- @param key String
function rt.KeyboardHandler.handle_key_pressed(key)
    for _, component in pairs(rt.KeyboardHandler._components) do
        if getmetatable(component.instance).is_focused == true then
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
    for _, component in pairs(rt.KeyboardHandler._components) do
        if getmetatable(component.instance).is_focused == true then
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

--- @brief add an keyboard component
function rt.add_keyboard_component(self)
    meta.assert_object(self)

    if not meta.is_nil(self.keyboard) then
        error("[rt] In add_keyboard_component: Object of type `" .. meta.typeof(self) .. "` already has a member called `keyboard`")
    end

    meta._install_property(self, "keyboard", rt.AllocationComponent(self))
    return rt.get_keyboard_component(self)
end

--- @brief get keyboard component assigned
--- @return rt.KeyboardComponent
function rt.get_keyboard_component(self)
    return self.keyboard
end

--- @brief [internal] test keyboard component
rt.test.keyboard_component = function()

    local instance = meta._new("Object")
    local component = rt.KeyboardComponent(instance)
    assert(component.instance == instance)
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
]]--