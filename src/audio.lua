rt.settings.audio.data_sample_rate = 44100
rt.settings.audio.data_bit_depth = 16
rt.settings.audio.data_n_channels = 1

--- @class rt.Audio
--- @param arg1 String (or rt.Time or Number) filename (or duration or n samples)
rt.Audio = meta.new_type("Audio", function(filename_or_duration_or_n_samples)
    local native = {}
    local arg = filename_or_duration_or_n_samples
    if meta.is_string(arg) then
        native = love.audio.newSoundData(arg)
    elseif meta.isa(arg, rt.Time) then
        native = love.audio.newSoundData(
            arg:as_seconds() * rt.settings.audio.default_sample_rate,
            rt.settings.audio.default_sample_rate,
            rt.settings.audio.data_bit_depth,
            rt.settings.audio.data_n_channels
        )
    else -- n samples
        meta.assert_number(arg)
        native = love.audio.newSoundData(
            arg,
            rt.settings.audio.default_sample_rate,
            rt.settings.audio.data_bit_depth,
            rt.settings.audio.data_n_channels
        )
    end

    return meta.new(rt.Audio, {
        _native = native
    })
end)

--- @brief load from file
--- @param file String
function rt.Audio:create_from_file(file)
    meta.assert_isa(self, rt.Audio)
    meta.assert_string(file)
    self._native = love.audio.newSoundData(file)
end

--- @brief load from data
--- @param duration_or_n_samples rt.Time (or Number)
function rt.Audio:create(duration_or_n_samples)
    if meta.isa(duration_or_n_samples, rt.Time) then
        self._native = love.audio.newSoundData(
            duration_or_n_samples:as_seconds() * rt.settings.audio.default_sample_rate,
            rt.settings.audio.default_sample_rate,
            rt.settings.audio.data_bit_depth,
            rt.settings.audio.data_n_channels
        )
    else
        meta.assert_number(duration_or_n_samples)
        self._native = love.audio.newSoundData(
            duration_or_n_samples,
            rt.settings.audio.default_sample_rate,
            rt.settings.audio.data_bit_depth,
            rt.settings.audio.data_n_channels
        )
    end
end

--- @brief set sample
--- @param index Number 1-based
--- @param value Number in [-1, 1]
function rt.Audio:set_sample(i, value)
    meta.assert_isa(self, rt.Audio)
    meta.assert_number(i, value)

    if value < -1 or value > 1 then
        println("[rt][WARNING] In rt.Audio.set_sample: Value `" .. tostring(value) .. "` is outside of [-1, 1]")
        value = clamp(value, -1, 1)
    end

    local n_samples = self:get_n_samples()
    if i < 1 or i > n_samples then
        error("[rt][ERROR] In rt.Audio.set_sample: Index `" .. tostring(i) .. "` is out of range for audio data with `" .. tostring(n_samples) .. "`")
    end

    self._native:setSample(i - 1, value)
end

--- @brief get sample
--- @param index Number 1-based
--- @return Number
function rt.Audio:get_sample(i)
    meta.assert_isa(self, rt.Audio)
    meta.assert_number(i)

    local n_samples = self:get_n_samples()
    if i < 1 or i > n_samples then
        error("[rt][ERROR] In rt.Audio.get_sample: Index `" .. tostring(i) .. "` is out of range for audio data with `" .. tostring(n_samples) .. "`")
    end

    return self._native:getSample(i - 1)
end

--- @brief get number of samples
--- @return Number
function rt.Audio:get_n_samples()
    meta.assert_isa(self, rt.Audio)
    return self._native:getSampleCount()
end