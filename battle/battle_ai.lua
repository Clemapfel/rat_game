--- @brief
function rt.GameState:entity_choose_move(user, ai_level)
    meta.assert_is(user, bt.Entity)
    meta.assert_enum(ai_level, bt.AILevel)

    local enemies, allies
    if user:get_is_enemy() == true then
        enemies = self:list_party()
        allies = self:list_enemies()
    else
        enemies = self:list_enemies()
        allies = self:list_party()
    end

    local all = state:list_entities()

    local options = {}
    for slot_i, move in pairs(self:entity_list_move_slots(user)) do
        local is_disabled = self:entity_get_move_is_disabled(user, slot_i)
        local n_left = move:get_max_n_uses() - self:entity_get_move_n_used()
        if n_left > 0 and is_disabled == false then
            local to_push = {
                move = move,
                targets = {}
            }

            local can_target_enemies = move:get_can_target_enemies()
            local can_target_allies = move:get_can_target_allies()
            local can_target_self = move:get_can_target_self()
            if move:get_can_target_multiple() then
                local valid_targets = {}
                for entity in values(all) do
                    if entity == user and can_target_self or
                        entity:get_is_enemy() == user:get_is_enemy() and can_target_allies or
                        entity:get_is_enemy() ~= user:get_is_enemy() and can_target_enemies
                    then
                        table.insert(valid_targets, entity)
                    end
                end

                table.insert(to_push.targets, valid_targets)
            else

            end
        end
    end
end