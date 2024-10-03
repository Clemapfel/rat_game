midi = {}

midi._message_callback = ffi.cast("RtMidiCCallback", function(
    time_stamp,     -- double
    message,        -- cstring
    message_size,   -- size_t,
    user_data      -- void*
)
    dbg(tostring(message))
end)

