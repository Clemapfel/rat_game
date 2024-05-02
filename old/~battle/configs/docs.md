# State (global)

```lua
meta {
    TODO
}

-- (Entity, Entity) -> Unsigned
get_weighted_attack(attacking_entity, defending_entity)


```

# GlobalStatus (bt.GlobalStatusInterface)

```lua
GlobalStatus {
    -- ### Instance Fields ### --
    
    id = "GLOBAL_STATUS_ID",        -- const String
    name = "Example Global Status", -- const String

    max_duration = POSITIVE_INFINITY, -- const Unsigned
    n_turns_elapsed = 0, -- const Unsigned
    is_silent = false,   -- const Boolean

    -- ### Instance Methods ### --
    
    get_id(self),       -- (GlobalStatus) -> String
    get_name(self),     -- (GlobalStatus) -> String
    get_is_silent(self),    -- (GlobalStatus) -> Boolean
    get_max_duration(self),     -- (GlobalStatus) -> Unsigned
    get_n_turns_elapsed(self),  -- (GlobalStatus) -> Unsigned
    
    -- ### Config Fields ### --

    id = "GLOBAL_STATUS_ID",        -- const String
    name = "Example Global Status", -- const String
    
    max_duration = POSITIVE_INFINITY, -- const Unsigned
    is_silent = false,   -- const Boolean
    
    description = "<no description>",   -- const String
    sprite_id = "",     -- const String
    sprite_index = 1,   -- const Union<String, Unsigned>

    -- (GlobalStatus, Table<Entity>) -> nil
    on_gained(self, all_entities),

    -- (GlobalStatus, Table<Entity>) -> nil
    on_lost(self, all_entities),

    -- (GlobalStatus, Table<Entity>) -> nil
    on_turn_start(self, all_entities),

    -- (GlobalStatus, Table<Entity>) -> nil
    on_turn_end(self, all_entities),

    -- (GlobalStatus, Entity, Unsigned) -> nil
    on_healing_received(self, entity, value),

    -- (GlobalStatus, Entity, Entity, Unsigned) -> nil
    on_healing_performed(self, entity, receiver, value),

    -- (GlobalStatus, Entity, Unsigned) -> nil
    on_damage_taken(self, entity, value),

    -- (GlobalStatus, Entity, Entity, Unsigned) -> nil
    on_damage_dealt(self, damage_dealer, damage_taker, value),

    -- (GlobalStatus, Entity, Status) -> nil
    on_status_gained(self, entity, status),

    -- (GlobalStatus, Entity, Status) -> nil
    on_status_lost(self, entity, status),

    -- (GlobalStatus, GlobalStatus, Table<Entity>) -> nil
    on_global_status_gained(self, global_status, all_entities),

    -- (GlobalStatus, GlobalStatus, Table<Entity>) -> nil
    on_global_status_lost(self, global_status, all_entities),

    -- (GlobalStatus, Entity) -> nil
    on_knocked_out(self, afflicted),

    -- (GlobalStatus, Entity) -> nil
    on_helped_up(self, entity),

    -- (GlobalStatus, Entity) -> nil
    on_killed(self, entity),

    -- (GlobalStatus, Entity, Entity) -> nil
    on_switch(self, entity_a, entity_b),

    -- (GlobalStatus, Entity, Move, Table<Entity>) -> nil
    on_move_used(self, entity, move, targets),

    -- (GlobalStatus, Entity, Consumable) -> nil
    on_consumable_consumed(self, entity, consumable),
}
```

# Status (bt.StatusInterface)

