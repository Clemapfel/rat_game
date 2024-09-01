rt.KeyboardKeyPrefix = "KEY_"

-- @class rt.KeyboardKey
--- @see https://love2d.org/wiki/KeyConstant
rt.KeyboardKey = meta.new_enum({
    UNKNOWN = "unknown",
    A = rt.KeyboardKeyPrefix .. "a",
    B = rt.KeyboardKeyPrefix .. "b",
    C = rt.KeyboardKeyPrefix .. "c",
    D = rt.KeyboardKeyPrefix .. "d",
    E = rt.KeyboardKeyPrefix .. "e",
    F = rt.KeyboardKeyPrefix .. "f",
    G = rt.KeyboardKeyPrefix .. "g",
    H = rt.KeyboardKeyPrefix .. "h",
    I = rt.KeyboardKeyPrefix .. "i",
    J = rt.KeyboardKeyPrefix .. "j",
    K = rt.KeyboardKeyPrefix .. "k",
    L = rt.KeyboardKeyPrefix .. "l",
    M = rt.KeyboardKeyPrefix .. "m",
    N = rt.KeyboardKeyPrefix .. "n",
    O = rt.KeyboardKeyPrefix .. "o",
    P = rt.KeyboardKeyPrefix .. "p",
    Q = rt.KeyboardKeyPrefix .. "q",
    R = rt.KeyboardKeyPrefix .. "r",
    S = rt.KeyboardKeyPrefix .. "s",
    T = rt.KeyboardKeyPrefix .. "t",
    U = rt.KeyboardKeyPrefix .. "u",
    V = rt.KeyboardKeyPrefix .. "v",
    W = rt.KeyboardKeyPrefix .. "w",
    X = rt.KeyboardKeyPrefix .. "x",
    Y = rt.KeyboardKeyPrefix .. "y",
    Z = rt.KeyboardKeyPrefix .. "z",
    ZERO = rt.KeyboardKeyPrefix .. "0",
    ONE = rt.KeyboardKeyPrefix .. "1",
    TWO = rt.KeyboardKeyPrefix .. "2",
    THREE = rt.KeyboardKeyPrefix .. "3",
    FOUR = rt.KeyboardKeyPrefix .. "4",
    FIVE = rt.KeyboardKeyPrefix .. "5",
    SIX = rt.KeyboardKeyPrefix .. "6",
    SEVEN = rt.KeyboardKeyPrefix .. "7",
    EIGHT = rt.KeyboardKeyPrefix .. "8",
    NINE = rt.KeyboardKeyPrefix .. "9",
    SPACE = rt.KeyboardKeyPrefix .. "space",
    EXCLAMATION_MARK = rt.KeyboardKeyPrefix .. "!",
    DOUBLE_QUOTE = rt.KeyboardKeyPrefix .. "\"",
    HASHTAG = rt.KeyboardKeyPrefix .. "#",
    DOLLAR_SIGN= rt.KeyboardKeyPrefix .. "$",
    SINGLE_QUOTE = rt.KeyboardKeyPrefix .. "'",
    LEFT_BRACKET = rt.KeyboardKeyPrefix .. "(",
    RIGHT_BRACKET = rt.KeyboardKeyPrefix .. ")",
    ASTERISK = rt.KeyboardKeyPrefix .. "*",
    PLUS = rt.KeyboardKeyPrefix .. "+",
    COMMA = rt.KeyboardKeyPrefix .. ",",
    MINUS = rt.KeyboardKeyPrefix .. "-",
    DOT = rt.KeyboardKeyPrefix .. ".",
    SLASH = rt.KeyboardKeyPrefix .. "/",
    COLON = rt.KeyboardKeyPrefix .. ":",
    SEMICOLON = rt.KeyboardKeyPrefix .. ";",
    LESS_THAN = rt.KeyboardKeyPrefix .. "<",
    EQUAL = rt.KeyboardKeyPrefix .. "=",
    MORE_THAN = rt.KeyboardKeyPrefix .. ">",
    QUESTION_MARK = rt.KeyboardKeyPrefix .. "?",
    AT = rt.KeyboardKeyPrefix .. "@",
    LEFT_SQUARE_BRACKET = rt.KeyboardKeyPrefix .. "[",
    RIGHT_SQUARE_BRACKET = rt.KeyboardKeyPrefix .. "]",
    CIRCUMFLEX = rt.KeyboardKeyPrefix .. "^",
    UNDERSCORE = rt.KeyboardKeyPrefix .. "_",
    GRAVE_ACCENT = rt.KeyboardKeyPrefix .. "`",
    ARROW_UP = rt.KeyboardKeyPrefix .. "up",
    ARROW_DOWN = rt.KeyboardKeyPrefix .. "down",
    ARROW_RIGHT = rt.KeyboardKeyPrefix .. "right",
    ARROW_LEFT = rt.KeyboardKeyPrefix .. "left",
    HOME = rt.KeyboardKeyPrefix .. "home",
    END = rt.KeyboardKeyPrefix .. "end",
    PAGE_UP = rt.KeyboardKeyPrefix .. "pageup",
    PAGE_DOWN = rt.KeyboardKeyPrefix .. "pagedown",
    INSERT = rt.KeyboardKeyPrefix .. "insert",
    BACKSPACE = rt.KeyboardKeyPrefix .. "backspace",
    TAB = rt.KeyboardKeyPrefix .. "tab",
    CLEAR = rt.KeyboardKeyPrefix .. "clear",
    RETURN = rt.KeyboardKeyPrefix .. "return",
    DELETE = rt.KeyboardKeyPrefix .. "delete",
    F1 = rt.KeyboardKeyPrefix .. "f1",
    F2 = rt.KeyboardKeyPrefix .. "f2",
    F3 = rt.KeyboardKeyPrefix .. "f3",
    F4 = rt.KeyboardKeyPrefix .. "f4",
    F5 = rt.KeyboardKeyPrefix .. "f5",
    F6 = rt.KeyboardKeyPrefix .. "f6",
    F7 = rt.KeyboardKeyPrefix .. "f7",
    F8 = rt.KeyboardKeyPrefix .. "f8",
    F9 = rt.KeyboardKeyPrefix .. "f9",
    F10 = rt.KeyboardKeyPrefix .. "f10",
    F11 = rt.KeyboardKeyPrefix .. "f11",
    F12 = rt.KeyboardKeyPrefix .. "f12",
    NUM_LOCK = rt.KeyboardKeyPrefix .. "numlock",
    CAPS_LOCK = rt.KeyboardKeyPrefix .. "capslock",
    RIGHT_SHIFT = rt.KeyboardKeyPrefix .. "rshift",
    LEFT_SHIFT = rt.KeyboardKeyPrefix .. "lshift",
    LEFT_CONTROL = rt.KeyboardKeyPrefix .. "rcrtl",
    RIGHT_CONTROL = rt.KeyboardKeyPrefix .. "lcrtl",
    RIGHT_ALT = rt.KeyboardKeyPrefix .. "ralt",
    LEFT_ALT = rt.KeyboardKeyPrefix .. "lalt",
    PAUSE = rt.KeyboardKeyPrefix .. "pause",
    ESCAPE = rt.KeyboardKeyPrefix .. "escape",
    HELP = rt.KeyboardKeyPrefix .. "help",
    PRINT_SCREEN = rt.KeyboardKeyPrefix .. "printscreen",
    SYSTEM_REQUEST = rt.KeyboardKeyPrefix .. "sysreq",
    MENU = rt.KeyboardKeyPrefix .. "menu",
    APPLICATION = rt.KeyboardKeyPrefix .. "application",
    POWER = rt.KeyboardKeyPrefix .. "power",
    EURO = rt.KeyboardKeyPrefix .. "currencyunit",
    UNDO = rt.KeyboardKeyPrefix .. "undo",
    SEARCH = rt.KeyboardKeyPrefix .. "acsearch",
    HOME = rt.KeyboardKeyPrefix .. "achome",
    BACK = rt.KeyboardKeyPrefix .. "acback",
    FORWARD = rt.KeyboardKeyPrefix .. "acforward",
    REFRESH = rt.KeyboardKeyPrefix .. "acrefresh",
    BOOKMARKS = rt.KeyboardKeyPrefix .. "acbookmarks",
    NUMPAD_0 = rt.KeyboardKeyPrefix .. "kp0",
    NUMPAD_1 = rt.KeyboardKeyPrefix .. "kp1",
    NUMPAD_2 = rt.KeyboardKeyPrefix .. "kp2",
    NUMPAD_3 = rt.KeyboardKeyPrefix .. "kp3",
    NUMPAD_4 = rt.KeyboardKeyPrefix .. "kp4",
    NUMPAD_5 = rt.KeyboardKeyPrefix .. "kp5",
    NUMPAD_6 = rt.KeyboardKeyPrefix .. "kp6",
    NUMPAD_7 = rt.KeyboardKeyPrefix .. "kp7",
    NUMPAD_8 = rt.KeyboardKeyPrefix .. "kp8",
    NUMPAD_DOT = rt.KeyboardKeyPrefix .. "kp.",
    NUMPAD_COMMA = rt.KeyboardKeyPrefix .. "kp,",
    NUMPAD_SLASH = rt.KeyboardKeyPrefix .. "kp/",
    NUMPAD_ASTERISK = rt.KeyboardKeyPrefix .. "kp*",
    NUMPAD_MINUS = rt.KeyboardKeyPrefix .. "kp-",
    NUMPAD_PLUS = rt.KeyboardKeyPrefix .. "kp+",
    NUMPAD_ENTER = rt.KeyboardKeyPrefix .. "kpenter",
    NUMPAD_EQUALS = rt.KeyboardKeyPrefix .. "kp=",
})

