rt.settings.monitored_audio_playback = {
    default_window_size = 2^11
}

rt.MonitoredAudioPlayback = meta.new_type("MonitoredAudioPlayback", function(file_path)
    local data = love.sound.newSoundData(file_path)
    return meta.new(rt.MonitoredAudioPlayback, {
        _data = data,
        _data_t = ternary(data:getBitDepth() == 16, "int16_t", "uint8_t"),
        _source = love.audio.newQueueableSource(
            data:getSampleRate(),
            data:getBitDepth(),
            data:getChannelCount(),
            3
        ),
        _buffer_offset = 0,
        _is_playing_offset = 0,
        _n_transformed = 0,
        _last_update = -1,
        _cutoff_frequency = 12e3,

        _window_size = 256,
        _n_bins = -1,

        on_update = nil
    })
end)

-- fftw interface
rt.MonitoredAudioPlayback.ft = (function()
    local fftw = ffi.load("libfftw3")
    assert(fftw)
    local ft = {}
    ft.fftw = fftw
    ft.fftw_cdef = [[
        extern double* fftw_alloc_real(size_t n);
        extern void* fftw_alloc_complex(size_t n);
        extern void* fftw_plan_dft_r2c_1d(int n, double* in, void* out, unsigned int flags);
        extern void* fftw_plan_dft_c2r_1d(int n, void* in, double* out, unsigned int flags);
        extern void fftw_execute(const void* plan);
    ]]
    ffi.cdef(ft.fftw_cdef)

    ft.alloc_real = fftw.fftw_alloc_real
    ft.alloc_complex = fftw.fftw_alloc_complex
    ft.plan_dft_r2c_1d = fftw.fftw_plan_dft_r2c_1d
    ft.plan_dft_c2r_1d = fftw.fftw_plan_dft_c2r_1d
    ft.plan_mode = 64 -- FFTW_ESTIMATE
    ft.execute = fftw.fftw_execute

    ft.real_data_t = "double*"
    ft.complex_data_t = "double(*)[2]"
    ft.complex_t = "double*"

    return ft
end)()

