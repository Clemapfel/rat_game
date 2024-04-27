# State (global)

```lua
meta {
    TODO
}
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
    
    description = "<no description>",   -- const String
    sprite_id = "",     -- const String
    sprite_index = 1,   -- const Union<String, Unsigned>

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_gained(self, all_entities),

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_lost(self, all_entities),

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_turn_start(self, all_entities),

    -- (GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_turn_end(self, all_entities),

    -- (GlobalStatusInterface, EntityInterface, Unsigned) -> nil
    on_healing_received(self, entity, value),

    -- (GlobalStatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_healing_performed(self, entity, receiver, value),

    -- (GlobalStatusInterface, EntityInterface, Unsigned) -> nil
    on_damage_taken(self, entity, value),

    -- (GlobalStatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_damage_dealt(self, damage_dealer, damage_taker, value),

    -- (GlobalStatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained(self, entity, status),

    -- (GlobalStatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_lost(self, entity, status),

    -- (GlobalStatusInterface, GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_global_status_gained(self, global_status, all_entities),

    -- (GlobalStatusInterface, GlobalStatusInterface, Table<EntityInterface>) -> nil
    on_global_status_lost(self, global_status, all_entities),

    -- (GlobalStatusInterface, EntityInterface) -> nil
    on_knocked_out(self, afflicted),

    -- (GlobalStatusInterface, EntityInterface) -> nil
    on_helped_up(self, entity),

    -- (GlobalStatusInterface, EntityInterface) -> nil
    on_killed(self, entity),

    -- (GlobalStatusInterface, EntityInterface, EntityInterface) -> nil
    on_switch(self, entity_a, entity_b),

    -- (GlobalStatusInterface, EntityInterface, MoveInterface, Table<EntityInterface>) -> nil
    on_move_used(self, entity, move, targets),

    -- (GlobalStatusInterface, EntityInterface, ConsumableInterface) -> nil
    on_consumable_consumed(self, entity, consumable),
}
```

# Status (bt.StatusInterface)