```lua
Status {
    -- ### Instance Fields ### --

    id = "STATUS_ID",        -- const String
    name = "Example Status", -- const String
    
    is_stun = false, -- const Boolean
    
    attack_offset = 0,   -- const Signed
    defense_offset = 0,  -- const Signed
    speed_offset = 0,    -- const Signed
    
    attack_factor = 1,   -- const Float >= 0
    defense_factor = 1,  -- const Float >= 0
    speed_factor = 1,    -- const Float >= 0

    damage_dealt_factor = 1,      -- const Float >= 0
    damage_received_factor = 1,   -- const Float >= 0
    healing_performed_factor = 1, -- const Float >= 0
    healing_received_factor = 1,  -- const Float >= 0
    
    damage_dealt_offset = 0,      -- const Unsigned
    damage_received_offset = 0,   -- const Unsigned
    healing_performed_offset = 0, -- const Unsigned
    healing_received_offset = 0,  -- const Unsigned
    
    max_duration = POSITIVE_INFINITY, -- const Unsigned
    is_silent = false,                -- const Boolean
    n_turns_elapsed = 0,              -- const Unsigned

    -- ### Instance Methods ### --
    
    get_id(self),   -- (Status) -> String
    get_name(self), -- (Status) -> String

    get_max_duration(self),     -- (Status) -> Unsigned
    get_is_silent(self),        -- (Status) -> Boolean
    get_n_turns_elapsed(self),  -- (Status) -> Unsigned

    get_attack_offset(self),        -- (Status) -> Unsigned
    get_attack_factor(self),        -- (Status) -> Float

    get_defense_offset(self),        -- (Status) -> Unsigned
    get_defense_factor(self),        -- (Status) -> Float

    get_speed_offset(self),        -- (Status) -> Unsigned
    get_speed_factor(self),        -- (Status) -> Float

    get_damage_dealt_offset(self),        -- (Status) -> Unsigned
    get_damage_dealt_factor(self),        -- (Status) -> Float

    get_damage_received_offset(self),        -- (Status) -> Unsigned
    get_damage_received_factor(self),        -- (Status) -> Float

    get_healing_performed_offset(self),        -- (Status) -> Unsigned
    get_healing_performed_factor(self),        -- (Status) -> Float
    
    get_healing_received_offset(self),          -- (Status) -> Unsigned
    get_healing_received_factor(self),          -- (Status) -> Float
    
    -- ### Config Fields ### --
    
    description = "<no description>",   -- String
    sprite_id = "",     -- String
    sprite_index = 1,   -- Union<String, Unsigned>

    id = "STATUS_ID",        -- const String
    name = "Example Status", -- const String

    attack_offset = 0,   -- Signed
    defense_offset = 0,  -- Signed
    speed_offset = 0,    -- Signed

    attack_factor = 1,   -- Float >= 0
    defense_factor = 1,  -- Float >= 0
    speed_factor = 1,    -- Float >= 0

    damage_dealt_factor = 1,      -- Float >= 0
    damage_received_factor = 1,   -- Float >= 0
    healing_performed_factor = 1, -- Float >= 0
    healing_received_factor = 1,  -- Float >= 0

    damage_dealt_offset = 0,      -- Signed
    damage_received_offset = 0,   -- Signed
    healing_performed_offset = 0, -- Signed
    healing_received_offset = 0,  -- Signed

    is_stun = false, -- const Boolean
    max_duration = POSITIVE_INFINITY, -- const Unsigned
    is_silent = false,                -- const Boolean

    -- (Status, Entity) -> nil
    on_gained(self, afflicted),
    
    -- (Status, Entity) -> nil
    on_lost(self, afflicted),
    
    -- (Status, Entity) -> nil
    on_turn_start(self, afflicted),
    
    -- (Status, Entity) -> nil
    on_turn_end(self, affclited),

    -- (Status, Entity, Unsigned) -> nil
    on_healing_received(self, afflicted, value),

    -- (Status, Entity, Entity, Unsigned) -> nil
    on_healing_performed(self, afflicted, receiver, value),

    -- (Status, Entity, Unsigned) -> nil
    on_damage_taken(self, afflicted, value),

    -- (Status, Entity, Entity, Unsigned) -> nil
    on_damage_dealt(self, afflicted, damage_taker, value),

    -- (Status, Entity, Status) -> nil
    on_status_gained(self, afflicted, status),

    -- (Status, Entity, Status) -> nil
    on_status_lost(self, afflicted, status),

    -- (Status, Entity, GlobalStatus) -> nil
    on_global_status_gained(self, afflicted, global_status),

    -- (Status, Entity, GlobalStatus) -> nil
    on_global_status_lost(self, afflicted, global_status),

    -- (Status, Entity) -> nil
    on_knocked_out(self, afflicted),

    -- (Status, Entity) -> nil
    on_helped_up(self, afflicted),
    
    -- (Status, Entity) -> nil
    on_killed(self, afflicted),
    
    -- (Status, Entity, Entity) -> nil
    on_switch(self, afflicted, entity_at_old_position),

    -- (Status, Entity, Move, Table<Entity>) -> nil
    on_move_used(self, afflicted, move, targets),

    -- (Status, Entity, Consumable) -> nil
    on_consumable_consumed(self, afflicted, consumable), 
}
```

