--- @class rt.AudioPlaybackMode
rt.AudioPlaybackMode = meta.new_enum({
    FROM_MEMORY = "static",
    FROM_DISK = "stream"
})

--- @class AudioPlayback
--- @param filename_or_audio rt.Audio (or String)
--- @param mode rt.AudioPlaybackMode (or nil)
rt.AudioPlayback = meta.new_type("AudioPlayback", function(filename_or_audio, mode)
    if meta.is_nil(mode) then mode = rt.AudioPlaybackMode.FROM_MEMORY end
    meta.assert_enum(mode, rt.AudioPlaybackMode)

    local native, data = {}, {}
    if meta.is_string(filename_or_audio) then
        native = love.audio.newSource(filename_or_audio, mode)
        data = {}
    else
        meta.assert_isa(filename_or_audio, rt.Audio)
        native = love.audio.newSource(filename_or_audio._native, mode)
        data = filename_or_audio
    end

    return meta.new(rt.AudioPlayback, {
        _native = native,
        _data = data
    })
end)

--- @brief start playback from current position
function rt.AudioPlayback:play()
    meta.assert_isa(self, rt.AudioPlayback)
    self._native:play()
end

--- @brief pause playback, retains current position
function rt.AudioPlayback:pause()
    meta.assert_isa(self, rt.AudioPlayback)
    self._native:pause()
end

--- @brief stop playback, rewinds to start
function rt.AudioPlayback:reset()
    meta.assert_isa(self, rt.AudioPlayback)
    self._native:seek(0)
end

--- @brief set playback position
--- @param time_or_sample rt.Time (or Number) duration or sample index
function rt.AudioPlayback:set_position(time_or_sample)
    meta.assert_isa(self, rt.AudioPlayback)
    if meta.isa(time_or_sample, rt.Time) then
        self._native:seek(time_or_sample:as_seconds(), "seconds")
    else
        meta.assert_number(time_or_sample)
        self._native:seek(time_or_sample, "samples")
    end
end

--- @brief get playback position
--- @return rt.Time
function rt.AudioPlayback:get_position()
    meta.assert_isa(self, rt.AudioPlayback)
    return rt.seconds(self._native:tell("seconds"))
end

--- @brief set whether audio should loop
--- @param b Boolean
function rt.AudioPlayback:set_should_loop(b)
    meta.assert_isa(self, rt.AudioPlayback)
    self._native:setLooping(b)
end

--- @brief set whether audio should loop
--- @return Boolean
function rt.AudioPlayback:set_should_loop(b)
    meta.assert_isa(self, rt.AudioPlayback)
    self._native:getLooping()
end

--- @brief set volume
--- @param v Number in [0, 1]
function rt.AudioPlayback:set_volume(value)
    meta.assert_isa(self, rt.AudioPlayback)
    meta.assert_number(value)
    if value < 0 or value > 1 then
        rt.error("In AudioPlayback:set_volume: Value `" .. tostring(value) .. "` is outside [0, 1]")
    end
    self._native:setVolumne(value)
end

--- @brief get volume
--- @return Number in [0, 1]
function rt.AudioPlayback:get_volume()
    meta.assert_isa(self, rt.AudioPlayback)
    return self._native:getVolume()
end