```lua
Status {
    -- ### Instance Fields ### --

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
    
    damage_dealt_offset = 0,      -- Unsigned
    damage_received_offset = 0,   -- Unsigned
    healing_performed_offset = 0, -- Unsigned
    healing_received_offset = 0,  -- Unsigned
    
    max_duration = POSITIVE_INFINITY, -- const Unsigned
    is_silent = false,                -- const Boolean
    n_turns_elapsed = 0,              -- const Unsigned

    -- ### Instance Methods ### --
    
    get_id(self),   -- (Status) -> String
    get_name(self), -- (Status) -> String

    get_max_duration(self),     -- (Status) -> Unsigned
    get_is_silent(self),        -- (Status) -> Boolean
    get_n_turns_elapsed(self),  -- (Status) -> Unsigned

    set_attack_offset(self, value), -- (Status, Unsigned) -> nil
    get_attack_offset(self),        -- (Status) -> Unsigned
    set_attack_factor(self, value), -- (Status, Float) -> nil
    get_attack_factor(self),        -- (Status) -> Float

    set_defense_offset(self, value), -- (Status, Unsigned) -> nil
    get_defense_offset(self),        -- (Status) -> Unsigned
    set_defense_factor(self, value), -- (Status, Float) -> nil
    get_defense_factor(self),        -- (Status) -> Float

    set_speed_offset(self, value), -- (Status, Unsigned) -> nil
    get_speed_offset(self),        -- (Status) -> Unsigned
    set_speed_factor(self, value), -- (Status, Float) -> nil
    get_speed_factor(self),        -- (Status) -> Float

    set_damage_dealt_offset(self, value), -- (Status, Unsigned) -> nil
    get_damage_dealt_offset(self),        -- (Status) -> Unsigned
    set_damage_dealt_factor(self, value), -- (Status, Float) -> nil
    get_damage_dealt_factor(self),        -- (Status) -> Float

    set_damage_received_offset(self, value), -- (Status, Unsigned) -> nil
    get_damage_received_offset(self),        -- (Status) -> Unsigned
    set_damage_received_factor(self, value), -- (Status, Float) -> nil
    get_damage_received_factor(self),        -- (Status) -> Float

    set_healing_performed_offset(self, value), -- (Status, Unsigned) -> nil
    get_healing_performed_offset(self),        -- (Status) -> Unsigned
    set_healing_performed_factor(self, value), -- (Status, Float) -> nil
    get_healing_performed_factor(self),        -- (Status) -> Float
    
    set_healing_received_offset(self, value),   -- (Status, Unsigned) -> nil
    get_healing_received_offset(self),          -- (Status) -> Unsigned
    set_healing_received_factor(self, value),   -- (Status, Float) -> nil
    get_healing_received_factor(self),          -- (Status) -> Float
    
    -- ### Config Fields ### --
    
    description = "<no description>",   -- String
    sprite_id = "",     -- String
    sprite_index = 1,   -- Union<String, Unsigned>

    id = "STATUS_ID",        -- const String
    name = "Example Status", -- const String

    attack_offset = 0,   -- Unsigned
    defense_offset = 0,  -- Unsigned
    speed_offset = 0,    -- Unsigned

    attack_factor = 1,   -- Float >= 0
    defense_factor = 1,  -- Float >= 0
    speed_factor = 1,    -- Float >= 0

    damage_dealt_factor = 1,      -- Float >= 0
    damage_received_factor = 1,   -- Float >= 0
    healing_performed_factor = 1, -- Float >= 0
    healing_received_factor = 1,  -- Float >= 0

    damage_dealt_offset = 0,      -- Unsigned
    damage_received_offset = 0,   -- Unsigned
    healing_performed_offset = 0, -- Unsigned
    healing_received_offset = 0,  -- Unsigned

    max_duration = POSITIVE_INFINITY, -- const Unsigned
    is_silent = false,                -- const Boolean

    -- (StatusInterface, EntityInterface) -> nil
    on_gained(self, afflicted),
    
    -- (StatusInterface, EntityInterface) -> nil
    on_lost(self, afflicted),
    
    -- (StatusInterface, EntityInterface) -> nil
    on_turn_start(self, afflicted),
    
    -- (StatusInterface, EntityInterface) -> nil
    on_turn_end(self, affclited),

    -- (StatusInterface, EntityInterface, Unsigned) -> nil
    on_healing_received(self, afflicted, value),

    -- (StatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_healing_performed(self, afflicted, receiver, value),

    -- (StatusInterface, EntityInterface, Unsigned) -> nil
    on_damage_taken(self, afflicted, value),

    -- (StatusInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_damage_dealt(self, afflicted, damage_taker, value),

    -- (StatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained(self, afflicted, status),

    -- (StatusInterface, EntityInterface, StatusInterface) -> nil
    on_status_lost(self, afflicted, status),

    -- (StatusInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_gained(self, afflicted, global_status),

    -- (StatusInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_lost(self, afflicted, global_status),

    -- (StatusInterface, EntityInterface) -> nil
    on_knocked_out(self, afflicted),

    -- (StatusInterface, EntityInterface) -> nil
    on_helped_up(self, afflicted),
    
    -- (StatusInterface, EntityInterface) -> nil
    on_killed(self, afflicted),
    
    -- (StatusInterface, EntityInterface, EntityInterface) -> nil
    on_switch(self, afflicted, entity_at_old_position),

    -- (StatusInterface, EntityInterface, MoveInterface, Table<EntityInterface>) -> nil
    on_move_used(self, afflicted, move, targets),

    -- (StatusInterface, EntityInterface, ConsumableInterface) -> nil
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

    -- (ConsumableInterface, EntityInterface) -> nil
    on_turn_start(self, afflicted),

    -- (ConsumableInterface, EntityInterface) -> nil
    on_turn_end(self, afflicted),

    -- (ConsumableInterface, EntityInterface, Unsigned) -> nil
    on_healing_received(self, afflicted, value),

    -- (ConsumableInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_healing_performed(self, afflicted, receiver, value),

    -- (ConsumableInterface, EntityInterface, Unsigned) -> nil
    on_damage_taken(self, afflicted, value),

    -- (ConsumableInterface, EntityInterface, EntityInterface, Unsigned) -> nil
    on_damage_dealt(self, afflicted, damage_taker, value),

    -- (ConsumableInterface, EntityInterface, StatusInterface) -> nil
    on_status_gained(self, afflicted, status),

    -- (ConsumableInterface, EntityInterface, StatusInterface) -> nil
    on_status_lost(self, afflicted, status),

    -- (ConsumableInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_gained(self, afflicted, global_status),

    -- (ConsumableInterface, EntityInterface, GlobalStatusInterface) -> nil
    on_global_status_lost(self, afflicted, global_status),

    -- (ConsumableInterface, EntityInterface) -> nil
    on_knocked_out(self, afflicted),

    -- (ConsumableInterface, EntityInterface) -> nil
    on_helped_up(self, afflicted),

    -- (ConsumableInterface, EntityInterface) -> nil
    on_killed(self, afflicted),

    -- (ConsumableInterface, EntityInterface, EntityInterface) -> nil
    on_switch(self, afflicted, entity_at_old_position),

    -- (ConsumableInterface, EntityInterface, MoveInterface, Table<EntityInterface>) -> nil
    on_move_used(self, afflicted, move, targets),

    -- (ConsumableInterface, EntityInterface, ConsumableInterface) -> nil
    on_consumable_consumed(self, afflicted, consumable),
}
```

# Entity (bt.EntityInterface)

```lua
Entity {
    
    -- TODO: has_ for move, consumable, etc.
}
```

# Move (bt.MoveInterface)

```lua
Move {
    -- ### Instance Fields ### --
    
    id = "EXAMPLE_MOVE", -- const String
    name = "Example Move", -- const String
    
    max_n_uses = POSITIVE_INFINITY, -- const Unsigned
    
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
    
    -- (MoveInterface, EntityInterface, Table<EntityInterface>) -> nil
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
    
    attack_factor = 1,  -- const Float >= 0
    defense_factor = 1, -- const Float >= 0
    speed_factor = 1,   -- const Float >= 0
    
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

    -- (Equip, EntityInterface) -> nil
    effect(self, holder),
}
```

