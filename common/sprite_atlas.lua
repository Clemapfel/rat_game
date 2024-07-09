rt.settings.sprite_atlas = {
    default_fps = 12
}

--- @class rt.SpriteAtlasEntry
rt.SpriteAtlasEntry = meta.new_type("SpriteAtlasEntry", function(path, id)
    return meta.new(rt.SpriteAtlasEntry, {
        id = id,
        path = path,
        texture = {},  -- rt.Texture
        data = {},     -- love.ImageData
        fps = rt.settings.sprite_atlas.default_fps,
        n_frames = -1,
        frame_width = -1,
        frame_height = -1,
        origin_x = 0.5,
        origin_y = 0.5,
        frame_to_name = {},     -- Table<Number, String>
        name_to_frame = {},     -- Table<String, Number>
        texture_rectangles = {}, -- Table<rt.AABB>
        is_realized = false,
    })
end)

--- @brief
function rt.SpriteAtlasEntry:get_id()
    return self.id
end

--- @brief
function rt.SpriteAtlasEntry:load()
    if self.is_realized == true then return end

    -- load image data
    local image_path = self.path .. "/" .. self.id .. ".png"
    local image_path_info = love.filesystem.getInfo(image_path)

    if image_path_info == nil then
        rt.error("In rt.SpriteAtlasEntry:realize: unable to load image at `" .. image_path .. "`")
    end

    local data = love.image.newImageData(image_path)
    local config_path = self.path .. "/" .. self.id .. ".lua"
    local config_path_info = love.filesystem.getInfo(config_path)

    -- load animation config
    local config = {}
    if config_path_info ~= nil then
        local source = love.filesystem.load(config_path)
        local error_maybe
        config, error_maybe = source()
        if error_maybe ~= nil then
            rt.error("In rt.SpriteAtlasEntry:realize: unable to load sprite config file at `" .. config_path .. "`")
        end
    end

    -- deduce width or n_frames if one but not the other is available
    config.name = which(config.name, self.id)
    if config.width ~= nil and config.n_frames == nil then
        config.n_frames = data:getWidth() / config.width
        if fract(config.n_frames) ~= 0 then
            rt.error("In rt.SpriteAtlasEntry:load: incorrect frame width for sprite at `" .. image_path .. "`: image of size `" .. data:getWidth() .. "` is not vidibles by number of frames `" .. config.n_frames .. "`")
        end
    elseif config.n_frames ~= nil and config.width == nil then
        config.width = data:getWidth() / config.n_frames
        if fract(config.width) ~= 0 then
            rt.error("In rt.SpriteAtlasEntry:load: incorrect frame width for sprite at `" .. image_path .. "`: image of size `" .. data:getWidth() .. "` is not vidibles by number of frames `" .. config.n_frames .. "`")
        end
    else
        if config.animations ~= nil then
            config.n_frames = NEGATIVE_INFINITY
            for pair in values(config.animations) do
                if meta.is_number(pair) then
                    pair = {pair, pair}
                end
                config.n_frames = math.max(config.n_frames, pair[1], pair[2])
            end
            config.width = data:getWidth() / config.n_frames
        else
            -- treat entire spritesheet as frame
            config.width = data:getWidth()
            config.height = data:getHeight()
            config.n_frames = 1
        end
    end
    config.height = which(config.height, data:getHeight())

    if not meta.is_nil(config.fps) and config.fps > 0 then
        self.fps = config.fps
    end

    self.frame_width = config.width
    self.frame_height = config.height


    local min_frame_i = POSITIVE_INFINITY
    local max_frame_i = NEGATIVE_INFINITY
    local frames_seen = {}

    if config.animations == nil then
        config.animations = {
            ["default"] = { 1, config.n_frames }
        }
    end

    for key, value in pairs(config.animations) do
        if meta.is_number(value) then
            min_frame_i = math.min(min_frame_i, value)
            max_frame_i = math.max(max_frame_i, value)
            frames_seen[key] = true
        else
            table.sort(value)
            min_frame_i = math.min(min_frame_i, value[1])
            max_frame_i = math.max(max_frame_i, value[2])

            for i = value[1], value[2] do
                frames_seen[i] = true
            end
        end
    end

    self.n_frames = 0
    for _ in pairs(frames_seen) do
        self.n_frames = self.n_frames + 1
    end

    self.origin_x = which(config.origin_x, 0.5)
    self.origin_y = which(config.origin_y, 0.5)
    meta.assert_number(self.origin_x, self.origin_y)

    -- initialize
    self.data = data
    self.texture = rt.Texture(self.data)

    local function add_frame(name, index)
        if self.frame_to_name[index] ~= nil then
            rt.error("In rt.SpriteAtlasEntry:realize: animation at `" .. config_path .. "` maps both `" .. name .. "` and `" .. self.frame_to_name[index] .. "` to index " .. index)
        end

        self.frame_to_name[index] = name

        if self.name_to_frame[name] == nil then
            self.name_to_frame[name] = {index, index}
        else
            local current = self.name_to_frame[name]
            if index < current[1] - 1 or index > current[2] + 1 then
                rt.error("In rt.SpriteAtlasEntry:realize: animation at `" .. config_path .. "` specifies non-consecutive frame range for animation with `" .. name .. "`")
            end

            current[1] = math.min(index, current[1])
            current[2] = math.max(index, current[2])
        end
        self.texture_rectangles[index] = rt.AABB(
                (index - 1) / self.n_frames, 0,
                1 / self.n_frames, 1
        )
    end

    for key, value in pairs(config.animations) do
        if meta.is_number(value) then
            add_frame(key, value)
        else
            local left = value[1]
            local right = value[2]
            if left == right then
                add_frame(key, left)
            else
                for i = left, right do
                    add_frame(key, i)
                end
            end
        end
    end

    for i = 1, self.n_frames do
        if self.frame_to_name[i] == nil or self.frame_to_name[i] == "" then
            rt.error("In rt.SpriteAtlasEntry:realize: animation at `" .. config_path .. "` does not assign an animation id to frame #" .. tostring(i))
        end
    end

    assert(#self.frame_to_name == #self.texture_rectangles)
    self.is_realized = true
end

-- @brief
function rt.SpriteAtlasEntry:get_texture()
    return self.texture
end

--- @brief
function rt.SpriteAtlasEntry:get_frame_size()
    return self.frame_width, self.frame_height
end

--- @brief
function rt.SpriteAtlasEntry:get_fps()
    return self.fps
end

--- @brief
--- @return rt.AABB
function rt.SpriteAtlasEntry:get_frame(index)
    if meta.typeof(index) == "string" then
        index = self.name_to_frame[index][1]
    end

    local out = self.texture_rectangles[index]
    if out == nil then
        rt.error("In rt.SpriteAtlasEntry:get_frame: animation `" .. self.path .. "/" .. self.id .. "` does not have frame `" .. index .. "`")
    end
    return out
end

--- @brief
function rt.SpriteAtlasEntry:get_n_frames()
    return #self.frame_to_name
end

--- @brief
function rt.SpriteAtlasEntry:get_frame_range(id)
    local out = self.name_to_frame[id]
    if out == nil then
        rt.error("In rt.SpriteAtlasEntry: spritesheet at `" .. self.path .. "` has no animation with id `" .. id .. "`")
    end
    return out
end

--- @brief
function rt.SpriteAtlasEntry:has_frame(id)
    return self.name_to_frame[id] ~= nil
end

--- @class rt.SpriteAtlas
rt.SpriteAtlas = meta.new_type("SpriteAtlas", function()
    return meta.new(rt.SpriteAtlas, {
        _folder = "",
        _data = {}  -- Table<ID, rt.SpriteAtlasEntry>
    })
end)

--- @brief
function rt.SpriteAtlas:initialize(folder)
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
                if seen[filename] ~= true then
                    if extension == "png" then
                        local id = prefix .. "/" .. name
                        if self._data[id] == nil then
                            self._data[id] = rt.SpriteAtlasEntry(prefix, name)
                            seen[filename] = true
                        end
                    end
                end
            end
        end
    end

    parse(self._folder)
end

--- @brief
function rt.SpriteAtlas:get(id)
    local out = self._data[self._folder .. "/" .. id]
    if meta.is_nil(out) then
        rt.warning("In rt.SpriteAtlas: no spritesheet with id `" .. id .. "`")
        return self._fallback
    end

    if out.is_realized == false then
        out:load()
    end
    return out
end

-- initialize global singleton
rt.SpriteAtlas = rt.SpriteAtlas()
rt.SpriteAtlas:initialize("assets/sprites")