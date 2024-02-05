--- @class ow.Map
ow.Map = meta.new_type("Map", function(name, path_prefix)
    local out = meta.new(ow.Map, {
        _path_prefix = path_prefix,
        _name = name,
        _tilesets = {},     -- Table<ow.Tileset>
    })
    out:_create()
    return out
end)

--- @brief [internal]
function ow.Map:_create()
    local config_path = self._path_prefix .. "/" .. self._name .. ".lua"
    local chunk, error_maybe = love.filesystem.load(config_path)
    if not meta.is_nil(error_maybe) then
        rt.error("In ow.Map:create_from: Error when loading file at `" .. config_path .. "`: " .. error_maybe)
    end

    local x = chunk()

    self._n_tiles_width = x.width
    self._n_tiles_height = x.height
    self._tile_width = x.tilewidth
    self._tile_height = x.tileheight

    for _, tileset in pairs(x.tilesets) do
        meta.assert(not meta.is_nil(tileset.name))
        local to_push = ow.Tileset(tileset.name, self._path_prefix)
        to_push:set_id_offset(tileset.firstgid)
        table.insert(self._tilesets, to_push)
    end

    return self
end


