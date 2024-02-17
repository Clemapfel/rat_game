rt.settings.audio_processor = {
    step_size = 2^12
}

--- @class rt.AudioProcessor
rt.AudioProcessor = meta.new_type("AudioProcessor", rt.SignalEmitter, function(path)
    local data = love.sound.newSoundData(path)
    local out = meta.new(rt.AudioProcessor, {
        _data = data,
        _source = love.audio.newQueueableSource(
            data:getSampleRate(),
            data:getBitDepth(),
            data:getChannelCount(),
            nil
        ),
        _playing = false,
        _playing_offset = 0,
        _step_size = rt.settings.audio_processor.step_size,

        _sample_t = ternary(data:getBitDepth() == 8, "uint8_t", "int16_t"),
        _is_mono = data:getChannelCount() == 1
    })

    if data:getChannelCount() > 2 then
        rt.error("In rt.AudioProcessor: audio file at `" .. path .. "` is neither mono nor stereo, more than 2 channels are not supported")
    end

    -- cf. https://github.com/love2d/love/blob/main/src/modules/sound/wrap_SoundData.lua#L41
    local mono_data = love.

    out:signal_add("update")
    return out
end)


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

        if once then
            local chunk = {}
            local data_chunk = {}
            local data = ffi.cast("int16_t*", self._data:getFFIPointer())
            for i = 1, self._step_size do
                table.insert(chunk, self._data:getSample(self._playing_offset + i))
                table.insert(data_chunk, data[self._playing_offset + i])
            end

            for i = 1, #chunk do
                println(chunk[i], " ", data_chunk[i] / (2^16 / 2), " ", chunk == data_chunk)
            end
            once = false
        end

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