rt.GamepadButtonPrefix = "BUTTON_"

--- @class rt.GamepadButton
rt.GamepadButton = meta.new_enum({
    TOP = rt.GamepadButtonPrefix .. "y",
    RIGHT = rt.GamepadButtonPrefix .. "b",
    BOTTOM = rt.GamepadButtonPrefix .. "a",
    LEFT = rt.GamepadButtonPrefix .. "x",
    DPAD_UP = rt.GamepadButtonPrefix .. "dpup",
    DPAD_DOWN = rt.GamepadButtonPrefix .. "dpdown",
    DPAD_LEFT = rt.GamepadButtonPrefix .. "dpleft",
    DPAD_RIGHT = rt.GamepadButtonPrefix .. "dpright",
    START = rt.GamepadButtonPrefix .. "start",
    SELECT = rt.GamepadButtonPrefix .. "back",
    HOME = rt.GamepadButtonPrefix .. "guide",
    LEFT_STICK = rt.GamepadButtonPrefix .. "leftstick",
    RIGHT_STICK = rt.GamepadButtonPrefix .. "rightstick",
    LEFT_SHOULDER = rt.GamepadButtonPrefix .. "leftshoulder",
    RIGHT_SHOULDER = rt.GamepadButtonPrefix .. "rightshoulder"
})

