local is_first = true
local first = nil
local t = {}

--- @class bt.Entity
bt.Entity = meta.new_type("BattleEntity", function(config, multiplicity)
    meta.assert_isa(config, bt.EntityConfig)
    meta.assert_number(multiplicity)
    return meta.new(bt.Entity, {
        _config = config,
        _multiplicity = multiplicity
    })
end)

meta.get_instance_metatable(bt.Entity).__eq = function(a, b)
    return a:get_id() == b:get_id()
end

function bt.Entity:_get_suffixes()
    local n = self._multiplicity
    local id_suffix = ""
    local name_suffix = ""
    if n > 1 then
        name_suffix = "" .. utf8.char(n + 0x03B1 - 1) -- lowercase greek letters

        id_suffix = ""
        if n < 10 then id_suffix = id_suffix .. "0" end
        id_suffix = id_suffix .. tostring(n)
    end
    return id_suffix, name_suffix
end

--- @brief
function bt.Entity:get_id_suffix()
    local id_suffix, _ = self:_get_suffixes()
    return id_suffix
end

--- @brief
function bt.Entity:get_name_suffix()
    local _, name_suffix = self:_get_suffixes()
    return name_suffix
end

--- @brief
function bt.Entity:get_id()
    local id_suffix, _ = self:_get_suffixes()
    if utf8.size(id_suffix) > 0 then
        return self._config.id .. "_" .. id_suffix
    else
        return self._config.id
    end
end

--- @brief
function bt.Entity:get_name()
    local _, name_suffix = self:_get_suffixes()
    if utf8.size(name_suffix) > 0 then
        return self._config.name .. " " .. name_suffix
    else
        return self._config.name
    end
end

--- @brief
function bt.Entity:get_config()
    return self._config
end

--- @brief
function bt.Entity:get_multiplicity()
    return self._multiplicity
end
