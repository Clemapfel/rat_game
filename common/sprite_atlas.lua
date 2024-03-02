rt.settings.sprite_atlas = {
    default_fps = 12
}

--- @class rt.SpriteShett
rt.SpriteAtlasEntry = meta.new_type("SpriteAtlasEntry", function(path, id)
    return {
        id = id,
        path = path,
        texture = {},  -- rt.Texture
        data = {},     -- love.ImageData
        n_frames = -1,
        frame_width = -1,
        frame_height = -1,
        frame_to_name = {},
        name_to_frame = {},
        is_realized = false
    }
end)

--- @brief
function rt.SpriteAtlasEntry:load()
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
    config.height = which(config.height, data.getHeight())

    if config.n_frames == nil and width_available then
        config.n_frames = data:getWidth() / config.width
    else
        config.n_frames = 1
    end

    config.animations = {
        default = {1, 1}
    }

    -- initialize
    self.data = data
    self.texture = rt.Texture(self.data)

    local function add_frame(name, index)
        if self.frame_to_name[index] ~= nil or self.name_to_frame[name] ~= nil then
            rt.error("In rt.SpriteAtlasEntry:realize: animation at `" .. config_path .. "` maps both `" .. name .. "` and `".. self.frame_to_name[index] .. "` to index " .. index)
        end

        self.frame_to_name[index] = name
        self.name_to_frame[name] = index
        self.texture_rectangles = rt.AABB(index / self.n_frames, 0, 1 / self.n_frames, 1)
    end

    for key, value in pairs(config.animations) do
        if meta.is_number(value) then
            add_frame(key, value)
        else
            for _, frame_i in pairs(value) do
                add_frame(key, frame_i)
            end
        end
    end

    self.n_frames = #self.frame_to_name
    self.is_realized = true
end

--- @class rt.SpriteAtlas
rt.SpriteAtlas = meta.new_type("SpriteAtlas", function(folder)
    return meta.new(rt.SpriteAtlas, {
        _folder = folder,

    })
end)

