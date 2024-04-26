# Status (bt.StatusInterface)

```lua
Status {
    -- ### Public Fields ###

    id = "STATUS_ID",        -- String
    name = "Example Status", -- String
    
    attack_offset = 0,   -- Unsigned
    defense_offset = 0,  -- Unsigned
    speed_offset = 0,    -- Unsigned
    
    attack_factor = 1,   -- Float
    defense_factor = 1,  -- Float
    speed_factor = 1,    -- Float
    
    max_duration = POSITIVE_INFINITY, -- const Unsigned
    is_silent = false,  -- const Boolean

    -- ### Instance Methods ###
    
    --- @brief attack modifiers
    set_attack_offset(self, offset), -- (Status, Unsigned) -> nil
    set_attack_factor(self, factor), -- (Status, Float) -> nil
    get_attack_offset(self), -- (Status) -> Unsigned
    get_attack_factor(self), -- (Status) -> Float
    
    -- ### Callbacks ###

    -- invoked when entity first gains self
    on_gained(self, afflicted) -- (StatusInterface, EntityInterface) -> nil
}
```

## Instance Methods

```lua

```

## Callbacks

