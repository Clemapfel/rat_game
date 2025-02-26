rt.KeyboardKeyPrefix = "KEY_"

--- @class rt.KeyboardKey
--- @see https://love2d.org/wiki/Scancode
rt.KeyboardKey = meta.enum("KeyboardKey", {
    A = rt.KeyboardKeyPrefix .."a",
    B = rt.KeyboardKeyPrefix .."b",
    C = rt.KeyboardKeyPrefix .."c",
    D = rt.KeyboardKeyPrefix .."d",
    E = rt.KeyboardKeyPrefix .."e",
    F = rt.KeyboardKeyPrefix .."f",
    G = rt.KeyboardKeyPrefix .."g",
    H = rt.KeyboardKeyPrefix .."h",
    I = rt.KeyboardKeyPrefix .."i",
    J = rt.KeyboardKeyPrefix .."j",
    K = rt.KeyboardKeyPrefix .."k",
    L = rt.KeyboardKeyPrefix .."l",
    M = rt.KeyboardKeyPrefix .."m",
    N = rt.KeyboardKeyPrefix .."n",
    O = rt.KeyboardKeyPrefix .."o",
    P = rt.KeyboardKeyPrefix .."p",
    Q = rt.KeyboardKeyPrefix .."q",
    R = rt.KeyboardKeyPrefix .."r",
    S = rt.KeyboardKeyPrefix .."s",
    T = rt.KeyboardKeyPrefix .."t",
    U = rt.KeyboardKeyPrefix .."u",
    V = rt.KeyboardKeyPrefix .."v",
    W = rt.KeyboardKeyPrefix .."w",
    X = rt.KeyboardKeyPrefix .."x",
    Y = rt.KeyboardKeyPrefix .."y",
    Z = rt.KeyboardKeyPrefix .."z",
    ONE = rt.KeyboardKeyPrefix .."1",
    TWO = rt.KeyboardKeyPrefix .."2",
    THREE = rt.KeyboardKeyPrefix .."3",
    FOUR = rt.KeyboardKeyPrefix .."4",
    FIVE = rt.KeyboardKeyPrefix .."5",
    SIX = rt.KeyboardKeyPrefix .."6",
    SEVEN = rt.KeyboardKeyPrefix .."7",
    EIGHT = rt.KeyboardKeyPrefix .."8",
    NINE = rt.KeyboardKeyPrefix .."9",
    ZERO = rt.KeyboardKeyPrefix .."0",
    RETURN = rt.KeyboardKeyPrefix .."return",
    ESCAPE = rt.KeyboardKeyPrefix .."escape",
    BACKSPACE = rt.KeyboardKeyPrefix .."backspace",
    TAB = rt.KeyboardKeyPrefix .."tab",
    SPACE = rt.KeyboardKeyPrefix .."space",
    MINUS = rt.KeyboardKeyPrefix .."-",
    EQUAL = rt.KeyboardKeyPrefix .."=",
    LEFT_SQUARE_BRACKET = rt.KeyboardKeyPrefix .."[",
    RIGHT_SQUARE_BRACKET = rt.KeyboardKeyPrefix .."]",
    DOUBLE_QUOTE = rt.KeyboardKeyPrefix .."\"",
    NON_US_HASH = rt.KeyboardKeyPrefix .."nonus#",
    SEMICOLON = rt.KeyboardKeyPrefix ..";",
    SINGLE_QUOTE = rt.KeyboardKeyPrefix .."'",
    GRAVE_ACCENT = rt.KeyboardKeyPrefix .."`",
    COMMA = rt.KeyboardKeyPrefix ..",",
    DOT = rt.KeyboardKeyPrefix ..".",
    SLASH = rt.KeyboardKeyPrefix .."/",
    CAPS = rt.KeyboardKeyPrefix .."capslock",
    F1 = rt.KeyboardKeyPrefix .."f1",
    F2 = rt.KeyboardKeyPrefix .."f2",
    F3 = rt.KeyboardKeyPrefix .."f3",
    F4 = rt.KeyboardKeyPrefix .."f4",
    F5 = rt.KeyboardKeyPrefix .."f5",
    F6 = rt.KeyboardKeyPrefix .."f6",
    F7 = rt.KeyboardKeyPrefix .."f7",
    F8 = rt.KeyboardKeyPrefix .."f8",
    F9 = rt.KeyboardKeyPrefix .."f9",
    F10 = rt.KeyboardKeyPrefix .."f10",
    F11 = rt.KeyboardKeyPrefix .."f11",
    F12 = rt.KeyboardKeyPrefix .."f12",
    F13 = rt.KeyboardKeyPrefix .."f13",
    F14 = rt.KeyboardKeyPrefix .."f14",
    F15 = rt.KeyboardKeyPrefix .."f15",
    F16 = rt.KeyboardKeyPrefix .."f16",
    F17 = rt.KeyboardKeyPrefix .."f17",
    F18 = rt.KeyboardKeyPrefix .."f18",
    F19 = rt.KeyboardKeyPrefix .."f19",
    F20 = rt.KeyboardKeyPrefix .."f20",
    F21 = rt.KeyboardKeyPrefix .."f21",
    F22 = rt.KeyboardKeyPrefix .."f22",
    F23 = rt.KeyboardKeyPrefix .."f23",
    F24 = rt.KeyboardKeyPrefix .."f24",
    LEFT_CONTROL = rt.KeyboardKeyPrefix .."lctrl",
    LEFT_SHIFT = rt.KeyboardKeyPrefix .."lshift",
    LEFT_ALT = rt.KeyboardKeyPrefix .."lalt",
    LEFT_GUI = rt.KeyboardKeyPrefix .."lgui",
    RIGHT_CONTROL = rt.KeyboardKeyPrefix .."rctrl",
    RIGHT_SHIFT = rt.KeyboardKeyPrefix .."rshift",
    RIGHT_ALT = rt.KeyboardKeyPrefix .."ralt",
    RIGHT_GUI = rt.KeyboardKeyPrefix .."rgui",
    PRINTSCREEN = rt.KeyboardKeyPrefix .."printscreen",
    SCROLLLOCK = rt.KeyboardKeyPrefix .."scrolllock",
    PAUSE = rt.KeyboardKeyPrefix .."pause",
    INSERT = rt.KeyboardKeyPrefix .."insert",
    HOME = rt.KeyboardKeyPrefix .."home",
    NUMLOCK = rt.KeyboardKeyPrefix .."numlock",
    PAGE_UP = rt.KeyboardKeyPrefix .."pageup",
    DELETE = rt.KeyboardKeyPrefix .."delete",
    END = rt.KeyboardKeyPrefix .."end",
    PAGE_DOWN = rt.KeyboardKeyPrefix .."pagedown",
    ARROW_RIGHT = rt.KeyboardKeyPrefix .."right",
    ARROW_LEFT = rt.KeyboardKeyPrefix .."left",
    ARROW_DOWN = rt.KeyboardKeyPrefix .."down",
    ARROW_UP = rt.KeyboardKeyPrefix .."up",
    BACKSLASH = rt.KeyboardKeyPrefix .. "\\",
    NON_US_BACKSLASH = rt.KeyboardKeyPrefix .."nonusbackslash",
    APPLICATION = rt.KeyboardKeyPrefix .."application",
    EXECUTE = rt.KeyboardKeyPrefix .."execute",
    HELP = rt.KeyboardKeyPrefix .."help",
    MENU = rt.KeyboardKeyPrefix .."menu",
    SELECT = rt.KeyboardKeyPrefix .."select",
    STOP = rt.KeyboardKeyPrefix .."stop",
    AGAIN = rt.KeyboardKeyPrefix .."again",
    UNDO = rt.KeyboardKeyPrefix .."undo",
    CUT = rt.KeyboardKeyPrefix .."cut",
    COPY = rt.KeyboardKeyPrefix .."copy",
    PASTE = rt.KeyboardKeyPrefix .."paste",
    FIND = rt.KeyboardKeyPrefix .."find",
    KEYPAD_SLASH = rt.KeyboardKeyPrefix .."kp/",
    KEYPAD_ASTERISK = rt.KeyboardKeyPrefix .."kp*",
    KEYPAD_MINUS = rt.KeyboardKeyPrefix .."kp-",
    KEYPAD_PLUS = rt.KeyboardKeyPrefix .."kp+",
    KEYPAD_EQUAL = rt.KeyboardKeyPrefix .."kp=",
    KEYPAD_ENTER = rt.KeyboardKeyPrefix .."kpenter",
    KEYPAD_ONE = rt.KeyboardKeyPrefix .."kp1",
    KEYPAD_TWO = rt.KeyboardKeyPrefix .."kp2",
    KEYPAD_THREE = rt.KeyboardKeyPrefix .."kp3",
    KEYPAD_FOUR = rt.KeyboardKeyPrefix .."kp4",
    KEYPAD_FIVE = rt.KeyboardKeyPrefix .."kp5",
    KEYPAD_SIX = rt.KeyboardKeyPrefix .."kp6",
    KEYPAD_SEVEN = rt.KeyboardKeyPrefix .."kp7",
    KEYPAD_EIGHT = rt.KeyboardKeyPrefix .."kp8",
    KEYPAD_NINE = rt.KeyboardKeyPrefix .."kp9",
    KEYPAD_ZERO = rt.KeyboardKeyPrefix .."kp0",
    KEYPAD_DOT = rt.KeyboardKeyPrefix .."kp.",
    INTERNATIONAL_1 = rt.KeyboardKeyPrefix .."international1",
    INTERNATIONAL_2 = rt.KeyboardKeyPrefix .."international2",
    INTERNATIONAL_3 = rt.KeyboardKeyPrefix .."international3",
    INTERNATIONAL_4 = rt.KeyboardKeyPrefix .."international4",
    INTERNATIONAL_5 = rt.KeyboardKeyPrefix .."international5",
    INTERNATIONAL_6 = rt.KeyboardKeyPrefix .."international6",
    INTERNATIONAL_7 = rt.KeyboardKeyPrefix .."international7",
    INTERNATIONAL_8 = rt.KeyboardKeyPrefix .."international8",
    INTERNATIONAL_9 = rt.KeyboardKeyPrefix .."international9",
    LANG_1 = rt.KeyboardKeyPrefix .."lang1",
    LANG_2 = rt.KeyboardKeyPrefix .."lang2",
    LANG_3 = rt.KeyboardKeyPrefix .."lang3",
    LANG_4 = rt.KeyboardKeyPrefix .."lang4",
    LANG_5 = rt.KeyboardKeyPrefix .."lang5",
    MUTE = rt.KeyboardKeyPrefix .."mute",
    VOLUME_UP = rt.KeyboardKeyPrefix .."volumeup",
    VOLUME_DOWN = rt.KeyboardKeyPrefix .."volumedown",
    AUDIO_NEXT = rt.KeyboardKeyPrefix .."audionext",
    AUDIO_PREVIOUS = rt.KeyboardKeyPrefix .."audioprev",
    AUDIO_STOP = rt.KeyboardKeyPrefix .."audiostop",
    AUDIO_PLAY = rt.KeyboardKeyPrefix .."audioplay",
    AUDIO_MUTE = rt.KeyboardKeyPrefix .."audiomute",
    MEDIA_SELECT = rt.KeyboardKeyPrefix .."mediaselect",
    WWW = rt.KeyboardKeyPrefix .."www",
    MAIL = rt.KeyboardKeyPrefix .."mail",
    CALCAULTOR = rt.KeyboardKeyPrefix .."calculator",
    COMPUTER = rt.KeyboardKeyPrefix .."computer",
    AC_SEARCH = rt.KeyboardKeyPrefix .."acsearch",
    AC_HOME = rt.KeyboardKeyPrefix .."achome",
    AC_BACK = rt.KeyboardKeyPrefix .."acback",
    AC_FORWARD = rt.KeyboardKeyPrefix .."acforward",
    AC_STOP = rt.KeyboardKeyPrefix .."acstop",
    AC_REFRESH = rt.KeyboardKeyPrefix .."acrefresh",
    AC_BOOKMARKS = rt.KeyboardKeyPrefix .."acbookmarks",
    POWER = rt.KeyboardKeyPrefix .."power",
    BRIGHTNESS_DOWN = rt.KeyboardKeyPrefix .."brightnessdown",
    BRIGHTNESS_UP = rt.KeyboardKeyPrefix .."brightnessup",
    DISPLAY_SWITCH = rt.KeyboardKeyPrefix .."displayswitch",
    KEYBOARD_ILLUMINATION_TOGGLE = rt.KeyboardKeyPrefix .."kbdillumtoggle",
    KEYBOARD_ILLUMINATION_DOWN = rt.KeyboardKeyPrefix .."kbdillumdown",
    KEYBOARD_ILLUMINATION_UP = rt.KeyboardKeyPrefix .."kbdillumup",
    EJECT = rt.KeyboardKeyPrefix .."eject",
    SLEEP = rt.KeyboardKeyPrefix .."sleep",
    ALT_ERASE = rt.KeyboardKeyPrefix .."alterase",
    SYSREQ = rt.KeyboardKeyPrefix .."sysreq",
    CANCEL = rt.KeyboardKeyPrefix .."cancel",
    CLEAR = rt.KeyboardKeyPrefix .."clear",
    PRIOR = rt.KeyboardKeyPrefix .."prior",
    RETURN_2 = rt.KeyboardKeyPrefix .."return2",
    SEPARATOR = rt.KeyboardKeyPrefix .."separator",
    OUT = rt.KeyboardKeyPrefix .."out",
    OPER = rt.KeyboardKeyPrefix .."oper",
    CLEAR_AGAIN = rt.KeyboardKeyPrefix .."clearagain",
    CRSEL = rt.KeyboardKeyPrefix .."crsel",
    EXSEL = rt.KeyboardKeyPrefix .."exsel",
    KEYPAD_00 = rt.KeyboardKeyPrefix .."kp00",
    KEYPAD_000 = rt.KeyboardKeyPrefix .."kp000",
    THOUSANDS_SEPARATOR = rt.KeyboardKeyPrefix .."thousandsseparator",
    DECIMAL_SEPARATOR = rt.KeyboardKeyPrefix .."decimalseparator",
    CURRENCY_UNIT = rt.KeyboardKeyPrefix .."currencyunit",
    CURRENCY_SUBUNIT = rt.KeyboardKeyPrefix .."currencysubunit",
    APP_1 = rt.KeyboardKeyPrefix .."app1",
    APP_2 = rt.KeyboardKeyPrefix .."app2",
    UNKNOWN = rt.KeyboardKeyPrefix .."unknown"
})

