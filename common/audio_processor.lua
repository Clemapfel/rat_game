rt.settings.audio_processor = {
    default_window_size = 2^12,
    null_chunk_size = 256
}

rt.AudioProcessor = meta.new_type("AudioProcessor", function(file_path, window_size)
    window_size = which(window_size, rt.settings.audio_processor.default_window_size)
    local data = love.sound.newSoundData(file_path)
    local out = meta.new(rt.AudioProcessor, {
        _data = data,
        _data_t = ternary(data:getBitDepth() == 16, "int16_t", "uint8_t"),
        _source = love.audio.newQueueableSource(
            data:getSampleRate(),
            data:getBitDepth(),
            data:getChannelCount(),
            3
        ),
        _null_chunk = love.sound.newSoundData(
            rt.settings.audio_processor.null_chunk_size,
            data:getSampleRate(),
            data:getBitDepth(),
            data:getChannelCount()
        ),
        _buffer_offset = 0,     -- position of already queued buffers
        _playing_offset = 0,    -- position of currently playing sample
        _last_update = -1,
        _n_transformed = 0,       -- number of samples processed by fourier transform
        _window_size = window_size, -- window used for queing audio and fourier transform

        transform = {},
        on_update = nil
    })

    for i = 1, out._null_chunk:getSampleCount() do
        out._null_chunk:setSample(i - 1, 0)
    end

    if data:getChannelCount() > 2 then
        rt.error("In rt.AudioProcessor: audio file at `" .. file_path .. "` is neither mono nor stereo, more than 2 channels are not supported")
    end
    return out
end)

rt.AudioProcessor.ft = rt.FourierTransform()

--- @brief
function rt.AudioProcessor:start()
    self._playing = true
    self._source:play()
end

--- @brief
function rt.AudioProcessor:stop()
    self._playing = false
    self._source:stop()
end

--- @brief
--- @param data love.AudioData
--- @param sample_offset Number
--- @param window_size Number
function rt.AudioProcessor:_signal_to_spectrum(data, offset, window_size)

    -- initialize transform memory for window size
    local tf = self.transform
    if meta.is_nil(self.transform) or self.transform.window_size ~= window_size then
        self.transform = {
            window_size = window_size,
            fourier_normalize_factor = 1 / math.sqrt(window_size),
            fftw_real = self.ft._alloc_real(window_size),
            fftw_complex = self.ft._alloc_complex(window_size),
            plan_signal_to_spectrum = {},
            plan_spectrum_to_signal = {}
        }

        tf = self.transform

        tf.plan_signal_to_spectrum = self.ft._plan_dft_r2c_1d(
            window_size,
            tf.fftw_real,
            tf.fftw_complex,
            self.ft._plan_mode
        )

        tf.plan_spectrum_to_signal = self.ft._plan_dft_c2r_1d(
            window_size,
            tf.fftw_complex,
            tf.fftw_real,
            self.ft._plan_mode
        )
    end

    local data_n = data:getSampleCount() * data:getChannelCount()
    local data_ptr = ffi.cast(self._data_t .. "*", self._data:getFFIPointer())
    local from = ffi.cast(self.ft._real_data_t, tf.fftw_real)

    -- convert audio signal to doubles
    if self._data:getChannelCount() == 1 then
        local normalize = function(x)
            return (x - 2^8) / (2^8 - 1)
        end

        for i = 1, self._window_size do
            if offset + i < data_n then
                from[i - 1] = ffi.cast("double", normalize(data_ptr[offset + i - 1]))
            else
                from[i - 1] = ffi.cast("double", 0)
            end
        end
    else -- stereo
        local normalize = function(x)
            return x / (2^16 / 2 - 1)
        end

        for i = 1, tf.window_size * 2, 2 do
            local index = offset * 2 + i - 1
            if offset + index < data_n then
                local left = normalize(data_ptr[index + 0])
                local right = normalize(data_ptr[index + 1])
                from[(i / 2) - 1] = left + right / 2.0
            else
                from[(i / 2) - 1] = 0
            end
        end
    end

    self.ft._execute(tf.plan_signal_to_spectrum)

    -- convert complex to magnitude, also take first half only and flip
    local to = ffi.cast(self.ft._complex_data_t, tf.fftw_complex)
    local half = math.floor(0.5 * tf.window_size)
    local normalize_factor = tf.fourier_normalize_factor

    local magnitude_out = {}
    for i = 1, half do
        local complex = ffi.cast(self.ft._complex_t, to[half - i - 1 - 1])
        local magnitude = rt.magnitude(complex[0], complex[1])
        magnitude = magnitude * normalize_factor -- project into [0, 1]
        table.insert(magnitude_out, magnitude)
    end

    return magnitude_out
end

--- @brief
function rt.AudioProcessor:update()
    if self._source:getFreeBufferCount() > 0 then
        local n_samples_to_push = math.min(self._window_size, clamp(self._data:getSampleCount() * self._data:getChannelCount() - self._buffer_offset, 0))
        if n_samples_to_push ~= 0 then
            assert(self._source:queue(
                self._data:getPointer(),
                self._buffer_offset * ffi.sizeof(self._data_t),
                n_samples_to_push * ffi.sizeof(self._data_t),
                self._data:getSampleRate(),
                self._data:getBitDepth(),
                self._data:getChannelCount()
            ))
            self._source:play()
            self._playing = true
            self._buffer_offset = self._buffer_offset + n_samples_to_push
        else
            self._playing = false
            self._buffer_offset = self._data:getSampleCount()
        end

        self._last_update = love.timer.getDelta()
    end

    if self._playing then
        local previous = self._last_update
        self._last_update = love.timer.getDelta()
        local delta = self._last_update - previous
        self._playing_offset = self._playing_offset + self._last_update * self._data:getSampleRate()

        while self._n_transformed <= self._playing_offset do
            if self.on_update ~= nil then
                self.on_update({1, 2, 3}) --self:_signal_to_spectrum(self._data, self._n_transformed, self._window_size))
            end
            self._n_transformed = self._n_transformed + self._window_size
        end
    end
    self._last_update = love.timer.getTime()
end