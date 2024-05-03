--- @class rt.Reference
rt.Reference = function(x)
    local out = {
        x = x
    }
    setmetatable(out, {
        __index = function(self)
            return nil
        end,

        __newindex = function(self, key, new_value)
            rt.error("In rt.Reference:__newindex: trying to set key `" .. key .. "` of reference, but references are immutable")
        end
    })
    return out
end