--- @class rt.GamepadAxis
rt.GamepadAxis = meta.new_enum({
    LEFT_X = "leftx",
    LEFT_Y = "lefty",
    RIGHT_X = "rightx",
    RIGHT_Y = "righty",
    LEFT_TRIGGER = "triggerleft",
    RIGHT_TRIGGER = "triggerright"
})

--- @class
rt.JoystickPosition = meta.new_enum({
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    UNKNOWN = "UNKNON"
})

--- @class rt.MouseButton
rt.MouseButton = meta.new_enum({
    LEFT = 1,
    MIDDLE = 2,
    RIGHT = 3,
    TOUCH = 4
})

--- @class rt.InputButton
rt.InputButton = meta.new_enum({
    A = "A",
    B = "B",
    X = "X",
    Y = "Y",
    UP = "UP",
    RIGHT = "RIGHT",
    DOWN = "DOWN",
    LEFT = "LEFT",
    START = "START",
    SELECT = "SELECT",
    L = "L",
    R = "R",
    DEBUG = "DEBUG"
})

--- @brief
rt._gamepad_button_to_string = {
    ["y"] = "TOP",
    ["b"] = "RIGHT",
    ["a"] = "BOTTOM",
    ["x"] = "LEFT",
    ["dpup"] = "UP",
    ["dpdown"] = "DOWN",
    ["dpleft"] = "LEFT",
    ["dpright"] = "RIGHT",
    ["leftshoulder"] = "L",
    ["rightshoulder"] = "R",
    ["start"] = "START",
    ["back"] = "SELECT",
    ["home"] = "CENTER",
    ["lstick"] = "RIGHT STICK",
    ["rstick"] = "LEFT STRICK",
    ["paddle1"] = "PADDLE #1",
    ["paddle2"] = "PADDLE #2",
    ["paddle3"] = "PADDLE #3",
    ["paddle4"] = "PADDLE #4"
}

function rt.gamepad_button_to_string(gamepad_button)
    local raw = string.sub(gamepad_button, #rt.GamepadButtonPrefix + 1, #gamepad_button)
    local out = rt._gamepad_button_to_string[raw]
    if out == nil then return "UNKNOWN" else return out end
end

function rt.keyboard_key_to_string(keyboard_key)
    if keyboard_key == rt.KeyboardKey.UNKNOWN then return "" end
    local raw = string.sub(keyboard_key, #rt.KeyboardKeyPrefix + 1, #keyboard_key)

    local status
    local status, res = pcall(function() return love.keyboard.getKeyFromScancode(raw) end)
    if status == false then
        rt.warning("In rt.keyboard_key_to_string: invalid scancode `" .. raw .. "`")
        return ""
    end

    local up_arrow = "\u{2191}"
    local down_arrow = "\u{2193}"
    local left_arrow = "\u{2190}"
    local right_arrow = "\u{2192}"
    local space_bar = "\u{2423}"
    local enter = "\u{21B5}"
    local backspace = "\u{232B}"

    if res == "ä" then return "Ä"
    elseif res == "ö" then return "Ö"
    elseif res == "ü" then return "Ü"
    elseif res == "up" then return up_arrow
    elseif res == "right" then return right_arrow
    elseif res == "down" then return down_arrow
    elseif res == "left" then return left_arrow
    elseif res == "space" then return space_bar
    elseif res == "return" then return enter
    --elseif res == "backspace" then return backspace
    else
        return string.upper(res)
    end
end
