rt.settings.sound_effect_atlas = {

}

--- @class
rt.SoundAtlasEntry = meta.new_type("SoundAtlasEntry", function(path, id, suffix)
    return meta.new(rt.SoundAtlasEntry, {
        id = id,
        path = path,
        suffix = suffix,
        source = {}, -- love.Source
        is_realized = false
    })
end)

--- @brief
function rt.SoundAtlasEntry:load()
    if self._is_realized == true then return end

    local path = self.path .. "/" .. self.id .. "." .. self.suffix
    if rt.filesystem.exists(path) == false then
        rt.error("In rt.SoundAtlasEntry:load: path `" .. self.path .. "/" .. self.id .. ".[mp3, wave, ogg]` does not exist" )
    end

    self.source = love.audio.newSource(path, "static")
    self.is_realized = true
end

--- @class rt.SoundAtlas
rt.SoundAtlas = meta.new_type("SoundAtlas", function()  
    return meta.new(rt.SoundAtlas, {
        _folder = "",
        _data = {}, -- Table<ID, rt.SoundAtlasEntry>
    })
end)

--- @brief
function rt.SoundAtlas:initialize(folder)
    self._folder = folder
    self._data = {}
    
    local seen = {}
    local function parse(prefix)
        local names = love.filesystem.getDirectoryItems(prefix)
        for _, name in pairs(names) do
            local filename = prefix .. "/" .. name
            local info = love.filesystem.getInfo(filename)
            if info.type == "directory" then
                parse(filename)
            elseif info.type == "file" then
                local name, extension = rt.filesystem.get_name_and_extension(filename)
                if seen[name] ~= true then
                    if extension == "mp3" or extension == "wav" or extension == "ogg" then
                        local id = prefix .. "/" .. name
                        if self._data[id] == nil then
                            self._data[id] = rt.SoundAtlasEntry(prefix, name, extension)
                            println(id)
                            seen[name] = true
                        end
                    end
                end
            end
        end
    end

    parse(self._folder)
end

--- @brief [internal]
function rt.SoundAtlas:_get(id)
    local out = self._data[self._folder .. "/" .. id]
    if meta.is_nil(out) then
        rt.error("In rt.SoundAtlas: no spritesheet with id `" .. id .. "`")
    end

    if out.is_realized == false then
        out:load()
    end
    return out
end

--- @brief
function rt.SoundAtlas:play(id)
    local sound = self:_get(id)
    sound.source:play()
end

--- @brief
function rt.SoundAtlas:stop(id)
    local sound = self:_get(id)
    sound.source:stop()
end