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
            return "<b><u>" .. object:get_name() .. "</u></b>"
        elseif meta.isa(object, bt.Consumable)
            or meta.isa(object, bt.Status)
            or meta.isa(object, bt.GlobalStatus)
            or meta.isa(object, bt.Equip)
        then
            return "<b><i>" .. object:get_name() .. "</i></b>"
        end
    end
end

do
    local _initialized = false
    local _id_to_object = {}

    --- @brief parse object description, injecting names and returning "see also" objects
    --- @return String, Table<any> formatted message, see_also
    function bt.format_description(object)
        if not _initialized then
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
                        _id_to_object[id] = type(id)
                    end
                end
            end

            _initialized = true
        end

        local c = "$"
        local str = object:get_description()
        local see_also = {}
        for id in string.gmatch(str, "%" .. c .. "([^%" .. c .. "]+)%" .. c) do -- $NAME$ -> NAME
            local other = _id_to_object[id]
            if other ~= nil then
                str = string.gsub(str, "%" .. c .. id .. "%" .. c, bt.format_name(other))
                table.insert(see_also, other)
            else
                rt.warning("In bt.format_description: object `" .. object:get_id() .. "`: cannot find reference `" .. id .. "` from description `" .. str .. "`" )
            end
        end

        return str, see_also
    end
end