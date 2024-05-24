--[[
Nodes:
+ Single Enemy
+ Single Ally
+ Ally Enemies
+ All Allies
+ Everyone
+ Field
]]--

bt.SelectionHandler = meta.new_type("BattleSelectionHandler", function(scene)
    return meta.new(bt.SelectionHandler, {
        _scene = scene,
        _nodes = {}
    })
end)

--- @param entities Table<Table<bt.Entity>>
function bt.SelectionHandler:_construct_graph_from(entities)
    self._nodes = {}

    for group in values(entities) do
        local sprites = {}
        for entity in values(group) do
            table.insert(sprites, self._scene._ui:get_sprite(entity))
        end
        table.insert(self._nodes, {
            entities = group,
            sprites = sprites
        })
    end
end

--- @brief [internal]
function bt.SelectionHandler:_draw_node(node)

end