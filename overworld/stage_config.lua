rt.settings.overworld.stage_config = {
    config_path = "assets/stages"
}

--[[
expects Tiled stage
located at /assets/stages
stage size "infinite"
with non-injected tilesets
]]--

--- @class ow.StageConfig
ow.StageConfig = meta.new_type("StageConfig", function(id)
    local out = ow.StageConfig._atlas[id]
    if out == nil then
        out = meta.new(ow.StageConfig, {
            _id = id
        })
        out:realize()
        ow.StageConfig._atlas[id] = out
    end
    return out
end)
ow.StageConfig._atlas = {}

ow.LayerType = meta.new_enum("LayerType", {
    TILES = "tilelayer",
    OBJECTS = "objectlayer"
})

local function _decode_gid(gid)
    local true_id = bit.band(gid, 0x0FFFFFFF)
    local flip_x = 0 ~= bit.band(gid, 0x80000000)
    local flip_y = 0 ~= bit.band(gid, 0x40000000)
    return true_id, flip_x, flip_y
end

--- @brief
function ow.StageConfig:realize()
    local config_path_prefix = rt.settings.overworld.stage_config.config_path .. "/"
    local path = config_path_prefix .. self._id .. ".lua"

    local load_success, chunk_or_error, love_error = pcall(love.filesystem.load, path)
    if not load_success then
        rt.error("In rt.load_config: error when parsing stage at `" .. path .. "`: " .. chunk_or_error)
        return
    end

    if love_error ~= nil then
        rt.error("In rt.load_config: error when loading stage at `" .. path .. "`: " .. love_error)
        return
    end

    local chunk_success, config_or_error = pcall(chunk_or_error)
    if not chunk_success then
        rt.error("In rt.load_config: error when running stage at `" .. path .. "`: " .. config_or_error)
        return
    end

    local config = config_or_error

    local _get = function(t, name)
        local out = t[name]
        if out == nil then
            rt.error("In rt.load_config: trying to access property `" .. name .. "` of stage at `" .. path .. "`, but it does not exist")
        end
        return out
    end

    -- init tilesets
    self._tilesets = {}
    for tileset in values(_get(config, "tilesets")) do
        table.insert(self._tilesets, {
            id_offset = _get(tileset, "firstgid"),
            tileset = ow.TilesetConfig(_get(tileset, "name"))
        })
    end

    self._gid_to_tileset_tile = {}
    for entry in values(self._tilesets) do
        local offset = entry.id_offset
        for tile_id in values(entry.tileset:get_tile_ids()) do
            self._gid_to_tileset_tile[tile_id + offset] = {
                id = tile_id,
                tileset = entry.tileset
            }
        end
    end

    self._layer_i_to_layer = {}
    self._tile_layers = meta.make_weak({})
    self._object_layers = meta.make_weak({})

    local is_solid_name = rt.settings.overworld.tileset_config.is_solid_property_name

    local layer_i = 1
    for layer in values(_get(config, "layers")) do
        local to_add = {
            properties = {},
            is_visible = _get(layer, "visible"),
            name = _get(layer, "name"),
            n_columns = _get(layer, "width"),
            n_rows = _get(layer, "height"),
            x_offset = _get(layer, "offsetx"),
            y_offset = _get(layer, "offsety"),
            parallax_factor_x = _get(layer, "parallaxx"),
            parallax_factor_y = _get(layer, "parallaxy"),
        }

        self._layer_i_to_layer[layer_i] = to_add
        layer_i = layer_i + 1

        local layer_type = _get(layer, "type")
        if layer_type == "tilelayer" then
            to_add.type = ow.LayerType.TILES
            to_add.tile_id_matrix = {}

            if layer.chunks == nil then
                rt.error("In ow.StageConfig.realize: layer `" .. layer_i .. "` does not have `chunks` field, is this an infinite map?")
            end

            local is_solid_matrix = rt.Matrix()

            -- construct gid matrix
            local chunks = _get(layer, "chunks")
            for chunk in values(chunks) do
                local x_offset = _get(chunk, "x")
                local y_offset = _get(chunk, "y")
                local width = _get(chunk, "width")
                local height = _get(chunk, "height")
                local data = _get(chunk, "data")
                for y = 1, height do
                    for x = 1, width do
                        local gid = data[(y - 1) * width + x]
                        if gid ~= 0 then -- empty tile
                            assert(to_add.tile_id_matrix:get(x + x_offset, y + y_offset) == nil)
                            to_add.tile_id_matrix:set(x + x_offset, y + y_offset, gid)

                            local tile = self._gid_to_tileset_tile[gid]
                            local is_solid = tile.tileset:get_tile_property(tile.id, is_solid_name) == true

                            if is_solid then
                                is_solid_matrix:set(x + x_offset, y + y_offset, true)
                            end
                        end
                    end
                end
            end

            -- per-layer properties
            if layer.properties ~= nil then
                for key, value in pairs(_get(layer, "properties")) do
                    to_add.properties[key] = value
                end
            end
        elseif layer_type == "objectgroup" then
            to_add.type = ow.LayerType.OBJECTS
            to_add.objects = {}

            for object in values(_get(layer, "objects")) do

            end
        elseif layer_type == "imagelayer" then
            -- noop
        else
            rt.error("In ow.StageConfig.realize: unhandled layer type `" .. layer_type .. "` of stage at `" .. path .. "`")
        end
    end
end