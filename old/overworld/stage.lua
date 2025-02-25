rt.settings.overworld.stage = {

}

--- @class ow.Stage
ow.Stage = meta.new_type("Stage", rt.Widget, function(config)
    meta.assert_isa(config, ow.StageConfig)
    return meta.new(ow.Stage, {
        _config = config,
        _layers = {}
    })
end)

--- @override
function ow.Stage:realize()
    local n_layers = self._config:get_n_layers()
end

function ow.Stage:size_allocate(x, y, width, height)

end

--- @override
function ow.Stage:draw()

end
