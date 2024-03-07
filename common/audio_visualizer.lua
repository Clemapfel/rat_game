rt.settings.audio_visualizer = {
    n_queueable_source_buffers = 3,
    default_window_size = 2^11,
    default_frequency_cutoff = 11000, -- Hz
    pre_emphasis_factor = 0.8
}

--- @brief
rt.AudioVisualizer = meta.new_type("AudioVisualizer", function(audio_file, config)
    
    -- algorithm configuration
    config = which(config, {})
    config.window_size = which(config.window_size, rt.settings.audio_visualizer.default_window_size)
    config.n_mel_frequency_bins = which(config.window_size / 16)
    config.frequency_cutoff = which(config.frequency_cutoff, rt.settings.audio_visualizer.default_frequency_cutoff)

    local data = love.sound.newSoundData(audio_file)
    local fftw = ffi.load(which(config.fftw3_path, "fftw3"))
    ffi.cdef([[
        extern double* fftw_alloc_real(size_t n);
        extern void* fftw_alloc_complex(size_t n);
        extern void* fftw_plan_dft_r2c_1d(int n, double* in, void* out, unsigned int flags);
        extern void* fftw_plan_dft_c2r_1d(int n, void* in, double* out, unsigned int flags);
        extern void fftw_execute(const void* plan);
    ]])
    
    local self = meta.new(rt.AudioVisualizer, {
        _config = config,

        _data = data,
        _data_t = ternary(data:getBitDepth() == 16, "int16_t", "uint8_t"),

        _source = love.audio.newQueueableSource(
            data:getSampleRate(),
            data:getBitDepth(),
            data:getChannelCount(),
            rt.settings.audio_visualizer.n_queueable_source_buffers
        ),
        
        _buffer_offset = 0,     -- position of already queued buffers
        _is_playing_offset = 0,    -- position of currently playing sample
        _last_update = -1,
        _n_transformed = 0,         -- number of samples processed by fourier transform
        _window_size = config.window_size, -- window used for queueing audio and fourier transform
        _is_playing = false,
        
        _fftw = {
            lib = fftw,
            alloc_real = fftw.fftw_alloc_real,
            alloc_complex = fftw.fftw_alloc_complex,
            plan_dft_r2c_1d = fftw.fftw_plan_dft_r2c_1d,
            plan_dft_c2r_1d = fftw.fftw_plan_dft_c2r_1d,
            plan_mode = 64, -- FFTW_ESTIMATE
            execute = fftw.fftw_execute,
        
            real_data_t = "double*",
            complex_data_t = "double(*)[2]",
            complex_t = "double*"
        },

        _transform = {},
        _mel_compression = {},
        _debug_draw = {},
        _on_update = nil
    })
    
    return self
end)

--- @brief
function rt.AudioVisualizer:play()
    self._is_playing = true
end

--- @brief
function rt.AudioVisualizer:pause()
    self._is_playing = false
end

--- @brief
function rt.AudioVisualizer:stop()
    self._is_playing = false
    self._buffer_offset = 0
    self._is_playing_offset = 0
    self._n_transformed = 0
end

--- @brief
function rt.AudioVisualizer:update()
    if self._source:getFreeBufferCount() > 0 then
        local n_samples_to_push = self._data:getSampleCount() * self._data:getChannelCount() - self._buffer_offset
        if n_samples_to_push < 0 then n_samples_to_push = 0 end
        n_samples_to_push = math.min(self._config.window_size, n_samples_to_push)
        
        if n_samples_to_push ~= 0 then
            if self._is_playing then
                self._source:queue(
                    self._data:getPointer(),
                    self._buffer_offset * ffi.sizeof(self._data_t),
                    n_samples_to_push * ffi.sizeof(self._data_t),
                    self._data:getSampleRate(),
                    self._data:getBitDepth(),
                    self._data:getChannelCount()
                )
                self._source:play()
                self._is_playing = true
                self._buffer_offset = self._buffer_offset + n_samples_to_push
            end
        else
            self._is_playing = false
            self._buffer_offset = self._data:getSampleCount()
        end
    end

    if self._is_playing then
        local previous = self._last_update
        self._last_update = love.timer.getDelta()
        local delta = self._last_update - previous
        self._is_playing_offset = self._is_playing_offset + self._last_update * self._data:getSampleRate()

        while self._n_transformed <= self._is_playing_offset do
            if self.on_update ~= nil then
                self.on_update(self:_calulate_spectrum())
            end
            self._n_transformed = self._n_transformed + self._window_size
        end
    end
    self._last_update = love.timer.getTime()
end

