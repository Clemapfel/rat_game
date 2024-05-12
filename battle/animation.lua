bt.Animation = meta.new_abstract_type("BattleAnimation", rt.Animation)

-- include all implementations
for _, name in pairs(love.filesystem.getDirectoryItems("battle/animations")) do
    if string.match(name, "%.lua$") ~= nil then
        local path = "battle.animations." .. string.gsub(name, "%.lua$", "")
        require(path)
    end
end