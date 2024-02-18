rt.settings.audio_processor = {
    step_size = 2^12,
    export_prefix = "audio"
}

function rt.AudioProcessorFilter(window_size)
    local out = {}
    out.transform = rt.FourierTransform()
    local ft = out.transform

    out.data_in = ft._alloc_real(window_size)
    out.data_out = ft._alloc_complex(window_size)
    out.plan = ft._plan_dft_r2c_1d(
        window_size,
        out.data_in,
        out.data_out,
        ft._plan_mode
    )

    out.compute = function(self, from, offset, length)
        local from = ffi.cast("double*", from)
        local to = ffi.cast("double*", self.data_in)
        for i = offset, offset + length - 1, 1 do
            to[i] = from[i]
        end

        out.transform._execute(out.transform.plan)
    end

    return out
end

--- @class rt.AudioProcessor
rt.AudioProcessor = meta.new_type("AudioProcessor", rt.SignalEmitter, function(id, path)
    local data = love.sound.newSoundData(path .. "/" .. id)
    local step_size = rt.settings.audio_processor.step_size
    local out = meta.new(rt.AudioProcessor, {
        _id = id,
        _data = data,
        _signal = {},   -- love.ByteData<double>
        _source = love.audio.newQueueableSource(
            data:getSampleRate(),
            data:getBitDepth(),
            data:getChannelCount(),
            nil
        ),
        _playing = false,
        _playing_offset = 0,
        _step_size = step_size,
        _is_mono = data:getChannelCount() == 1,
        
        _filter = rt.AudioProcessorFilter(step_size)
    })

    if data:getChannelCount() > 2 then
        rt.error("In rt.AudioProcessor: audio file at `" .. path .. "` is neither mono nor stereo, more than 2 channels are not supported")
    end

    out:_initialize_data()
    out:signal_add("update")
    return out
end)

--- @brief [internal] pre-compute mono version of signal as C-doubles, to be used with fftw
function rt.AudioProcessor:_initialize_data()

    -- store computed version on disk to avoid doing the work every time
    local prefix = rt.settings.audio_processor.export_prefix
    if love.filesystem.getInfo(prefix) == nil then
        love.filesystem.createDirectory(prefix)
    end

    local export_path = prefix .. "/" .. self._id .. ""
    local info = love.filesystem.getInfo(export_path)

    if not meta.is_nil(info) then
        self._signal = love.data.newByteData(love.filesystem.read(export_path))
        return
    end

    -- cf. https://github.com/love2d/love/blob/main/src/modules/sound/wrap_SoundData.lua#L41
    local n_channels = self._data:getChannelCount()
    local n_samples = self._data:getSampleCount() / n_channels
    local bit_depth = self._data:getBitDepth()
    local sample_t = ternary(bit_depth == 16, "int16_t*", "uint8_t*")

    -- project into [-1, 1]
    local normalize = function(x)
        if bit_depth == 8 then
            return (x - 2^8) / (2^8 - 1)
        elseif bit_depth == 16 then
            return x / (2^16 / 2 - 1)
        end
    end

    if n_channels == 2 then
        self._signal = love.data.newByteData(n_samples / 2 * ffi.sizeof("double"))
        local data_in = ffi.cast(sample_t, self._data:getFFIPointer())
        local data_out = ffi.cast("double*", self._signal:getFFIPointer())
        for i = 0, n_samples - 2, 2 do
            local left = normalize(data_in[i + 0])
            local right = normalize(data_in[i + 1])
            data_out[i / 2] = ffi.cast("double", (left + right) / 2)
        end
    else
        self._signal = love.data.newByteData(n_samples * ffi.sizeof("double"))
        local data_in = ffi.cast(sample_t, self._data:getFFIPointer())
        local data_out = ffi.cast("double*", self._signal:getFFIPointer())
        for i = 0, n_samples - 1, 1 do
            data_out[i] = ffi.cast("double", normalize(data_in[i]))
        end
    end

    -- export
    local res = love.filesystem.write(export_path, self._signal:getString())
    if res == true then
        rt.log("[rt][INFO] In rt.AudioProcesser._initialize_data: exporting `" .. self._id .. "` to `" .. export_path .. "`")
    end
end

--- @brief
function rt.AudioProcessor:start()
    self._playing = true
end

--- @brief
function rt.AudioProcessor:stop()
    self._playing = false
end

once = true

--- @brief
function rt.AudioProcessor:update()
    if self._source:getFreeBufferCount() > 0 then

        self._source:queue(
            self._data:getPointer(),
            self._playing_offset,
            self._step_size,
            self._data:getSampleRate(),
            self._data:getBitDepth(),
            self._data:getChannelCount()
        )
        self._source:play()
        self._playing_offset = self._playing_offset + self._step_size
    end
end

