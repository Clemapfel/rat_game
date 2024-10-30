do
    local _entity_id_to_color = {
        ["RAT"] = "PUPRLE",
        ["MC"] = "ORANGE",
        ["GIRL"] = "LILAC",
        ["WILDCARD"] = "NEON_RED",
        ["PROF"] = "LIGHT_BLUE",
        ["SCOUT"] = "YELLOW"
    }

    --- @brief format object name
    function bt.format_name(object)
        if meta.isa(object, bt.Entity) then
            local color = _entity_id_to_color[object:get_id()]
            if color == nil then color = "RED" end -- enemies
            return "<b><color=RED>" .. object:get_name() .. "</color></b>"
        elseif meta.isa(object, bt.Move) then
            return "<b><i>" .. object:get_name() .. "<i></b>"
        elseif meta.isa(object, bt.Consumable)
            or meta.isa(object, bt.Status)
            or meta.isa(object, bt.GlobalStatus)
            or meta.isa(object, bt.Equip)
        then
            return "<b><u>" .. object:get_name() .. "</u></b>"
        elseif meta.is_number(object) or meta.is_string(object) then
            return tostring(object)
        else
            rt.error("In bt.format_name: unhandled object type `" .. meta.typeof(object) .. "`")
        end
    end
end

do -- pre-load all immutable configs, parse description and replace with formatted names
    assert(bt.Status ~= nil and bt.Move ~= nil and bt.Equip ~= nil and bt.Consumable ~= nil and bt.GlobalStatus ~= nil)
    local _id_to_object = (function()
        local out = {}
        for path_type in range(
            {"statuses", bt.Status},
            {"moves", bt.Move},
            {"equips", bt.Equip},
            {"consumables", bt.Consumable},
            {"global_statuses", bt.GlobalStatus}
        ) do
            local path, type = table.unpack(path_type)
            for _, name in pairs(love.filesystem.getDirectoryItems("assets/configs/" .. path)) do
                local id = string.match(name, "^(.-)%.lua$") -- "NAME.lua" -> NAME
                if id ~= nil then
                    out[id] = type(id)
                end
            end
        end
        return out
    end)()

    local c = "$"
    local match_pattern = "%" .. c .. "([^%" .. c .. "]+)%" .. c -- $NAME$ -> NAME
    for object in values(_id_to_object) do
        meta.set_is_mutable(object, true)

        local str = object:get_description()
        for id in string.gmatch(str, match_pattern) do
            local other = _id_to_object[id]
            if other ~= nil then
                str = string.gsub(str, "%" .. c .. id .. "%" .. c, bt.format_name(other))
                table.insert(object.see_also, other)
            else
                rt.warning("In bt.format_description: object `" .. object:get_id() .. "`: cannot find reference `" .. id .. "` from description `" .. str .. "`" )
            end
        end

        object.description = str
        meta.set_is_mutable(object, false)
    end
end