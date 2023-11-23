--- @class bt.Entity
bt.Entity = meta.new_type("Entity", function(id)
    return meta.new(bt.Action, {
        id = id
    })
end)

-- cleartext name
bt.Entity.name = ""

-- sprite ID for inventory portrait
bt.Entity.portrait_id = "default"

-- HP stat
bt.Entity.hp_base = 1
bt.Entity.hp_ev = 0
bt.Entity.hp_current = 1

-- ATK stat
bt.Entity.attack_base = 0
bt.Entity.attack_ev = 0

-- DEF stat
bt.Entity.defense_base = 0
bt.Entity.defense_ev = 0

-- SPD stat
bt.Entity.speed_base = 0
bt.Entity.speed_ev = 0

bt.Entity.moveset = rt.List()           -- List<bt.Move>
bt.Entity.permanent_moveset = rt.List() -- List<bt.Move>
bt.Entity.consumables = rt.List()       -- List<bt.Consumables>

-- equipment
bt.Entity.n_equip_slots = 2
bt.Entity.equipment = {}            -- index -> ID

