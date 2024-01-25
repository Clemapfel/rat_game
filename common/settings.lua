rt.settings = {}
rt.settings.margin_unit = 10

do -- make settings automatically create sub tables if they do not yet exist
    local function make_auto_extend(x, recursive)
        if recursive == nil then recursive = false end
        local metatable = getmetatable(table)
        if metatable == nil then
            metatable = {}
            setmetatable(x, metatable)
        end

        if metatable.__index ~= nil then
            error("In make_auto_extend_table: table already has a metatable with an __index method")
        end

        metatable.__index = function(self, key)
            local out = {}
            self[key] = out

            if recursive then
                make_auto_extend(out, recursive)
            end
            return out
        end
    end
    make_auto_extend(rt.settings, true)
end