function rt.MonitoredAudioPlayback:_signal_to_spectrum(data, offset, window_size, n_bins)
    -- initialize
    if window_size ~= self._window_size or n_bins ~= self._n_bins then
        self._window_size = window_size
        self._n_bins = n_bins

        -- initialize fourier transform
        self.transform = {
            window_size = window_size,
            fourier_normalize_factor = 1 / math.sqrt(window_size),
            fftw_real = self.ft.alloc_real(window_size),
            fftw_complex = self.ft.alloc_complex(window_size),
            plan_signal_to_spectrum = {},
            bins = {}
        }

        tf = self.transform

        tf.plan_signal_to_spectrum = self.ft.plan_dft_r2c_1d(
            window_size,
            tf.fftw_real,
            tf.fftw_complex,
            self.ft.plan_mode
        )

        tf.plan_spectrum_to_signal = self.ft.plan_dft_c2r_1d(
            window_size,
            tf.fftw_complex,
            tf.fftw_real,
            self.ft.plan_mode
        )

        local sample_rate = self._data:getSampleRate()

        -- initialize mel frequency filter bank
        function mel_to_hz(mel)
            return 700 * (10^(mel / 2595) - 1)
        end

        function hz_to_mel(hz)
            return 2595 * math.log10(1 + (hz / 700))
        end

        function bin_to_hz(bin_i)
            -- src: https://dsp.stackexchange.com/a/75802
            return (bin_i - 1) * sample_rate / (window_size / 2)
        end

        function hz_to_bin(hz)
            return math.round(hz / (sample_rate / (window_size / 2)) + 1)
        end

        local n_mel_filters = n_bins
        local bin_i_center_frequency = {}
        local mel_lower = 0
        local mel_upper = hz_to_mel(self._cutoff_frequency)
        for mel in step_range(mel_lower, mel_upper, (mel_upper - mel_lower) / n_mel_filters) do
            table.insert(bin_i_center_frequency, hz_to_bin(mel_to_hz(mel)))
        end

        for i = 2, #bin_i_center_frequency - 1 do
            local left, center, right = bin_i_center_frequency[i-1], bin_i_center_frequency[i], bin_i_center_frequency[i+1]
            table.insert(tf.bins, {
                math.floor(left), --mix(left, center, 0.5)),
                math.floor(right) --mix(center, right, 0.5))
            })
        end

        tf.bins[1][1] = 1
        tf.bins[#(tf.bins)][2] = bin_i_center_frequency[#bin_i_center_frequency]
    end

    tf = self.transform

    local data_n = data:getSampleCount() * data:getChannelCount()
    local data_ptr = ffi.cast(self._data_t .. "*", self._data:getFFIPointer())

    local from = ffi.cast(self.ft.real_data_t, tf.fftw_real)
    local to = ffi.cast(self.ft.complex_data_t, tf.fftw_complex)

    local bit_depth = self._data:getBitDepth()
    local normalize
    if bit_depth == 16 then
        normalize = function(x)
            return x / (2^16 / 2 - 1)
        end
    else
        normalize = function(x)
            return (x + 2^8) / (2^8 - 1)
        end
    end

    local signal = {}
    -- convert audio signal to doubles
    if self._data:getChannelCount() == 1 then
        for i = 1, window_size do
            if offset + i < data_n then
                signal[i - 1] = normalize(data_ptr[offset + i - 1])
            else
                signal[i - 1] = 0
            end
        end
    else -- stereo
        for i = 1, window_size * 2, 2 do
            local index = offset * 2 + i - 1
            local index_out = math.floor((i - 1) / 2)

            if offset + index < data_n then
                local left = normalize(data_ptr[index + 0])
                local right = normalize(data_ptr[index + 1])
                signal[index_out] = left + right / 2.0
            else
                signal[index_out] = 0
            end
        end
    end

    local hann_alpha = 0.5
    local hamming_alpha = 25 / 46
    -- https://en.wikipedia.org/wiki/Window_function#Hann_and_Hamming_windows
    function cosine_windowing(n, alpha)
        return alpha - (1 - alpha) * math.cos((2 * math.pi * n) / (window_size - 1))
    end

    function flattop_windowing(n)
        -- https://www.mathworks.com/help/signal/ref/flattopwin.html
        local a0, a1, a2, a3, a4 = 0.21557895, 0.41663158, 0.277263158, 0.083578947, 0.006947368
        local pi = math.pi
        return a0 - a1 * math.cos(2 * pi * n / (window_size - 1)) + a2 * math.cos(4 * pi * n / (window_size - 1)) + a3 * math.cos(6 * pi * n / (window_size - 1)) + a4 * math.cos(8 * pi * n / (window_size - 1))
    end

    -- pre-emphasize high frequencies, first order high pass filter
    local highpass_factor = 0.98;
    from[0] = signal[0]
    for i = 1, window_size - 1 do
        from[i] = highpass_factor * (from[i - 1] + signal[i] - signal[i - 1])
        from[i] = from[i] * flattop_windowing(i, hann_alpha)
    end

    -- fouier transform
    self.ft.execute(tf.plan_signal_to_spectrum)

    -- convert complex to magnitude, also take first half only and flip
    local half = math.floor(0.5 * window_size)
    local normalize_factor = tf.fourier_normalize_factor

    -- discard frequencies above cutoff
    half = math.round(self._cutoff_frequency / (self._data:getSampleRate() / (window_size / 2)) + 1)
    local magnitudes = {}
    for i = 1, half do
        local complex = ffi.cast(self.ft.complex_t, to[half - i - 1])
        local magnitude = rt.magnitude(complex[0], complex[1])
        magnitude = magnitude * normalize_factor -- project into [0, 1]
        table.insert(magnitudes, magnitude)
    end

    local coefficients = {}
    local total_energy = 0
    for bin_i, bin in ipairs(tf.bins) do
        local sum = 0
        local n = 1
        local width = bin[2] - bin[1]
        for i = bin[1], bin[2] do
            if i > 0 and i <= #magnitudes then
                sum = sum + magnitudes[i]
                n = n + 1
            end
        end
        sum = sum / n
        total_energy = total_energy + sum
        table.insert(coefficients, sum)
    end

    return coefficients, total_energy
end

--- @brief
function rt.MonitoredAudioPlayback:start()
    self._is_playing = true
    self._source:play()
end

--- @brief
function rt.MonitoredAudioPlayback:stop()
    self._is_playing = false
    self._source:stop()
end

--- @brief
function rt.MonitoredAudioPlayback:update()
    if self._last_update == -1 then self._last_update = love.timer.getTime() end

    local function round(n)
        if self._data:getChannelCount() == 2 then
            return n + 2 - (n + 2) % 4
        else
            return n + (2 - n % 2) % 2
        end
    end

    if self._source:getFreeBufferCount() > 0 then
        local n_samples_to_push = math.min(
            round(self._data:getSampleRate() * 3 / 60),  -- push 4 frames worth of data each frame
            clamp(self._data:getSampleCount() * self._data:getChannelCount() - self._buffer_offset)
        )
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
            self._is_playing = true
            self._buffer_offset = self._buffer_offset + n_samples_to_push
        else
            self._is_playing = false
            self._buffer_offset = self._data:getSampleCount()
        end
    end

    if self._is_playing then
        local delta = love.timer.getTime() - self._last_update
        self._is_playing_offset = self._is_playing_offset + delta * self._data:getSampleRate()
    end

    self._last_update = love.timer.getTime()
end

--- @brief get spectrum of last window_size samples
function rt.MonitoredAudioPlayback:get_current_spectrum(window_size, n_mel_frequencies)
    n_mel_frequencies = math.round(which(window_size / 16))
    return self:_signal_to_spectrum(self._data, clamp(self._is_playing_offset, 0), window_size, n_mel_frequencies)
end



