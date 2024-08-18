--- @class mn.OptionsScene
mn.OptionsScene = meta.new_type("MenuOptionsScene", rt.Scene, function(state)

    local out = {
        _state = state
    }
    
    out._vsync_label_text = "VSync"
    out._vsync_on_label = "ON"
    out._vsync_off_label = "OFF"
    out._vsync_adaptive_label = "ADAPTIVE"

    out._fullscreen_label_text = "Fullscreen"
    out._fullscreen_true_label = "YES"
    out._fullscreen_false_label = "NO"

    out._borderless_label_text = "Borderless"
    out._borderless_true_label = "YES"
    out._borderless_false_label = "NO"

    out._msaa_label_text = "MSAA"
    out._msaa_0_label = "0"
    out._msaa_2_label = "2"
    out._msaa_4_label = "4"
    out._msaa_8_label = "8"
    out._msaa_16_label = "16"

    out._resolution_label_text = "Resolution"
    out._resolution_1280_720_label = "1280x720 (16:9)"
    out._resolution_1600_900_label = "1600x900 (16:9)"
    out._resolution_1920_1080_label = "1920x1080 (16:9)"
    out._resolution_2560_1440_label = "2560x1400 (16:9)"
    out._resolution_variable_label = "custom"

    out._multiple_choice_layout = {
        [out._vsync_label_text] = {
            options = {
                out._vsync_on_label,
                out._vsync_off_label,
                out._vsync_adaptive_label
            },
            default = out._vsync_adaptive_label
        },

        [out._fullscreen_label_text] = {
            options = {
                out._fullscreen_true_label,
                out._fullscreen_false_label
            },
            default = out._fullscreen_false_label
        },

        [out._borderless_label_text] = {
            options = {
                out._borderless_true_label,
                out._borderless_false_label,
            },
            default = out._borderless_false_label
        },

        [out._msaa_label_text] = {
            options = {
                out._msaa_0_label,
                out._msaa_2_label,
                out._msaa_4_label,
                out._msaa_8_label,
                out._msaa_16_label
            },
            default = out._msaa_8_label
        },

        [out._resolution_label_text] = {
            options = {
                out._resolution_1280_720_label,
                out._resolution_1600_900_label,
                out._resolution_1920_1080_label,
                out._resolution_2560_1440_label,
                out._resolution_variable_label,
            },
            default = out._resolution_1280_720_label
        }
    }

    out._sfx_level_text = "Sound Effects"
    out._music_level_text = "Music"
    out._vfx_motion_text = "Motion Effects"
    out._vfx_contrast_text = "Visual Effects"

    out._level_layout = {
        [out._sfx_level_text] = {
            range = {0, 100, 100},
            default = 50
        },

        [out._music_level_text] = {
            range = {0, 100, 100},
            default = 50
        },

        [out._vfx_motion_text] = {
            range = {0, 3, 3},
            default = 3
        },

        [out._vfx_contrast_text] = {
            range = {0, 100, 1},
            default = 100
        }
    }

    return meta.new(mn.OptionsScene, out)
end)

--- @override
function mn.OptionsScene:realize()
    if self._is_realized then return end

    local scene = self

    local label_prefix, label_postfix = "<b>", "</b>"
    local create_button_and_label = function(name, text, handler)
        local label = rt.Label(label_prefix .. text .. label_postfix)
        label:set_justify_mode(rt.JustifyMode.LEFT)
        label:realize()

        local button = mn.OptionsButton(table.unpack(scene._multiple_choice_layout[text]))
        button:realize()

        scene["_" .. name .. "_label"] = label
        scene["_" .. name .. "_option_button"] = button
        scene["_" .. name .. "_option_button"]:signal_connect("select", handler)
    end

    create_button_and_label("vsync", self._vsync_label, function(_, which)
        local mode
        if which == scene._vsync_on_label then
            mode = rt.VSyncMode.ON
        elseif which == scene._vsync_off_label then
            mode = rt.VSyncMode.OFF
        elseif which == scene._vsync_adaptive_label then
            mode = rt.VSyncMode.ADAPTIVE
        end
        scene._state:set_vsync_mode(mode)
    end)

    create_button_and_label("fullscreen", self._fullscreen_label_text, function(_, which)
        local on
        if which == scene._fullscreen_true_label then
            on = true
        elseif which == scene._fullscreen_false_label then
            on = false
        end
        scene._state:set_fullscreen(on)
    end)

    create_button_and_label("borderless", self._borderless_label_text, function(_, which)
        local on
        if which == scene._borderless_true_label then
            on = true
        elseif which == scene._borderless_false_label then
            on = false
        end
        scene._state:set_borderless(on)
    end)

    create_button_and_label("msaa", self._msaa_label_text, function(_, which)
        local level
        if which == scene._msaa_0_label then
            level = 0
        elseif which == scene._msaa_2_label then
            level = 2
        elseif which == scene._msaa_4_label then
            level = 4
        elseif which == scene._msaa_8_label then
            level = 8
        elseif which == scene._msaa_16_label then
            level = 16
        end
        scene._state:set_msaa_level(level)
    end)

    create_button_and_label("resolution", self._resolution_label_text, function(_, which)
        if which == scene._resolution_variable_label then
            scene._state:set_window_resizable(true)
            return
        end

        local x_res, y_res
        if which == scene._resolution_1280_720_label then
            x_res, y_res = 1280, 720
        elseif which == scene._resolution_1600_900_label then
            x_res, y_res = 1600, 900
        elseif which == scene._resolution_1920_1080_label then
            x_res, y_res = 1920, 1080
        elseif which == scene._resolution_2560_1440_label then
            x_res, y_res = 2560, 1440
        end

        scene._state:set_resizable(false)
        scene._state:set_resolution(x_res, y_res)
    end)

    --

    local create_button_and_scale = function(name, text, handler)
        local label = rt.Label(label_prefix .. text .. label_postfix)
        label:set_justify_mode(rt.JustifyMode.LEFT)
        label:realize()

        local item = self._level_layout[text]
        local scale = mn.Scale(
            item.range[1],
            item.range[2],
            item.range[3],
            item.default
        )

        scale:realize()
        scale:signal_connect("value_changed", handler)
    end

    create_button_and_scale("sfx_level", self._sfx_level_text, function(_, fraction)
        scene._state:set_sfx_level(fraction)
    end)

    create_button_and_scale("music_level", self._music_level_text, function(_, fraction)
        scene._state:set_music_level(fraction)
    end)

    create_button_and_scale("vfx_motion", self._vfx_motion_text, function(_, fraction)
        scene._state:set_vfx_motion_level(fraction)
    end)

    create_button_and_scale("vfx_contrast", self._vfx_contrast_text, function(_, fraction)
        scene._state:set_vfx_contrast_level(fraction)
    end)
end
