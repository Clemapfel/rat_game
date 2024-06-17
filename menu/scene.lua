--[[
Entities:

    portraits tab bar
    HP
    tab bar
    name label
    moves / consumables / equips label

    list of items:
    Header: Name, AP, Type
        list of moves
            Icon, Name, Max Uses
        list of consumables
            Icon, Name
        list of equips
            Icon, Name, Type

    Verbose info

    Equip Slot
    Consumable Slot


]]--


--- @class mn.Scene
mn.Scene = meta.new_type("MenuScene", rt.Scene, function()

end)