# Consumable (bt.ConsumableInterface)

```lua
Consumable {
    -- ### Instance Fields ### --
    
    id = "CONSUMABLE_ID",        -- const String
    name = "Example Consumable", -- const String

    max_n_uses = POSITIVE_INFINITY,   -- const Unsigned
    n_uses_left = POSITIVE_INFINITY,  -- const Unsigned
    is_silent = false,                -- const Boolean
    
    -- ### Instance Methods ### ---

    get_id(self),   -- (Consumable) -> String
    get_name(self), -- (Consumable) -> String

    get_is_silent(self),   -- (Consumable) -> Boolean
    get_max_n_uses(self),  -- (Consumable) -> Unsigned
    get_n_uses_left(self), -- (Consumable) -> Unsigned
    
    consume(self),  -- (Consumable) -> nil

    -- ### Config Fields ### --

    id = "CONSUMABLE_ID",        -- const String
    name = "Example Consumable", -- const String
    max_n_uses = POSITIVE_INFINITY,   -- const Unsigned
    is_silent = false,                -- const Boolean
    
    description = "<no description>",   -- String
    sprite_id = "",     -- String
    sprite_index = 1,   -- Union<String, Unsigned>

    -- (Consumable, Entity) -> nil
    on_turn_start(self, afflicted),

    -- (Consumable, Entity) -> nil
    on_turn_end(self, afflicted),

    -- (Consumable, Entity, Unsigned) -> nil
    on_healing_received(self, afflicted, value),

    -- (Consumable, Entity, Entity, Unsigned) -> nil
    on_healing_performed(self, afflicted, receiver, value),

    -- (Consumable, Entity, Unsigned) -> nil
    on_damage_taken(self, afflicted, value),

    -- (Consumable, Entity, Entity, Unsigned) -> nil
    on_damage_dealt(self, afflicted, damage_taker, value),

    -- (Consumable, Entity, Status) -> nil
    on_status_gained(self, afflicted, status),

    -- (Consumable, Entity, Status) -> nil
    on_status_lost(self, afflicted, status),

    -- (Consumable, Entity, GlobalStatus) -> nil
    on_global_status_gained(self, afflicted, global_status),

    -- (Consumable, Entity, GlobalStatus) -> nil
    on_global_status_lost(self, afflicted, global_status),

    -- (Consumable, Entity) -> nil
    on_knocked_out(self, afflicted),

    -- (Consumable, Entity) -> nil
    on_helped_up(self, afflicted),

    -- (Consumable, Entity) -> nil
    on_killed(self, afflicted),

    -- (Consumable, Entity, Entity) -> nil
    on_switch(self, afflicted, entity_at_old_position),

    -- (Consumable, Entity, Move, Table<Entity>) -> nil
    on_move_used(self, afflicted, move, targets),

    -- (Consumable, Entity, Consumable) -> nil
    on_consumable_consumed(self, afflicted, consumable),
}
```

# Entity (bt.EntityInterface)

```lua
Entity {
    -- ### Instance Fields ### --
    id = "EXAMPLE_ENTITY", -- const String
    name = "Example Entity", -- const String
    
    attack = 0,  -- const Unsigned
    defense = 0, -- const Unsigned
    speed = 0,   -- const Unsigned
    
    priority = 0, -- const Signed
    
    is_enemy = true, -- const Boolean
    
    -- ### Instance Methods ### --
    
    get_id_multiplicity(self), -- (Entity) -> 
    
    get_hp(self),
    get_hp_current(self),
    get_hp_base(self),
    
    get_attack(self), -- (Entity) -> Unsigned
    get_attack_base(self), -- (Entity) -> Unsigned
    get_attack_raw(self), -- (Entity) -> Unsigned
    get_attack_base_raw(self),

    get_defense(self), -- (Entity) -> Unsigned
    get_defense_base(self), -- (Entity) -> Unsigned
    get_defense_raw(self), -- (Entity) -> Unsigned
    get_defense_base_raw(self),

    get_speed(self), -- (Entity) -> Unsigned
    get_speed_base(self), -- (Entity) -> Unsigned
    get_speed_raw(self), -- (Entity) -> Unsigned
    get_speed_base_raw(self),
    
    get_priority(self),
    set_priority(self), -- TODO: when is priority resolved?
    
    get_is_stunned(self),
    add_status(self, status_id),
    remove_status(self, status_id),
    
    get_priority(self), -- (Entity) -> Signed
    
    get_is_knocked_out(self),
    get_is_dead(self),
    get_is_alive(self),
    get_is_enemy(self),

    list_statuses(self),
    list_equips(self),
    list_consumables(self),
    list_moves(self)
}
```

