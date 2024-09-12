--- @class rt.SourceTimeUnit
rt.SourceTimeUnit = meta.new_enum({
    SECONDS = "seconds",
    SAMPLES = "samples"
})

--- @class rt.SoundAtlas
rt.SoundAtlas = meta.new_type("SoundAtlas", function(path)
    local out = meta.new(rt.SoundAtlas, {
        _path = path,
        _data = {},  -- Table<EntryID, { data, is_realized, path }>
        _sound_components = {},
        _music_components = {}
    })
    meta.make_weak(out._sound_components, false, true)
    meta.make_weak(out._music_components, false, true)
    return out
end)

--- @brief
function rt.SoundAtlas:add_sound_component(component)
    self._sound_components[meta.hash(component)] = component
end

--- @brief
function rt.SoundAtlas:remove_sound_component(component)
    self._sound_components[meta.hash(component)] = nil
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
                data[id_prefix .. name] = {
                    data = nil,
                    path = filename,
                    is_realized = false,
                    origin_source = nil
                }
            end
        end
    end

    self._data = {}
    parse(self._path, self._data)
end

--- @brief
--- @return love.Source
function rt.SoundAtlas:get_source(id)
    local entry = self._data[id]
    if entry == nil then
        rt.warning("In rt.SoundAtlas: no sound with id `" .. id .. "`")
        return
    end

    if entry.is_realized ~= true then
        entry.data = love.sound.newSoundData(entry.path)
        entry.origin_source = love.audio.newSource(entry.data, "static")
        entry.is_realized = true
    end

    return entry.origin_source:clone()
end

--- @brief
function rt.SoundAtlas:update(delta)
    local unit = rt.SourceTimeUnit.SAMPLES
    for _, component in pairs(self._sound_components) do
        if component._native ~= nil then
            dbg(component._native:tell("samples"), component._native:getDuration("samples"))

                --component:signal_emit("finished")
                --component._is_active = false

        end
    end
end

rt.SoundAtlas = rt.SoundAtlas("assets/sfx")
rt.SoundAtlas:initialize()