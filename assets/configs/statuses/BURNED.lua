return {
    name = "Burn",
    description = "Halfs defense, deals 1/16th of user.hp at the end of each turn",
    flavor_text = "Flamin' Hot",

    sprite_id = "statuses",
    sprite_index = "BURNED",

    defense_factor = 0.5,

    on_gained = function(self, afflicted)
        local name = get_name(self)
        message(name .. " was set ablaze")
    end,

    on_lost = function(self, afflicted)
        local name = get_name(self)
        message(name .. " is no longer burning")
    end,

    on_already_present = function(self, afflicted)
        local name = get_name(self)
        message(name .. " is already burning")
    end
}