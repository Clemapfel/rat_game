--- @class rt.InputHandler
rt.InputHandler = meta.new_type("InputHandler", {
    components = {},        -- Table<Hash, rt.InputComponent>
    mapping = {},           -- Table<rt.GamepadButton, Table<LoveButton>>
    reverse_mapping = {},   -- Table<LoveButton, rt.GamepadButton>
    state = {},             -- Table<rt.InputButton, Boolean>
    axis_state = {},        -- Table<rt.GamepadAxis, Number>
    active_joystick = 1
})() -- singleton instance
meta.make_weak(rt.InputHandler.components, true, true)

rt.KeyboardKeyPrefix = "KEY_"

--- @class rt.KeyboardKey
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
    SEARCH = rt.KeyboardKeyPrefix .. "appsearch",
    HOME = rt.KeyboardKeyPrefix .. "apphome",
    BACK = rt.KeyboardKeyPrefix .. "appback",
    FORWARD = rt.KeyboardKeyPrefix .. "appforward",
    REFRESH = rt.KeyboardKeyPrefix .. "apprefresh",
    BOOKMARKS = rt.KeyboardKeyPrefix .. "appbookmarks",
    KEYPAD_0 = rt.KeyboardKeyPrefix .. "kp0",
    KEYPAD_1 = rt.KeyboardKeyPrefix .. "kp1",
    KEYPAD_2 = rt.KeyboardKeyPrefix .. "kp2",
    KEYPAD_3 = rt.KeyboardKeyPrefix .. "kp3",
    KEYPAD_4 = rt.KeyboardKeyPrefix .. "kp4",
    KEYPAD_5 = rt.KeyboardKeyPrefix .. "kp5",
    KEYPAD_6 = rt.KeyboardKeyPrefix .. "kp6",
    KEYPAD_7 = rt.KeyboardKeyPrefix .. "kp7",
    KEYPAD_8 = rt.KeyboardKeyPrefix .. "kp8",
    KEYPAD_DOT = rt.KeyboardKeyPrefix .. "kp.",
    KEYPAD_COMMA = rt.KeyboardKeyPrefix .. "kp,",
    KEYPAD_SLASH = rt.KeyboardKeyPrefix .. "kp/",
    KEYPAD_ASTERISK = rt.KeyboardKeyPrefix .. "kp*",
    KEYPAD_MINUS = rt.KeyboardKeyPrefix .. "kp-",
    KEYPAD_PLUS = rt.KeyboardKeyPrefix .. "kp+",
    KEYPAD_ENTER = rt.KeyboardKeyPrefix .. "kpenter",
    KEYPAD_EQUALS = rt.KeyboardKeyPrefix .. "kp=",
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
    RIGHT_SHOULDER = rt.GamepadButtonPrefix .. "rightshoulder",
    LEFT_TRIGGER = rt.GamepadButtonPrefix .. "triggerleft",
    RIGHT_TRIGGER = rt.GamepadButtonprefix .. "triggerright"
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
    R = "R"
})

--- @brief
rt.InputMapping = {
    -- A
    [rt.InputButton.A] = {
        rt.GamepadButton.RIGHT,
        rt.KeyboardKey.SPACE
    },

    -- B
    [rt.InputButton.B] = {
        rt.GamepadButton.BOTTOM,
        rt.KeyboardKey.B
    },

    -- X
    [rt.InputButton.X] = {
        rt.GamepadButton.TOP,
        rt.KeyboardKey.X,
    },

    -- Y
    [rt.InputButton.Y] = {
        rt.GamepadButton.LEFT,
        rt.KeyboardKey.Y
    },

    -- L
    [rt.InputButton.L] = {
      rt.GamepadButton.LEFT_SHOULDER,
      rt.KeyboardKey.L
    },

    -- R
    [rt.InputButton.R] = {
      rt.GamepadButton.RIGHT_SHOULDER,
      rt.KeyboardKey.R
    },

    -- START
    [rt.InputButton.START] = {
        rt.GamepadButton.START,
        rt.KeyboardKey.M
    },

    -- SELECT
    [rt.InputButton.SELECT] = {
        rt.GamepadButton.SELECT,
        rt.KeyboardKey.N
    },

    -- UP
    [rt.InputButton.UP] = {
        rt.GamepadButton.DPAD_UP,
        rt.KeyboardKey.ARROW_UP,
        rt.KeyboardKey.W
    },

    -- RIGHT
    [rt.InputButton.RIGHT] = {
        rt.GamepadButton.DPAD_RIGHT,
        rt.KeyboardKey.ARROW_RIGHT,
        rt.KeyboardKey.D
    },

    -- DOWN
    [rt.InputButton.DOWN] = {
        rt.GamepadButton.DPAD_DOWN,
        rt.KeyboardKey.ARROW_DOWN,
        rt.KeyboardKey.S
    },

    -- LEFT
    [rt.InputButton.LEFT] = {
        rt.GamepadButton.DPAD_LEFT,
        rt.KeyboardKey.ARROW_LEFT,
        rt.KeyboardKey.A
    }
}

--- @brief
function rt.InputHandler:update_input_mapping()
    self.reverse_mapping = {}
    self.mapping = {}
    self.state = {}
    for _, input_button in pairs(rt.InputButton) do
        self.mapping[input_button] = {}
        for _, which in pairs(rt.InputMapping[input_button]) do
            table.insert(self.mapping[input_button], which)
            self.reverse_mapping[which] = input_button
        end

        self.state[input_button] = false
    end

    self.axis_state = {}
    for _, axis in pairs(rt.GamepadAxis) do
        self.axis_state[axis] = 0
    end
end
rt.InputHandler:update_input_mapping()