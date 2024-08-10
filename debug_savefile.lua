local out = {}
--[[
{
    party[entity_id] = {
        moves[slot_i] = {
            move_id,
            n_times_used
        },

        equips[slot] = {
            equip_id,
        },

        consumables[slot_i] = {
            consumable_id,
            n_times_used
        }
    },

    shared_moves[move_id] = count,
    shared_equips[equip_id] = count,
    shared_consumables[consumable_id] = count
}
]]--

local moves = {
    "DEBUG_MOVE",
    "INSPECT",
    "PROTECT",
    "STRUGGLE",
    "SURF",
    "WISH"
}

local equips = {
    "DEBUG_EQUIP",
    "DEBUG_CLOTHING",
    "DEBUG_FEMALE_CLOTHING",
    "DEBUG_MALE_CLOTHING",
    "DEBUG_WEAPON",
    "DEBUG_TRINKET"
}

local consumables = {
    "DEBUG_CONSUMABLE",
    "ONE_CHERRY",
    "TWO_CHERRY"
}

out.party = {}
for party_i, party_id in ipairs("MC", "PROF", "GIRL", "RAT") do
    local entity = {
        index = party_i,
        moves = {},
        equips = {},
        consumables = {}
    }

    local config = bt.Entity(party_id)
    local possible_moves = rt.random.shuffle({table.unpack(moves)})
    local move_i = 1
    for i = 1, config:get_n_move_slots() do
        if rt.random.toss_coin(0.5) then
            entity.moves[i] = possible_moves[move_i]
            move_i = move_i + 1
            if move_i > #moves then break end
        end
    end

    for i = 1, config:get_n_equip_slots() do
        entity.equips[i] = equips[rt.random(1, #equips)]
    end

    for i = 1, config:get_n_equip_slots() do
        entity.equips[i] = equips[rt.random(1, #equips)]
    end

    out.party[party_id] = entity
end

local max_count = 99

out.shared_moves = {}
for move in values(moves) do
    out.shared_moves[move] = rt.random.integer(1, max_count)
end

out.shared_equips = {}
for equip in values(equips) do
    out.shared_equips[equip] = rt.random.integer(1, max_count)
end

out.shared_consumables = {}
for consumable in values(consumables) do
    out.shared_consumables[consumable] = rt.random.integer(1, max_count)
end

return out