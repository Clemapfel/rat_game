--- @class mn.InventorySceen
mn.InventoryScene = meta.new_type("InventoryScene", rt.Scene, function()
    return meta.new(mn.InventoryScene, {

        _entity_tab_bar = mn.TabBar(),
        _entity_pages = {},
        _entity_index = 1,



        _shared_list_index = mn.InventoryScene._shared_move
    })
end, {
    shared_move_list_index = 1,
    shared_consumable_list_index = 2,
    shared_equip_list_index = 3,
    shared_template_list_index = 4,

    _shared_list_sort_mode_order = {
        [mn.ScrollableListSortMode.BY_NAME] = mn.ScrollableListSortMode.BY_QUANTITY,
        [mn.ScrollableListSortMode.BY_QUANTITY] = mn.ScrollableListSortMode.BY_ID,
        [mn.ScrollableListSortMode.BY_ID] = mn.ScrollableListSortMode.BY_NAME,
    },
})