-- ### keybinding config for rat_game
-- ### for a list of available constants, see below
return {
    A = {
        rt.GamepadButton.RIGHT,
        rt.KeyboardKey.SPACE
    },

    B = {
        rt.GamepadButton.BOTTOM,
        rt.KeyboardKey.B
    },

    X = {
        rt.GamepadButton.TOP,
        rt.KeyboardKey.X,
    },

    Y = {
        rt.GamepadButton.LEFT,
        rt.KeyboardKey.Y
    },

    L = {
        rt.GamepadButton.LEFT_SHOULDER,
        rt.KeyboardKey.L
    },

    R = {
        rt.GamepadButton.RIGHT_SHOULDER,
        rt.KeyboardKey.R
    },

    START = {
        rt.GamepadButton.START,
        rt.KeyboardKey.M
    },

    SELECT = {
        rt.GamepadButton.SELECT,
        rt.KeyboardKey.N
    },

    UP = {
        rt.GamepadButton.DPAD_UP,
        rt.KeyboardKey.ARROW_UP,
        rt.KeyboardKey.W
    },

    RIGHT = {
        rt.GamepadButton.DPAD_RIGHT,
        rt.KeyboardKey.ARROW_RIGHT,
        rt.KeyboardKey.D
    },

    DOWN = {
        rt.GamepadButton.DPAD_DOWN,
        rt.KeyboardKey.ARROW_DOWN,
        rt.KeyboardKey.S
    },

    LEFT = {
        rt.GamepadButton.DPAD_LEFT,
        rt.KeyboardKey.ARROW_LEFT,
        rt.KeyboardKey.A
    },

    DEBUG = {
        rt.KeyboardKey.ESCAPE
    }
}

