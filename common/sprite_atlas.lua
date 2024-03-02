rt.settings.sprite_atlas = {
    default_fps = 12
}

--- @class rt.SpriteShett
rt.SpriteAtlasEntry = meta.new_type("SpriteAtlasEntry", function(path, id)
    return meta.new(rt.SpriteAtlasEntry, {
        id = id,
        path = path,
        texture = {},  -- rt.Texture
        data = {},     -- love.ImageData
        n_frames = -1,
        frame_width = -1,
        frame_height = -1,
        frame_to_name = {},     -- Table<Number, String>
        name_to_frame = {},     -- Table<String, Number>
        texture_rectangles = {}, -- Table<rt.AABB>
        is_realized = false,
    })
end)

--- @brief
function rt.SpriteAtlasEntry:load()
    if self._is_realized == true then return end

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

    local width_available = config.width

    -- if unable to load, treat entire image as sprite
    config.name = which(config.name, self.id)
    config.width = which(config.width, data:getWidth())
    config.height = which(config.height, data:getHeight())

    if config.animations == nil then
        config.animations = {
            ["default"] = {1, 1}
        }
        config.n_frames = 1
    end

    local min_frame_i = POSITIVE_INFINITY
    local max_frame_i = NEGATIVE_INFINITY
    local frames_seen = {}
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

    -- initialize
    self.data = data
    self.texture = rt.Texture(self.data)

    local function add_frame(name, index)
        if self.frame_to_name[index] ~= nil or self.name_to_frame[name] ~= nil then
            rt.error("In rt.SpriteAtlasEntry:realize: animation at `" .. config_path .. "` maps both `" .. name .. "` and `".. self.frame_to_name[index] .. "` to index " .. index)
        end

        self.frame_to_name[index] = name
        self.name_to_frame[name] = index
        self.texture_rectangles[index] = rt.AABB(
            index / self.n_frames, 0,
                1 / self.n_frames, 1
        )
    end

    for key, value in pairs(config.animations) do
        if meta.is_number(value) then
            add_frame(key, value)
        else
            if #value == 2 and value[1] == value[2] then
                add_frame(key, value[1])
            else
                for _, frame_i in pairs(value) do
                    add_frame(key, frame_i)
                end
            end
        end
    end

    -- fill potential gaps
    for i = min_frame_i, max_frame_i do
        if self.frame_to_name[i] == nil then
            self.frame_to_name[i] = self.frame_to_name[i-1]
            self.name_to_frame[i] = self.name_to_frame[i-1]

            local before = self.texture_rectangles[i]
            self.texture_rectangles[i] = rt.AABB(
                before.x, before.y, before.width, before.height
            )
        end
    end

    self.is_realized = true
end

--- @class rt.SpriteAtlas
rt.SpriteAtlas = meta.new_type("SpriteAtlas", function(folder)
    return meta.new(rt.SpriteAtlas, {
        _folder = folder,

    })
end)