--- @brief [internal]
--- @return
function rt.AudioVisualizer:_calulate_spectrum()

    -- initialize C-side memory
    if self._transform.window_size == nil or self._transform.window_size ~= self._config.window_size then
        local window_size = self._config.window_size
        self._transform = {
            window_size = window_size,
            fftw_real = self._fftw.alloc_real(window_size),
            fftw_complex = self._fftw.alloc_complex(window_size)
        }

        self._transform.plan_signal_to_spectrum = self._fftw.plan_dft_r2c_1d(
            window_size,
            self._transform.fftw_real,
            self._transform.fftw_complex,
            self._fftw.plan_mode
        )
    end

    function bin_to_hz(bin_i)
        -- cf. https://dsp.stackexchange.com/a/75802
        return (bin_i - 1) * self._data:getSampleRate() / (self._transform.window_size / 2)
    end

    function hz_to_bin(hz)
        return math.round(hz / (self._data:getSampleRate() / (self._transform.window_size / 2)) + 1)
    end

    -- initialize mel compression
    if self._mel_compression.n_bins == nil or self._mel_compression.n_bins ~= self._config.n_mel_frequency_bins then
        function mel_to_hz(mel)
            return 700 * (10^(mel / 2595) - 1)
        end

        function hz_to_mel(hz)
            return 2595 * math.log10(1 + (hz / 700))
        end

        self._mel_compression = {
            n_bins = self._config.n_mel_frequency_bins,
            bins = {}
        }

        local n_mel_filters = self._mel_compression.n_bins
        local bin_i_center_frequency = {}
        local mel_lower = 0
        local mel_upper = hz_to_mel(math.max(self._config.frequency_cutoff))
        for mel in step_range(mel_lower, mel_upper, (mel_upper - mel_lower) / n_mel_filters) do
            table.insert(bin_i_center_frequency, hz_to_bin(mel_to_hz(mel)))
        end

        for i = 2, #bin_i_center_frequency - 1 do
            local left, center, right = bin_i_center_frequency[i-1], bin_i_center_frequency[i], bin_i_center_frequency[i+1]

            if left < (#bin_i_center_frequency - 1) / 4 then
                -- for low frequencies, keep 1:1 or even n:1 ratio
                table.insert(self._mel_compression.bins, {left, left})
            else
                table.insert(self._mel_compression.bins, {
                    math.floor(mix(left, center, 0.5)),
                    math.floor(mix(center, right, 0.5))
                })
            end
        end

        local n = #self._mel_compression.bins
        self._mel_compression.bins[n][2] = bin_i_center_frequency[#bin_i_center_frequency]
        self._mel_compression.last_result = table.rep(0, #(self._mel_compression.bins))
    end

    local data_n = self._data:getSampleCount() * self._data:getChannelCount()
    local data_ptr = ffi.cast(self._data_t .. "*", self._data:getFFIPointer())
    local window_size = self._transform.window_size
    local offset = self._n_transformed

    -- convert audio signal to doubles
    local signal = {}
    local bit_depth = self._data:getBitDepth()
    local normalize

    if self._data:getBitDepth() == 8 then
        normalize = function(x)
            return (x - 2^8) / (2^8 - 1)
        end
    elseif self._data:getBitDepth() == 16 then
        normalize = function(x)
            return x / (2^16 / 2 - 1)
        end
    end

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

    -- C-side arrays
    local from = ffi.cast(self._fftw.real_data_t, self._transform.fftw_real)
    local to = ffi.cast(self._fftw.complex_data_t, self._transform.fftw_complex)

    -- pre-emphasize high frequencies with first order high pass filter while writing to C arrays
    local highpass_factor = rt.settings.audio_visualizer.pre_emphasis_factor;
    from[0] = signal[0]
    for i = 1, window_size - 1 do
        from[i] = highpass_factor * (from[i - 1] + signal[i] - signal[i - 1])
        -- cf. https://en.wikipedia.org/wiki/High-pass_filter#Algorithmic_implementation
    end

    -- apply fourier transform
    self._fftw.execute(self._transform.plan_signal_to_spectrum)

    -- discard upper half, including anything above frequency cutoff (in Hz)
    local half = math.round(hz_to_bin(self._config.frequency_cutoff))

    -- compute complex magnitude, apply mel compression
    local normalize_factor = 1 / math.sqrt(window_size) / highpass_factor

    local coefficients = {}
    local total_energy = 0

    local bass_energy = 0
    local mid_energy = 0
    local high_energy = 0

    for bin_i, bin in ipairs(self._mel_compression.bins) do
        local sum = 0
        local n = 1
        local width = bin[2] - bin[1]
        for i = bin[1], bin[2] do
            if i > 0 and i <= half  then
                local complex = ffi.cast(self._fftw.complex_t, to[half - i]) -- also flip
                local magnitude = rt.magnitude(complex[0], complex[1]) * normalize_factor
                sum = sum + magnitude
                n = n + 1
            end
        end
        sum = sum / n
        total_energy = total_energy + sum
        table.insert(coefficients, sum)
    end

    return coefficients
end
