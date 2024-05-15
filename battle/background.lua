--- @class bt.Background
bt.Background = meta.new_abstract_type("BattleBackground", rt.Widget)

-- include all implementations
for _, name in pairs(love.filesystem.getDirectoryItems("battle/backgrounds")) do
    if string.match(name, "%.lua$") ~= nil then
        local path = "battle.backgrounds." .. string.gsub(name, "%.lua$", "")
        require(path)
    end
end

--- @override
function bt.Background:update(delta, spectrum)
    -- noop
end