--[[
### Available Constants ###

# Controller                        # XBox  | Nintendo  | Playstation
rt.GamepadButton.TOP                # Y     | X         | Triangle
rt.GamepadButton.RIGHT              # B     | A         | Circle
rt.GamepadButton.BOTTOM             # A     | B         | X
rt.GamepadButton.LEFT               # X     | Y         | Rectangle
rt.GamepadButton.DPAD_UP
rt.GamepadButton.DPAD_DOWN
rt.GamepadButton.DPAD_LEFT
rt.GamepadButton.DPAD_RIGHT
rt.GamepadButton.START
rt.GamepadButton.SELECT
rt.GamepadButton.HOME
rt.GamepadButton.LEFT_STICK
rt.GamepadButton.RIGHT_STICK
rt.GamepadButton.LEFT_SHOULDER
rt.GamepadButton.RIGHT_SHOULDER

# Keyboard
rt.KeyboardKey.A
rt.KeyboardKey.B
rt.KeyboardKey.C
rt.KeyboardKey.D
rt.KeyboardKey.E
rt.KeyboardKey.F
rt.KeyboardKey.G
rt.KeyboardKey.H
rt.KeyboardKey.I
rt.KeyboardKey.J
rt.KeyboardKey.K
rt.KeyboardKey.L
rt.KeyboardKey.M
rt.KeyboardKey.N
rt.KeyboardKey.O
rt.KeyboardKey.P
rt.KeyboardKey.Q
rt.KeyboardKey.R
rt.KeyboardKey.S
rt.KeyboardKey.T
rt.KeyboardKey.U
rt.KeyboardKey.V
rt.KeyboardKey.W
rt.KeyboardKey.X
rt.KeyboardKey.Y
rt.KeyboardKey.Z
rt.KeyboardKey.ZERO
rt.KeyboardKey.ONE
rt.KeyboardKey.TWO
rt.KeyboardKey.THREE
rt.KeyboardKey.FOUR
rt.KeyboardKey.FIVE
rt.KeyboardKey.SIX
rt.KeyboardKey.SEVEN
rt.KeyboardKey.EIGHT
rt.KeyboardKey.NINE
rt.KeyboardKey.SPACE
rt.KeyboardKey.EXCLAMATION_MARK
rt.KeyboardKey.DOUBLE_QUOTE
rt.KeyboardKey.HASHTAG
rt.KeyboardKey.DOLLAR_SIGN
rt.KeyboardKey.SINGLE_QUOTE
rt.KeyboardKey.LEFT_BRACKET
rt.KeyboardKey.RIGHT_BRACKET
rt.KeyboardKey.ASTERISK
rt.KeyboardKey.PLUS
rt.KeyboardKey.COMMA
rt.KeyboardKey.MINUS
rt.KeyboardKey.DOT
rt.KeyboardKey.SLASH
rt.KeyboardKey.COLON
rt.KeyboardKey.SEMICOLON
rt.KeyboardKey.LESS_THAN
rt.KeyboardKey.EQUAL
rt.KeyboardKey.MORE_THAN
rt.KeyboardKey.QUESTION_MARK
rt.KeyboardKey.AT
rt.KeyboardKey.LEFT_SQUARE_BRACKET
rt.KeyboardKey.RIGHT_SQUARE_BRACKET
rt.KeyboardKey.CIRCUMFLEX
rt.KeyboardKey.UNDERSCORE
rt.KeyboardKey.GRAVE_ACCENT
rt.KeyboardKey.ARROW_UP
rt.KeyboardKey.ARROW_DOWN
rt.KeyboardKey.ARROW_RIGHT
rt.KeyboardKey.ARROW_LEFT
rt.KeyboardKey.HOME
rt.KeyboardKey.END
rt.KeyboardKey.PAGE_UP
rt.KeyboardKey.PAGE_DOWN
rt.KeyboardKey.INSERT
rt.KeyboardKey.BACKSPACE
rt.KeyboardKey.TAB
rt.KeyboardKey.CLEAR
rt.KeyboardKey.RETURN
rt.KeyboardKey.DELETE
rt.KeyboardKey.F1
rt.KeyboardKey.F2
rt.KeyboardKey.F3
rt.KeyboardKey.F4
rt.KeyboardKey.F5
rt.KeyboardKey.F6
rt.KeyboardKey.F7
rt.KeyboardKey.F8
rt.KeyboardKey.F9
rt.KeyboardKey.F10
rt.KeyboardKey.F11
rt.KeyboardKey.F12
rt.KeyboardKey.NUM_LOCK
rt.KeyboardKey.CAPS_LOCK
rt.KeyboardKey.RIGHT_SHIFT
rt.KeyboardKey.LEFT_SHIFT
rt.KeyboardKey.LEFT_CONTROL
rt.KeyboardKey.RIGHT_CONTROL
rt.KeyboardKey.RIGHT_ALT
rt.KeyboardKey.LEFT_ALT
rt.KeyboardKey.PAUSE
rt.KeyboardKey.ESCAPE
rt.KeyboardKey.HELP
rt.KeyboardKey.PRINT_SCREEN
rt.KeyboardKey.SYSTEM_REQUEST
rt.KeyboardKey.MENU
rt.KeyboardKey.APPLICATION
rt.KeyboardKey.POWER
rt.KeyboardKey.EURO
rt.KeyboardKey.UNDO
rt.KeyboardKey.SEARCH
rt.KeyboardKey.HOME
rt.KeyboardKey.BACK
rt.KeyboardKey.FORWARD
rt.KeyboardKey.REFRESH
rt.KeyboardKey.BOOKMARKS
rt.KeyboardKey.NUMPAD_0
rt.KeyboardKey.NUMPAD_1
rt.KeyboardKey.NUMPAD_2
rt.KeyboardKey.NUMPAD_3
rt.KeyboardKey.NUMPAD_4
rt.KeyboardKey.NUMPAD_5
rt.KeyboardKey.NUMPAD_6
rt.KeyboardKey.NUMPAD_7
rt.KeyboardKey.NUMPAD_8
rt.KeyboardKey.NUMPAD_DOT
rt.KeyboardKey.NUMPAD_COMMA
rt.KeyboardKey.NUMPAD_SLASH
rt.KeyboardKey.NUMPAD_ASTERISK
rt.KeyboardKey.NUMPAD_MINUS
rt.KeyboardKey.NUMPAD_PLUS
rt.KeyboardKey.NUMPAD_ENTER
rt.KeyboardKey.NUMPAD_EQUALS

### Default Keybindings ###
return {
    A = {
        rt.GamepadButton.RIGHT,
        rt.KeyboardKey.SPACE
    },

    B = {
        rt.GamepadButton.BOTTOM,
        rt.KeyboardKey.B
    },

    X = {
        rt.GamepadButton.TOP,
        rt.KeyboardKey.X,
    },

    Y = {
        rt.GamepadButton.LEFT,
        rt.KeyboardKey.Y
    },

    L = {
        rt.GamepadButton.LEFT_SHOULDER,
        rt.KeyboardKey.L
    },

    R = {
        rt.GamepadButton.RIGHT_SHOULDER,
        rt.KeyboardKey.R
    },

    START = {
        rt.GamepadButton.START,
        rt.KeyboardKey.M
    },

    SELECT = {
        rt.GamepadButton.SELECT,
        rt.KeyboardKey.N
    },

    UP = {
        rt.GamepadButton.DPAD_UP,
        rt.KeyboardKey.ARROW_UP,
        rt.KeyboardKey.W
    },

    RIGHT = {
        rt.GamepadButton.DPAD_RIGHT,
        rt.KeyboardKey.ARROW_RIGHT,
        rt.KeyboardKey.D
    },

    DOWN = {
        rt.GamepadButton.DPAD_DOWN,
        rt.KeyboardKey.ARROW_DOWN,
        rt.KeyboardKey.S
    },

    LEFT = {
        rt.GamepadButton.DPAD_LEFT,
        rt.KeyboardKey.ARROW_LEFT,
        rt.KeyboardKey.A
    },

    DEBUG = {
        rt.KeyboardKey.ESCAPE
    }
}
]]--