rt.GamepadButtonPrefix = "BUTTON_"

--- @class rt.GamepadButton
rt.GamepadButton = meta.enum("GamepadButton", {
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
    CENTER = rt.GamepadButtonPrefix .. "guide",
    LEFT_STICK = rt.GamepadButtonPrefix .. "leftstick",
    RIGHT_STICK = rt.GamepadButtonPrefix .. "rightstick",
    LEFT_SHOULDER = rt.GamepadButtonPrefix .. "leftshoulder",
    RIGHT_SHOULDER = rt.GamepadButtonPrefix .. "rightshoulder",
    UNKNOWN = rt.GamepadButtonPrefix .. "unknown"
})

--- @class rt.GamepadAxis
rt.GamepadAxis = meta.enum("GamepadAxis", {
    LEFT_X = "leftx",
    LEFT_Y = "lefty",
    RIGHT_X = "rightx",
    RIGHT_Y = "righty",
    LEFT_TRIGGER = "triggerleft",
    RIGHT_TRIGGER = "triggerright"
})

--- @class rt.JoystickPosition
rt.JoystickPosition = meta.enum("JoystickPosition", {
    LEFT = "LEFT",
    RIGHT = "RIGHT",
    UNKNOWN = "UNKNON"
})

--- @class rt.MouseButton
rt.MouseButton = meta.enum("MouseButton", {
    LEFT = 1,
    MIDDLE = 2,
    RIGHT = 3,
    TOUCH = 4
})

