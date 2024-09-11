--- @class rt.SourceTimeUnit
rt.SourceTimeUnit = meta.new_enum({
    SECONDS = "seconds",
    SAMPLES = "samples"
})

--- @class rt.SoundAtlasEntry
--- @signal started (self) -> nil
--- @signal finished (self) -> nil
rt.SoundAtlasEntry = meta.new_type("SoundAtlasEntry", rt.SignalEmitter, function(path)
    local out = meta.new(rt.SoundAtlasEntry, {
        path = path,
        data = nil, -- love.AudioData
        sources = {}, -- Table<love.Source, { cf :play }>
        is_realized = false,
        volume_factor = 1,
        duration = 0,
    })

    out:signal_add("started")
    out:signal_add("finished")
end, {
    fade_in_duration = 1,
    fade_out_duration = 1
})

--- @brief
function rt.SoundAtlasEntry:update(delta)
    local fade_in_slope = 1 / self.fade_in_duration * delta
    local fade_out_slop = -1 / self.fade_out_duration * delta
    local sfx_volume = rt.settings.sfx_level
    for source, entry in pairs(self.sources) do
        if source:isPlaying() then
            if source:tell(rt.SourceTimeUnit.SECONDS) > self.duration - self.fade_out_duration then
                self.target_volume = 0
            end

            if entry.current_volume < entry.target_volume then
                entry.current_volume = entry.current_volume + fade_in_slope
                if entry.current_volume > 1 then
                    entry.current_volume = 1
                end
            elseif entry.current_volume > entry.target_volume then
                entry.current_volume = entry.current_volume - fade_out_slop
                if entry.current_volume < 0 then
                    entry.current_volume = 0
                    source:stop()
                end
            end
            dbg(entry.current_volume * self.volume_factor * sfx_volume)
            source:setVolume(entry.current_volume * self.volume_factor * sfx_volume)
        end
    end
end

--- @brief
function rt.SoundAtlasEntry:realize()
    if self.is_realized == true then return end
    self.data = love.sound.newSounddata(self.path)
    self.duration = self.data:getDuration()
end

--- @brief
function rt.SoundAtlasEntry:play()
    local source
    for source_maybe, source_data in pairs(self.sources) do
        if source_data.is_active == false then
            source = source_maybe
            source_data.is_active = true
            break
        end
    end

    if source == nil then
        source = love.audio.newSource(self.data)
        self.sources[source] = {
            is_active = true,
            current_volume = 0,
            target_volume = 1
        }
    else
        self.sources[source].is_active = true
        self.sources[source].target_volume = 1
    end

    source:play()
end

--- @brief
function rt.SoundAtlasEntry:stop()
    if self.source ~= nil then
        self.target_volume = 0
        self.stop_on_0_volume = true
        self:update(0)
    end
end

--- @brief
function rt.SoundAtlasEntry:is_done()
    return self.is_done
end

--- @class rt.SoundAtlas
rt.SoundAtlas = meta.new_type("SoundAtlas", function(path)
    local out = meta.new(rt.SoundAtlas, {
        _path = path,
        _data = {},  -- Table<EntryID, { data, is_realized, path }>
        _active_entries = {}    -- Table<rt.SoundAtlasEntry>
    })
    return out
end)

--- @brief
function rt.SoundAtlas:update(delta)
    for entry in self._active_entries do
        entry:update(delta)
    end
end

--- @brief
function rt.SoundAtlas:initialize()
    local function parse(prefix, data)
        local items = love.filesystem.getDirectoryItems(prefix)
        for item in values(items) do
            local filename = prefix .. "/" .. item
            local type = love.filesystem.getInfo(filename).type
            local name, extension = rt.filesystem.get_name_and_extension(filename)
            if type == "directory" then
                parse(filename, data)
            elseif type == "file" and extension == "wav" or extension == "mp3" or extension == "ogg" then
                local id_prefix = string.gsub(prefix, self._path .. "/?", "")
                if #id_prefix ~= 0 then
                    id_prefix = id_prefix .. "/"
                end
                data[id_prefix .. name] = rt.SoundAtlasEntry(filename)
            end
        end
    end

    self._data = {}
    parse(self._path, self._data)
end

--- @brief
function rt.SoundAtlas:play(id)
    local entry = self._data[id]
    if entry == nil then
        rt.warning("In rt.SoundAtlas: no sound with id `" .. id .. "`")
        return
    end

    if entry.is_realized == false then
        entry.data = love.sound.newSoundData(entry.path)
    end


    entry:play()
end

rt.SoundAtlas = rt.SoundAtlas("assets/sfx")
rt.SoundAtlas:initialize()