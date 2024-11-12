return {
    -- mn.InventoryScene
    inventory_scene = {
        heading = "Inventory" -- <b> appened in inventory_scene
    },

    -- mn.OptionsScene
    options_scene = {
        heading = "<b>Inventory > Settings</b>",

        vsync = "VSync",
        vsync_on = "ON",
        vsync_off = "OFF",
        vsync_adaptive = "ADAPTIVE",

        fullscreen = "Fullscreen",
        fullscreen_on = "YES",
        fullscreen_off = "NO",

        msaa = "MSAA",
        msaa_off = "0",
        msaa_good = "2",
        msaa_better = "4",
        msaa_best = "8",
        msaa_max = "16",

        resolution = "Resolution",
        resolution_1280_720 = "1280x720 (16:9)",
        resolution_1366_768 = "1366x768 (16:9)",
        resolution_1600_900 = "1600x900 (16:9)",
        resolution_1920_1080 = "1920x1080 (16:9)",
        resolution_2560_1440 = "2560x1400 (16:9)",

        resolution_1280_800 = "1280x800 (16:10)",
        resolution_1440_900 = "1440x900 (16:10)",
        resolution_1680_1050 = "1680x1050 (16:10)",
        resolution_1920_1200 = "1920x1200 (16:10)",
        resolution_2560_1600 = "2560x1600 (16:10)",

        resolution_2560_1080 = "2560x1080 (21:9)",
        resolution_native = "Native",

        gamma = "Gamma",
        sfx_level = "Sound Effects",
        music_level = "Music",
        vfx_motion = "Motion Effects",
        vfx_contrast = "Visual Effects",
        deadzone = "Deadzone",
        keymap = "Controls",

        control_indicator_a = "Change Value",
        control_indicator_b = "Exit",
        control_indicator_y = "Restore Default",
        control_indicator_left_right = "Change Value",
        control_indicator_keymap_item_select = "Select"
    },

    -- rt.input_button_to_string
    [rt.InputButton.A] = "A",
    [rt.InputButton.B] = "B",
    [rt.InputButton.X] = "X",
    [rt.InputButton.Y] = "Y",
    [rt.InputButton.UP] = "Move Up",
    [rt.InputButton.RIGHT] = "Move Right",
    [rt.InputButton.DOWN] = "Move Down",
    [rt.InputButton.LEFT] = "Move Left",
    [rt.InputButton.L] = "Left Alt",
    [rt.InputButton.R] = "Right Alt",
    [rt.InputButton.START] = "Start",
    [rt.InputButton.SELECT] = "Select",

    -- mn.KeybindingScene
    keybindings_scene = {
        accept = "Accept",
        go_back = "Abort",
        heading_keyboard = "<b>Settings > Controls > Keyboard</b>",
        heading_gamepad = "<b>Settings > Controls > Gamepad</b>",
        restore_defaults = "Restore Defaults",

        control_indicator_a = "Remap",
        control_indicator_all = "Select",
        control_indicator_b = "Abort",

        confirm_load_default_message = "Restore Default Keybindings?",
        confirm_load_default_submessage = "This will override TODO",

        confirm_abort_message = "Are you sure you want to abort?",
        confirm_abort_submessage = "The current keybinding modification will not be applied",

        keybinding_invalid_message = "Invalid Keybinding"
    }
}