--- @class rt.InputButton
rt.InputButton = meta.enum("InputButton", {
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
function rt.keyboard_key_to_native(keyboard_key)
    return string.sub(keyboard_key, #rt.KeyboardKeyPrefix + 1, #keyboard_key)
end

--- @brief
function rt.gamepad_button_to_native(gamepad_button)
    return string.sub(gamepad_button, #rt.GamepadButtonPrefix + 1, #gamepad_button)
end

--- @brief
function rt.keyboard_key_to_string(keyboard_key)
    if keyboard_key == rt.KeyboardKey.UNKNOWN then return "" end
    local raw = rt.keyboard_key_to_native(keyboard_key)

    local status, res = pcall(function() return love.keyboard.getKeyFromScancode(raw) end)
    if status == false then
        rt.warning("In rt.keyboard_key_to_string: invalid scancode `" .. raw .. "`")
        return ""
    end

    local up_arrow = "\u{2191}"
    local down_arrow = "\u{2193}"
    local left_arrow = "\u{2190}"
    local right_arrow = "\u{2192}"
    local space_bar = "SPACE"--"\u{23B5}"
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

--- @brief
function rt.gamepad_button_to_string(gamepad_button)
    return ({
        [rt.GamepadButton.TOP] = "Top Face Button",
        [rt.GamepadButton.RIGHT] = "Right Face Button",
        [rt.GamepadButton.BOTTOM] = "Bottom Face Button",
        [rt.GamepadButton.LEFT] = "Left Face Button",
        [rt.GamepadButton.DPAD_UP] = "DPad Up",
        [rt.GamepadButton.DPAD_DOWN] = "DPad Down",
        [rt.GamepadButton.DPAD_LEFT] = "DPad Left",
        [rt.GamepadButton.DPAD_RIGHT] = "DPad Right",
        [rt.GamepadButton.START] = "Start",
        [rt.GamepadButton.SELECT] = "Select",
        [rt.GamepadButton.CENTER] = "Home",
        [rt.GamepadButton.LEFT_STICK] = "Left Stick Press",
        [rt.GamepadButton.RIGHT_STICK] = "Right Stick Press",
        [rt.GamepadButton.LEFT_SHOULDER] = "Left Shoulder",
        [rt.GamepadButton.RIGHT_SHOULDER] = "Right Shoulder",
        [rt.GamepadButton.UNKNOWN] = "(Unknown)",
    })[gamepad_button]
end

--- @brief
function rt.input_button_to_string(button)
    return rt.Translation[button]
end

