--- @brief
--- @signal message (rt.MidiInput, rt.MidiSingalType, value_0_1) -> nil
rt.MidiInput = meta.new_type("MidiInput", rt.SignalEmitter, function()
    local out = meta.new(rt.MidiInput, {
        _native_in = rtmidi.rtmidi_in_create(rtmidi.RTMIDI_API_UNSPECIFIED, "default", 256)
    })
    rtmidi.rtmidi_open_port(out._native_in, 1, "default")
    out:signal_add("message")
    return out
end)

--- @class rt.MidiMessageType
rt.MidiMessageType = meta.new_enum({
    -- SCENE 6 LIVE, Octave -1
    PAD_1 = 0,
    PAD_2 = 1,
    PAD_3 = 2,
    PAD_4 = 3,
    PAD_5 = 4,
    PAD_6 = 5,
    PAD_7 = 6,
    PAD_8 = 7,
    PAD_9 = 8,
    PAD_10 = 9,
    PAD_11 = 10,
    PAD_12 = 11,
    PAD_13 = 12,
    PAD_14 = 13,
    PAD_15 = 14,
    PAD_16 = 15,
    
    PAD_MIN = 0,
    PAD_MAX = 15,

    KNOB_1 = 16,
    KNOB_2 = 17,
    KNOB_3 = 18,
    KNOB_4 = 19,
    KNOB_5 = 20,
    KNOB_6 = 21,
    KNOB_7 = 22,
    KNOB_8 = 23,
    
    KNOB_MIN = 16,
    KNOB_MAX = 23,

    SLIDER_1 = 24,
    SLIDER_2 = 24,
    SLIDER_3 = 25,
    SLIDER_4 = 26,
    SLIDER_5 = 27,
    SLIDER_6 = 28,
    SLIDER_7 = 29,
    SLIDER_8 = 30,
    SLIDER_9 = 31,
    
    SLIDER_MIN = 24,
    SLIDER_MAX = 31,

    JOYSTICK_UP_DOWN = 32,
    JOYSTICK_LEFT_RIGHT = 33,

    MIN_NOTE = 36,
    MAX_NOTE = 120,

    NOTE_OFF = 123,
    START = 250,
    CONTINUE = 251,
    STOP = 252
})

function rt.MidiInput.is_slider(type)
    return type >= rt.MidiMessageType.SLIDER_1 or type <= rt.MidiMessageType.SLIDER_8
end

function rt.MidiInput.is_pad(type)
    return type >= rt.MidiMessageType.PAD_1 or type <= rt.MidiMessageType.PAD_16
end

function rt.MidiInput.is_key(type)
    return type >= rt.MidiMessageType.MIN_NOTE or type <= rt.MidiMessageType.MAX_NOTE
end

--- @brief work through current message queue
function rt.MidiInput:update(_)
    local ref_size = 256
    local message = ffi.new("unsigned char[8]")
    local size = ffi.new("size_t[1]"); size[0] = ref_size

    local timestamp = rtmidi.rtmidi_in_get_message(self._native_in, message, size)
    while size[0] > 0 do
        local status = message[0]
        local controller = message[1]
        local value = message[2]
        if not (meta.is_enum_value(controller, rt.MidiMessageType) or controller >= rt.MidiMessageType.MIN_NOTE and controller <= rt.MidiSignaltype.MAX_NOTE) then
            rt.warning("In rt.MidiInput:update: Unhandled control message `" .. controller .. "`")
        end
        self:signal_emit("message", timestamp, controller, tonumber(value) / 127.0)
        timestamp = rtmidi.rtmidi_in_get_message(self._native_in, message, size)
    end
end