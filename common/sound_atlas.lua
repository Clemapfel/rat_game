--- @class rt.SourceTimeUnit
rt.SourceTimeUnit = meta.new_enum({
    SECONDS = "seconds",
    SAMPLES = "samples"
})

--- @class rt.SoundAtlasEntry
rt.SoundAtlasEntry = meta.new_type("SoundAtlasEntry", function(data)
    return meta.new(rt.SoundAtlasEntry, {
        path = path,
        id = id,
        data = data, -- love.AudioData
        source = love.audio.newSource(data, "stream"), -- love.Source
        is_realized = false,

        volume_factor = 1,
        state = rt.SoundPlaybackState.NOT_PLAYING,
        stop_on_0_volume = false,
        is_done = true,
        current_volume = 1,
        target_volume = 1,
    })
end, {
    fade_in_duration = 0.01,
    fade_out_duration = 0.01
})

--- @brief
function rt.SoundAtlasEntry:realize()
    if self._is_realized == true then return end

    local path = self.path .. "/" .. self.id .. "." .. self.suffix
    local success, source_maybe = pcall(function()
        return love.audio.newSource(path, "static")
    end)

    if not success then
        rt.error("In rt.SoundAtlasEntry.realize: error when loading file at path `" .. path .. "`: " .. source_maybe)
    end
    self.source = source_maybe
    self.is_realized = true
end

--- @brief
function rt.SoundAtlasEntry:update(delta)
    if self.source ~= nil and self.source:isPlaying() then

    end
end

--- @brief
function rt.SoundAtlasEntry:play()
    if self.source ~= nil then
        self.target_volume = 1
        self.stop_on_0_volume = false
        self.is_done = true
        self.source:play()
        self:update(0)
    end
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

    meta.make_weak(out._active, false, true)
    return out
end)

--- @brief
function rt.SoundAtlas:update(delta)
    rt.error("TODO")
end

--- @brief
function rt.SoundAtlas:initialize()
    local function parse(prefix, content)
        local items = love.filesystem.getDirectoryItems(prefix)
        for item in values(items) do
            local filename = prefix .. "/" .. item
            local type = love.filesystem.getInfo(filename).type
            local name, extension = rt.filesystem.get_name_and_extension(filename)
            if type == "directory" then
                local to_insert = {}
                content[name] = to_insert
                parse(filename, to_insert)
            elseif type == "file" and extension == "wav" or extension == "mp3" or extension == "ogg" then
                dbg(name, " ", filename)

                content[name] = {
                    data = nil, -- love.sound.SounData
                    is_realized = false,
                    path = filename
                }
            end
        end
    end

    self._data = {}
    parse(self._path, self._data)
end

--- @brief
function rt.SoundAtlas:play(id)
    local data_entry = self._data[id]
    if data_entry == nil then
        rt.warning("In rt.SoundAtlas: no sound with id `" .. id .. "`")
        return
    end

    if data_entry.is_realized == false then
        data_entry.data = love.sound.newSounddata(data_entry.path)
        data_entry.is_realized = true
    end

    local sound_entry = rt.SoundAtlasEntry(data_entry.data)
    table.insert(self._active_entries, )

    TODO entry has data, add new source if needed
end

rt.SoundAtlas = rt.SoundAtlas("assets/mother3_sfx")
rt.SoundAtlas:initialize()