-- @class bt.MoveToolip
bt.MoveTooltip = meta.new_type("MoveTooltip", function(move)
    meta.assert_isa(move, bt.MoveConfig)

    local target_text = {}
    local self = move.can_target_self
    local ally = move.can_target_ally
    local enemy = move.can_target_enemy

    if move.targeting_mode == bt.TargetingMode.SINGLE then
        if self then
            table.insert(target_text, "self")
        end

        if ally then
            table.insert(target_text, "or ally")
        end

        if enemy then
            table.insert(target_text, "or enemy")
        end
    elseif move.targeting_mode == bt.TargetingMode.MULTIPLE then
        if self and not ally and not enemy then
            rt.error("invali config:")
        elseif self and ally and not enemy then
            table.insert(target_text, "party")
        end
    end

    return meta.new(bt.MoveTooltip, {

    })
end)