# Move (bt.MoveInterface)

```lua
Move {
    -- ### Instance Fields ### --
    
    id = "EXAMPLE_MOVE", -- const String
    name = "Example Move", -- const String
    
    max_n_uses = POSITIVE_INFINITY, -- const Unsigned
    -- n uses left is entity property
    
    can_target_multiple = false, -- const Boolean
    can_target_self = true,      -- const Boolean
    can_target_enemy = true,     -- const Boolean
    can_target_ally = true,      -- const Boolean
    
    priority = 0, -- const Signed
    
    -- ### Instance Methods ### --
    
    get_id(self),         -- (Move) -> String
    get_name(self),       -- (Move) -> String
    get_max_n_uses(self), -- (Move) -> Unsigned
    
    get_can_target_multiple(self), -- (Move) -> Boolean
    get_can_target_self(self),     -- (Move) -> Boolean
    get_can_target_enemy(self),    -- (Move) -> Boolean
    get_can_target_ally(self),     -- (Move) -> Boolean
    
    get_priority(self), -- (Move) -> Boolean

    -- ### Config Fields ### --

    id = "EXAMPLE_MOVE",   -- const String
    name = "Example Move", -- const String

    max_n_uses = POSITIVE_INFINITY, -- const Unsigned

    can_target_multiple = false, -- const Boolean
    can_target_self = true,      -- const Boolean
    can_target_enemy = true,     -- const Boolean
    can_target_ally = true,      -- const Boolean

    priority = 0, -- const Signed

    description = "<no description>",    -- String
    
    sprite_id = "",      -- String
    sprite_index = 1,    -- Union<String, Unsigned>
    animation_id = "",   -- String
    animation_index = 1, -- Union<String, Unsigned>
    
    -- (Move, Entity, Table<Entity>) -> nil
    effect(self, user, targets),
}
```

# Equip (bt.EquipInterface)

```lua
Equip {
    -- ### Instance Fields ### --

    id = "EXAMPLE_EQUIP",   -- const String
    name = "Example Equip", -- const String
    
    hp_base_offset = 0,      -- const Signed
    attack_base_offset = 0,  -- const Signed
    defense_base_offset = 0, -- const Signed
    speed_base_offset = 0,   -- const Signed
    
    hp_base_factor = 1,      -- const Float >= 0
    attack_base_factor = 1,  -- const Float >= 0
    defense_base_factor = 1, -- const Float >= 0
    speed_base_factor = 1,  -- const Float >= 0

    is_silent = true, -- const Boolean

    -- ### Instance Methods ### --

    get_id(self),         -- (Equip) -> String
    get_name(self),       -- (Equip) -> String
    get_is_silent(self),  -- (Equip) -> Boolean

    get_hp_base_offset(self),      -- (Equip) -> Signed
    get_attack_base_offset(self),  -- (Equip) -> Signed
    get_defense_base_offset(self), -- (Equip) -> Signed
    get_speed_base_offset(self),   -- (Equip) -> Signed

    get_attack_factor(self),  -- (Equip) -> Float
    get_defense_factor(self), -- (Equip) -> Float
    get_speed_factor(self),   -- (Equip) -> Float
    
    -- ### Config Fields ### --

    id = "EXAMPLE_EQUIP",   -- const String
    name = "Example Equip", -- const String

    hp_base_offset = 0,      -- const Signed
    attack_base_offset = 0,  -- const Signed
    defense_base_offset = 0, -- const Signed
    speed_base_offset = 0,   -- const Signed

    attack_factor = 1,  -- const Float >= 0
    defense_factor = 1, -- const Float >= 0
    speed_factor = 1,   -- const Float >= 0

    is_silent = true, -- const Boolean

    description = "<no description>",    -- String

    sprite_id = "",      -- String
    sprite_index = 1,    -- Union<String, Unsigned>

    -- (Equip, Entity) -> nil
    effect(self, holder),
}
```
