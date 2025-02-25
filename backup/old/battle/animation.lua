bt.Animation = meta.new_abstract_type("BattleAnimation", rt.Animation)

-- include all implementations
for folder in range("simulation", "moves") do
    for _, name in pairs(love.filesystem.getDirectoryItems("battle/animations/" .. folder)) do
        if string.match(name, "%.lua$") ~= nil then
            local path = "battle.animations." .. folder .. "." .. string.gsub(name, "%.lua$", "")
            require(path)
        end
    end
end