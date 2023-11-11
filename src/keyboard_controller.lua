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
    MINUS = "-",
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
    ARROW_UP = "up",
    ARROW_DOWN = "down",
    ARROW_RIGHT = "right",
    ARROW_LEFT = "left",
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
meta.make_weak(rt.KeyboardHandler._components, false, true)

--- @class rt.KeyboardController
--- @brief create new controller
--- @param holder meta.Object
rt.KeyboardController = meta.new_type("KeyboardController", function(instance)
    meta.assert_object(instance)
    local hash = rt.KeyboardHandler._hash
    rt.KeyboardHandler._hash = rt.KeyboardHandler._hash + 1

    local out = meta.new(rt.KeyboardController, {
        instance = instance,
        _hash = hash
    }, rt.SignalEmitter)

    out:signal_add("key_pressed")
    out:signal_add("key_released")

    rt.KeyboardHandler._components[hash] = out
    return out
end)


--- @brief on key pressed
--- @param key String
function rt.KeyboardHandler.handle_key_pressed(key)
    for _, component in pairs(rt.KeyboardHandler._components) do
        if component.instance:get_has_focus() then
            component:signal_emit("key_pressed", key)
        end
    end
end
love.keypressed = function(key) rt.KeyboardHandler.handle_key_pressed(key) end

--- @brief on key released
--- @param key String
function rt.KeyboardHandler.handle_key_released(key)
    for _, component in pairs(rt.KeyboardHandler._components) do
        if component.instance:get_has_focus() then
            component:signal_emit("key_released", key)
        end
    end
end
love.keyreleased = function(key) rt.KeyboardHandler.handle_key_released(key) end

--- @brief add an keyboard component
--- @param target meta.Object
--- @return rt.KeyboardController
function rt.add_keyboard_controller(target)
    meta.assert_object(target)
    getmetatable(target).components.keyboard = rt.KeyboardController(target)
    return getmetatable(target).components.keyboard
end

--- @brief get keyboard component
--- @param target meta.Object
--- @return rt.KeyboardController
function rt.get_keyboard_controller(target)
    meta.assert_object(target)
    local components = getmetatable(target).components
    if meta.is_nil(components) then
        return nil
    end
    return components.keyboard
end
